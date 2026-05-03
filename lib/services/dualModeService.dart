import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'mdnsService.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class DualModeService extends ChangeNotifier {
  // Компоненты
  final MdnsService _mdns = MdnsService();
  HttpServer? _httpServer;
  String? _currentIp;
  String? _myDeviceName;

  // Состояние
  bool _isServerRunning = false;
  bool _isClientMode = false;
  final List<PeerDevice> _peers = [];
  final List<SharedFile> _mySharedFiles = [];
  final List<PeerFile> _peerFiles = [];
  int _updateCounter = 0;

  // Геттеры
  int get updateCounter => _updateCounter;
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
      // Получаем версию Android
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;

      if (sdkInt >= 33) {
        // Андроид 13+
        final images = await Permission.photos.request();
        final videos = await Permission.videos.request();
        final audio = await Permission.audio.request();

        final allGranted = images.isGranted && videos.isGranted && audio.isGranted;

        if (allGranted) {
          if (kDebugMode) print('Разрешения для медиа получены андроид 13+');
          return true;
        } else {
          // Если какое-то разрешение отклонено навсегда
          if (images.isPermanentlyDenied || videos.isPermanentlyDenied || audio.isPermanentlyDenied) {
            if (kDebugMode) print('Разрешения отклонены навсегда');
            await openAppSettings();
          }
          return false;
        }

      } else if (sdkInt >= 30) {
        // Андроид 11-12
        final status = await Permission.manageExternalStorage.request();

        if (status.isGranted) {
          if (kDebugMode) print('Разрешение manageExternalStorage получено (Android 11-12)');
          return true;
        } else if (status.isPermanentlyDenied) {
          if (kDebugMode) print('Разрешение отклонено навсегда, открываем настройки');
          await openAppSettings();
          return false;
        }
        return false;

      } else {
        // андроид 10
        final status = await Permission.storage.request();

        if (status.isGranted) {
          if (kDebugMode) print('Разрешение storage получено (Android 10-)');
          return true;
        } else if (status.isPermanentlyDenied) {
          if (kDebugMode) print('Разрешение отклонено навсегда, открываем настройки');
          await openAppSettings();
          return false;
        }
        return false;
      }
    }
    return true;
  }
  // Инициализация
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

      _currentIp = await _getLocalIp();
      _myDeviceName = await _getDeviceName();

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

      // POST /api/notify - уведомление об обновлении файлов
      if (request.uri.path == '/api/notify' && request.method == 'POST') {
        final body = await utf8.decoder.bind(request).join();
        final data = jsonDecode(body);
        final senderName = data['deviceName'] ?? 'Unknown';

        if (kDebugMode) {
          print('Получено уведомление об обновлении от $senderName');
        }

        // Уведомляем UI (вызовет обновление у всех слушателей)
        _updateCounter++;
        notifyListeners();

        request.response
          ..statusCode = 200
          ..write('OK')
          ..close();
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

    //  Удаление файла из шаринга
    for (var path in paths) {
      try {
        final sourceFile = File(path);
        if (!await sourceFile.exists()) {
          if (kDebugMode) {
            print('Файл не существует: $path');
          }
          continue;
        }


        String fileName = path;
        if (path.contains('/')) {
          fileName = path.split('/').last;
        } else if (path.contains('\\')) {
          fileName = path.split('\\').last;
        }


        if (!_mySharedFiles.any((f) => f.name == fileName)) {
          _mySharedFiles.add(SharedFile(
            name: fileName,
            path: path,  // оригинальный путь
            size: await sourceFile.length(),
          ));

          if (kDebugMode) {
            print('Файл добавлен в общий доступ: $fileName');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Ошибка обработки файла $path: $e');
        }
      }
    }

    notifyListeners();

    // Оповещаем всех пиров об обновлении
    _notifyPeersAboutUpdate();

    if (kDebugMode) {
      print('Файлы добавлены, уведомления отправлены');
    }

    if (kDebugMode) {
      print('Всего общих файлов: ${_mySharedFiles.length}');
      for (var f in _mySharedFiles) {
        print('   - ${f.name} (${f.path})');
      }
    }
  }
  void removeSharedFile(String name) {
    _mySharedFiles.removeWhere((f) => f.name == name);
    notifyListeners();
    // Оповещаем всех пиров об обновлении
    _notifyPeersAboutUpdate();
  }

  // Обработка изменений mDNS
  Future<void> _onMdnsChanged() async {
    await _updatePeersFromMdns();
  }

  // Уведомление всех пиров о добавлении новых файлов
  Future<void> _notifyPeersAboutUpdate() async {
    // Пропускаем, если мы не в режиме сервера или нет пиров
    if (!_isServerRunning || _peers.isEmpty) return;

    final myName = _myDeviceName ?? 'Unknown';
    final notificationData = jsonEncode({
      'deviceName': myName,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Отправляем уведомление каждому пиру
    for (var peer in _peers) {
      try {
        final url = Uri.parse('http://${peer.host}:${peer.port}/api/notify');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: notificationData,
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          if (kDebugMode) {
            print('Уведомление отправлено на ${peer.name}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Не удалось уведомить ${peer.name}: $e');
        }
      }
    }
  }


  // Обновление списка пиров
  Future<void> _updatePeersFromMdns() async {
    final currentPeerIds = _peers.map((p) => p.id).toSet();
    final newPeerIds = _mdns.services.map((s) => s.name).toSet();

    _peers.clear();

    for (var service in _mdns.services) {
      final serviceName = service.name ?? '';
      final serviceHost = service.host ?? '';

      // Пропускаем своё устройство
      if (_myDeviceName != null && serviceName == _myDeviceName) {
        if (kDebugMode) print('Пропускаем своё устройство: $serviceName');
        continue;
      }

      // Преобразуем .local имя в IP
      String? resolvedIp;

      if (serviceHost.endsWith('.local')) {
        if (kDebugMode) print('Разрешаем имя: $serviceHost');
        resolvedIp = await _resolveLocalHostname(serviceHost);

        if (resolvedIp == null) {
          if (kDebugMode) print('Не удалось разрешить $serviceHost, пропускаем');
          continue;
        }
      } else if (serviceHost.contains(':') || serviceHost.contains('%')) {
        if (kDebugMode) print('Пропускаем IPv6 адрес: $serviceHost');
        continue;
      } else {
        resolvedIp = serviceHost;
      }

      if (kDebugMode) print('Добавляем устройство: $serviceName → $resolvedIp:${service.port}');

      _peers.add(PeerDevice(
        id: service.name ?? 'unknown',
        name: service.name ?? 'Unknown',
        host: resolvedIp,
        port: service.port ?? 8080,
        lastSeen: DateTime.now(),
      ));
    }

    notifyListeners();

    if (kDebugMode) {
      print('Обновлён список пиров: ${_peers.length} устройств');
      for (var p in _peers) {
        print('   - ${p.name} (${p.host}:${p.port})');
      }
    }
  }

  Future<String?> _resolveLocalHostname(String hostname) async {
    try {
      final cleanHostname = hostname.replaceAll('.local', '');
      final addresses = await InternetAddress.lookup(cleanHostname);

      for (var addr in addresses) {
        if (addr.type == InternetAddressType.IPv4) {
          if (kDebugMode) print('Разрешено (IPv4): ${addr.address}');
          return addr.address;
        }
      }
      if (kDebugMode) print('IPv4 не найден для $hostname, пропускаем');
      return null;

    } catch (e) {
      if (kDebugMode) print('Ошибка разрешения $hostname: $e');
      return null;
    }
  }

  // Получение списка файлов с пира
  Future<List<PeerFile>> fetchPeerFiles(PeerDevice peer) async {
    try {
      final hostPort = _formatHostForUrl(peer.host, peer.port);
      final url = Uri.http('${peer.host}:${peer.port}', '/api/files');
      print('Запрос к ${peer.host}:${peer.port}/api/files');
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
    try {
      final hostPort = _formatHostForUrl(peer.host, peer.port);
      final url = Uri.http(hostPort, '/download/${file.name}');
      final request = http.Request('GET', url);
      final response = await request.send();

      if (response.statusCode != 200) {
        print('Ошибка HTTP: ${response.statusCode}');
        return false;
      }

      // Получаем папку для скачиваний
      final downloadDir = await _getDownloadDirectory();
      print('Папка для сохранения: ${downloadDir.path}');

      // Проверяем доступность папки
      if (!await downloadDir.exists()) {
        try {
          await downloadDir.create(recursive: true);
          print('Папка создана: ${downloadDir.path}');
        } catch (e) {
          print('Не удалось создать папку: $e');
          return false;
        }
      }

      // Проверяем, можно ли писать в папку
      final testFile = File('${downloadDir.path}/.test');
      try {
        await testFile.writeAsString('test');
        await testFile.delete();
        print('Папка доступна для записи');
      } catch (e) {
        print('Нет прав на запись в папку: $e');
        return false;
      }

      final filePath = '${downloadDir.path}/${file.name}';
      final outputFile = File(filePath);

      // Если файл уже существует, добавляем суффикс
      String finalPath = filePath;
      int counter = 1;
      while (await File(finalPath).exists()) {
        final extension = file.name.contains('.')
            ? '.${file.name.split('.').last}'
            : '';
        final nameWithoutExt = file.name.split('.').first;
        finalPath = '${downloadDir.path}/${nameWithoutExt}_$counter$extension';
        counter++;
      }

      print('Сохраняем в: $finalPath');
      final outputFileFinal = File(finalPath);
      final sink = outputFileFinal.openWrite();

      int bytesReceived = 0;
      final contentLength = response.contentLength ?? file.size;

      await for (var chunk in response.stream) {
        sink.add(chunk);
        bytesReceived += chunk.length;
        onProgress(bytesReceived / contentLength);
      }

      await sink.close();

      // Проверяем, что файл действительно создался
      if (await outputFileFinal.exists()) {
        final fileSize = await outputFileFinal.length();
        print('Скачан файл: ${file.name} (${_formatSize(fileSize)}) в ${downloadDir.path}');
        return true;
      } else {
        print('Файл не был создан после записи');
        return false;
      }
    } catch (e) {
      print('Ошибка скачивания: $e');
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
      final downloadsPath = '/storage/emulated/0/Download';
      final grushaDir = Directory('$downloadsPath/GrushaSync');

      // Пытаемся создать папку, если не получится — используем просто Download
      try {
        if (!await grushaDir.exists()) {
          await grushaDir.create(recursive: true);
        }
        return grushaDir;
      } catch (e) {
        print('Не удалось создать папку GrushaSync: $e');
        return Directory(downloadsPath);
      }
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
    try {
      // Получаем список всех сетевых интерфейсов, исключая loopback (127.0.0.1)
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
      );

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          // Ищем первый попавшийся IPv4 адрес, который не является внутренним
          if (addr.type == InternetAddressType.IPv4 &&
              addr.address != '127.0.0.1') {
            print('Найден IP через NetworkInterface: ${addr.address}');
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('Ошибка NetworkInterface: $e');
    }
    return null;
  }

  Future<String> _getDeviceName() async {
    final ip = await _getLocalIp();
    return 'Device-${ip?.split('.').last ?? 'unknown'}';
  }

  String _formatHostForUrl(String host, int port) {

    if (host.contains(':') && !host.contains('.')) {
      return '[$host]:$port';
    }
    return '$host:$port';
  }
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<String> getCachedDeviceName() async {
    if (_myDeviceName != null) {
      return _myDeviceName!;
    }
    final name = await _getDeviceName();
    _myDeviceName = name;
    return name;
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