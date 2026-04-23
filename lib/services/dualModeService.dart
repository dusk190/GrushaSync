import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'mdnsService.dart';
import 'package:permission_handler/permission_handler.dart';

class DualModeService extends ChangeNotifier {
  // Компоненты
  final MdnsService _mdns = MdnsService();
  HttpServer? _httpServer;

  // Состояние
  bool _isServerRunning = false;
  bool _isClientMode = false;
  final List<PeerDevice> _peers = [];
  final List<SharedFile> _mySharedFiles = [];
  final List<PeerFile> _peerFiles = [];

  // Геттеры
  bool get isServerRunning => _isServerRunning;
  bool get isClientMode => _isClientMode;
  List<PeerDevice> get peers => _peers;
  List<SharedFile> get mySharedFiles => _mySharedFiles;
  List<PeerFile> get peerFiles => _peerFiles;
  MdnsService get mdns => _mdns;
  // Запрос разрешения на storage
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    // Для других платформ разрешения не нужны
    return true;
  }

  // Запрос нескольких разрешений
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();

      return statuses[Permission.storage]?.isGranted ?? false;
    }
    return true;
  }

  // Проверка статуса разрешения
  Future<PermissionStatus> checkStoragePermission() async {
    return await Permission.storage.status;
  }

  // Открыть настройки приложения (если разрешение отклонено навсегда)
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
  // Проверка и запрос всех необходимых разрешений при старте
  Future<bool> ensurePermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;

      if (status.isGranted) {
        if (kDebugMode) {
          print('✅ Разрешение на storage уже получено');
        }
        return true;
      }

      if (status.isDenied) {
        final result = await requestStoragePermission();
        if (result) {
          if (kDebugMode) {
            print('✅ Разрешение на storage получено');
          }
          return true;
        }
      }

      if (status.isPermanentlyDenied) {
        if (kDebugMode) {
          print('⚠️ Разрешение отклонено навсегда, открываем настройки');
        }
        await openAppSettings();
        return false;
      }
    }
    return true;
  }
  // Инициализация (запускаем сразу и сервер, и клиент)
  Future<void> initialize() async {
    final hasPermission = await ensurePermissions();
    if (!hasPermission) {
      if (kDebugMode) {
        print('Нет разрешений, работа сервиса ограничена');
      }
    }

    // Запускаем HTTP сервер (чтобы нас могли видеть)
    await _startServer();

    // Запускаем mDNS поиск (чтобы видеть других)
    await _mdns.startDiscovery();

    // Подписываемся на события mDNS
    _mdns.addListener(_onMdnsChanged);

    if (kDebugMode) {
      print('DualModeService инициализирован');
      print('   - Сервер: ${_isServerRunning ? "запущен" : "остановлен"}');
      print('   - Поиск: ${_mdns.isDiscovering ? "активен" : "неактивен"}');
    }
  }

  // Запуск HTTP сервера
  Future<void> _startServer() async {
    try {
      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      _isServerRunning = true;

      // Регистрируем mDNS сервис
      final deviceName = await _getDeviceName();
      await _mdns.registerService(deviceName, 8080);

      // Обрабатываем входящие запросы
      _handleIncomingRequests();

      notifyListeners();

      if (kDebugMode) {
        final ip = await _getLocalIp();
        print('HTTP Сервер запущен на $ip:8080');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка запуска сервера: $e');
      }
    }
  }

  // Обработка входящих HTTP запросов
  void _handleIncomingRequests() {
    _httpServer?.listen((HttpRequest request) async {
      final peerIp = request.connectionInfo?.remoteAddress.address ?? 'unknown';

      // GET /api/files - список файлов
      if (request.uri.path == '/api/files') {
        final response = _generateFileListJson();
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(response)
          ..close();
        return;
      }

      // GET /download/{filename} - скачивание файла
      if (request.uri.path.startsWith('/download/')) {
        final filename = request.uri.pathSegments.last;
        await _handleDownloadRequest(request, filename);
        return;
      }

      // 404
      request.response
        ..statusCode = 404
        ..write('Not Found')
        ..close();
    });
  }

  // Генерация списка файлов в JSON
  String _generateFileListJson() {
    final files = _mySharedFiles.map((f) => {
      'name': f.name,
      'size': f.size,
      'sizeFormatted': _formatSize(f.size),
    }).toList();

    return jsonEncode({
      'deviceName': _mdns.isRegistered ? 'Моё устройство' : 'Unknown',
      'files': files,
    });
  }

  // Обработка запроса на скачивание
  Future<void> _handleDownloadRequest(HttpRequest request, String filename) async {
    try {
      // Ищем файл в списке общих файлов
      final fileInfo = _mySharedFiles.firstWhere(
            (f) => f.name == filename,
        orElse: () => throw Exception('File not found'),
      );

      final file = File(fileInfo.path);

      //Проверяем существование файла
      if (!await file.exists()) {
        if (kDebugMode) {
          print('Файл не найден: ${fileInfo.path}');
        }
        request.response
          ..statusCode = 404
          ..write('File not found')
          ..close();
        return;
      }

      //Получаем размер файла
      final fileSize = await file.length();

      // Кодируем имя файла для HTTP заголовка (поддержка кириллицы)
      final encodedFilename = Uri.encodeComponent(filename);

      // Настраиваем заголовки ответа
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.binary
        ..headers.add('Content-Disposition', 'attachment; filename*=UTF-8\'\'$encodedFilename')
        ..headers.add('Content-Length', fileSize.toString());

      // Отправляем файл стримом
      final stream = file.openRead();
      await request.response.addStream(stream);
      await request.response.close();

      if (kDebugMode) {
        print('Файл отправлен: $filename (${_formatSize(fileSize)})');
      }

    } catch (e) {
      if (kDebugMode) {
        print('Ошибка отправки файла $filename: $e');
      }

      try {
        request.response
          ..statusCode = 500
          ..write('Internal Server Error')
          ..close();
      } catch (_) {}
    }
  }




  // Добавление файлов для шаринга
  void addSharedFiles(List<String> paths) async {
    // Проверяем разрешения перед копированием
    final hasPermission = await requestStoragePermission();
    if (!hasPermission) {
      if (kDebugMode) {
        print('Нет разрешения на запись в хранилище');
      }
      return;
    }

    final sharedDir = Directory('/storage/emulated/0/Download/GrushaSync');

    if (!await sharedDir.exists()) {
      await sharedDir.create(recursive: true);
    }

    for (var path in paths) {
      try {
        final sourceFile = File(path);
        if (!await sourceFile.exists()) {
          if (kDebugMode) {
            print('Файл не существует: $path');
          }
          continue;
        }

        // Извлекаем имя файла
        String fileName = path;
        if (path.contains('/')) {
          fileName = path.split('/').last;
        } else if (path.contains('\\')) {
          fileName = path.split('\\').last;
        }

        final destPath = '${sharedDir.path}/$fileName';
        final destFile = File(destPath);

        // Копируем, если файл ещё не существует
        if (!await destFile.exists()) {
          await sourceFile.copy(destPath);
          if (kDebugMode) {
            print('Файл скопирован: $fileName');
          }
        }

        // Проверяем, нет ли уже такого файла в списке
        if (!_mySharedFiles.any((f) => f.name == fileName)) {
          _mySharedFiles.add(SharedFile(
            name: fileName,
            path: destPath,
            size: await destFile.length(),
          ));
        }
      } catch (e) {
        if (kDebugMode) {
          print('Ошибка обработки файла $path: $e');
        }
      }
    }

    notifyListeners();

    if (kDebugMode) {
      print('Всего общих файлов: ${_mySharedFiles.length}');
    }
  }

  //  Удаление файла из шаринга
  void removeSharedFile(String name) {
    _mySharedFiles.removeWhere((f) => f.name == name);
    notifyListeners();
  }

  // Обработка изменений mDNS
  void _onMdnsChanged() {
    _updatePeersFromMdns();
  }

  // Обновление списка пиров
  void _updatePeersFromMdns() {
    final currentPeerIds = _peers.map((p) => p.id).toSet();
    final newPeerIds = _mdns.services.map((s) => s.name).toSet();

    // Добавляем новых пиров
    for (var service in _mdns.services) {
      if (!currentPeerIds.contains(service.name)) {
        _peers.add(PeerDevice(
          id: service.name ?? 'unknown',
          name: service.name ?? 'Unknown',
          host: service.host ?? '0.0.0.0',
          port: service.port ?? 8080,
          lastSeen: DateTime.now(),
        ));
      }
    }

    // Удаляем потерянных пиров
    _peers.removeWhere((p) => !newPeerIds.contains(p.id));

    notifyListeners();

    if (kDebugMode) {
      print('Обновлён список пиров: ${_peers.length} устройств');
    }
  }

  // Получение списка файлов с пира
  Future<List<PeerFile>> fetchPeerFiles(PeerDevice peer) async {
    try {
      final url = Uri.http('${peer.host}:${peer.port}', '/api/files');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final files = (data['files'] as List).map((f) => PeerFile(
          name: f['name'],
          size: f['size'],
          sizeFormatted: f['sizeFormatted'],
          peerId: peer.id,
          peerName: peer.name,
        )).toList();

        if (kDebugMode) {
          print('Получено ${files.length} файлов от ${peer.name}');
        }

        return files;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения файлов от ${peer.name}: $e');
      }
    }

    return [];
  }

  // Скачивание файла с пира
  Future<bool> downloadFile(PeerDevice peer, PeerFile file, Function(double) onProgress) async {
    //  Проверяем разрешения перед скачиванием
    final hasPermission = await requestStoragePermission();
    if (!hasPermission) {
      if (kDebugMode) {
        print('Нет разрешения на запись в хранилище');
      }
      return false;
    }

    try {
      final url = Uri.http('${peer.host}:${peer.port}', '/download/${file.name}');
      final request = http.Request('GET', url);
      final response = await request.send();

      if (response.statusCode != 200) {
        return false;
      }

      // Получаем правильную папку для скачиваний
      final downloadDir = await _getDownloadDirectory();

      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final filePath = '${downloadDir.path}/${file.name}';
      final outputFile = File(filePath);
      final sink = outputFile.openWrite();

      int bytesReceived = 0;
      final contentLength = response.contentLength ?? file.size;

      await for (var chunk in response.stream) {
        sink.add(chunk);
        bytesReceived += chunk.length;
        onProgress(bytesReceived / contentLength);
      }

      await sink.close();

      if (kDebugMode) {
        print('Скачан файл: ${file.name} в ${downloadDir.path}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка скачивания: $e');
      }
      return false;
    }
  }
  // Определение папки для скачиваний в зависимости от платформы
  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Default';
      return Directory('$userProfile\\Downloads\\GrushaSync');
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '/Users/default';
      return Directory('$home/Downloads/GrushaSync');
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? '/home/default';
      return Directory('$home/Downloads/GrushaSync');
    } else {
      return Directory('/storage/emulated/0/Download/GrushaSync');
    }
  }
  // Остановка сервиса
  @override
  void dispose()  {
    _mdns.unregisterService();
    _mdns.stopDiscovery();
    _httpServer?.close();
    super.dispose();
  }

  // Вспомогательные методы
  Future<String?> _getLocalIp() async {
    final info = NetworkInfo();
    try {
      return await info.getWifiIP();
    } catch (e) {
      return null;
    }
  }

  Future<String> _getDeviceName() async {
    final ip = await _getLocalIp();
    return 'Device-${ip?.split('.').last ?? 'unknown'}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}


class PeerDevice {
  final String id;
  final String name;
  final String host;
  final int port;
  DateTime lastSeen;

  PeerDevice({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.lastSeen,
  });
}

class SharedFile {
  final String name;
  final String path;
  final int size;

  SharedFile({required this.name, required this.path, required this.size});
}

class PeerFile {
  final String name;
  final int size;
  final String sizeFormatted;
  final String peerId;
  final String peerName;

  PeerFile({
    required this.name,
    required this.size,
    required this.sizeFormatted,
    required this.peerId,
    required this.peerName,
  });
}