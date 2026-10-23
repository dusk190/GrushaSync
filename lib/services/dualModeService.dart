import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/peer_device.dart';
import '../models/shared_file.dart';
import '../models/peer_file.dart';
export '../models/peer_device.dart';
export '../models/shared_file.dart';
export '../models/peer_file.dart';

import 'ConfigService.dart';
import 'mdnsService.dart';
import 'network_utils.dart';
import 'peer_discovery_service.dart';
import 'file_server_service.dart';
import 'file_client_service.dart';
import 'permission_service.dart';

/// Главный координатор (Фасад) для UI-слоя.
/// Объединяет обнаружение пиров, раздачу и скачивание файлов.
class DualModeService extends ChangeNotifier {
  static const String _filesPath = "/BjhbfjKWkjn1217y8Fbkbhwkjijf";
  static const String _downloadPath = "/WEJKFHLwiehffao29u4819fjnsj/download";
  static const int _serverPort = 8080;

  // Модули сервиса
  final PeerDiscoveryService _discovery = PeerDiscoveryService();
  final FileClientService _client = FileClientService();
  late final FileServerService _server;

  // Локальное состояние
  final List<SharedFile> _mySharedFiles = [];
  String? _currentIp;
  String? _myDeviceName;
  int _updateCounter = 0;

  // Геттеры для UI
  int get updateCounter => _updateCounter;
  bool get isServerRunning => _server.isRunning;
  bool get isClientMode => false;
  List<PeerDevice> get peers => _discovery.peers;
  List<SharedFile> get mySharedFiles => _mySharedFiles;
  MdnsService get mdns => _discovery.mdns;
  String? get networkPassword => _discovery.networkPassword;
  String get filesPath => _filesPath;
  String get downloadPath => _downloadPath;

  DualModeService() {
    _server = FileServerService(
      filesPath: _filesPath,
      downloadPath: _downloadPath,
      getSharedFiles: () => _mySharedFiles,
      onNotifyReceived: _onFilesUpdatedByPeer,
    );
    _discovery.addListener(_onDiscoveryChanged);
  }

  // --- Инициализация ---
  Future<void> initialize() async {
    await _loadNetworkPassword();
    await PermissionService.ensurePermissions();

    _currentIp = await NetworkUtils.getLocalIp();
    _myDeviceName = await NetworkUtils.getDeviceName();

    _discovery.setSelfInfo(
      deviceName: _myDeviceName!,
      currentIp: _currentIp,
      networkPassword: _discovery.networkPassword,
    );

    // Запускаем локальный HTTP-сервер
    await _server.start(_serverPort);

    // Регистрируем mDNS и начинаем поиск пиров
    await _discovery.registerSelf(
      deviceName: _myDeviceName!,
      port: _serverPort,
      ip: _currentIp,
      networkPassword: _discovery.networkPassword,
    );
    await _discovery.startDiscovery();

    notifyListeners();
  }

  // --- Разрешения (делегирование в PermissionService) ---
  Future<bool> requestStoragePermission() => PermissionService.requestStoragePermission();
  Future<PermissionStatus> checkStoragePermission() => PermissionService.checkStoragePermission();
  Future<void> openSettings() => PermissionService.openSettings();
  Future<bool> ensurePermissions() => PermissionService.ensurePermissions();

  // --- Работа с файлами раздачи ---
  void addSharedFiles(List<String> paths) async {
    for (var path in paths) {
      try {
        final sourceFile = File(path);
        if (!await sourceFile.exists()) continue;

        String fileName = path;
        if (path.contains('/')) {
          fileName = path.split('/').last;
        } else if (path.contains('\\')) {
          fileName = path.split('\\').last;
        }

        if (!_mySharedFiles.any((f) => f.path == path)) {
          final fileLength = await sourceFile.length();
          final fileId = '${DateTime.now().microsecondsSinceEpoch}_${fileLength}_${path.hashCode.abs()}';

          _mySharedFiles.add(SharedFile(
            id: fileId,
            name: fileName,
            path: path,
            size: fileLength,
          ));

          if (kDebugMode) {
            print('Файл добавлен в общий доступ: $fileName (id: $fileId)');
          }
        }
      } catch (e) {
        if (kDebugMode) print('Ошибка обработки файла $path: $e');
      }
    }

    notifyListeners();
    _notifyPeersAboutUpdate();
  }

  void removeSharedFile(String idOrName, {bool notifyPeers = false}) {
    _mySharedFiles.removeWhere((f) => f.id == idOrName || f.name == idOrName);
    notifyListeners();
    if (notifyPeers) {
      _notifyPeersAboutUpdate();
    }
  }

  // --- Клиентские операции ---
  Future<List<PeerFile>> fetchPeerFiles(PeerDevice peer) {
    return _client.fetchPeerFiles(
      peer,
      _filesPath,
      onPeerFailed: (p) => _discovery.removePeer(p),
    );
  }

  Future<bool> downloadFile(PeerDevice peer, PeerFile file, Function(double) onProgress) {
    return _client.downloadFile(
      peer,
      file,
      _downloadPath,
      onProgress,
      onPeerFailed: (p) => _discovery.removePeer(p),
      onStateChanged: notifyListeners,
    );
  }

  bool isFileDownloading(String fileId) => _client.isFileDownloading(fileId);
  ValueNotifier<double> getProgressNotifier(String fileId) => _client.getProgressNotifier(fileId);

  // --- Сеть и пиры ---
  Future<void> refreshMdns() => _discovery.refreshDiscovery();

  void removePeer(PeerDevice peer) => _discovery.removePeer(peer);

  Future<String> getCachedDeviceName() async {
    if (_myDeviceName != null) return _myDeviceName!;
    final name = await NetworkUtils.getDeviceName();
    _myDeviceName = name;
    return name;
  }

  Future<void> setNetworkPassword(String? password) async {
    final cleanPass = (password != null && password.isNotEmpty) ? password : null;
    if (cleanPass != null) {
      await ConfigService.setNetPass(cleanPass);
    } else {
      await ConfigService.removePass();
    }

    if (_server.isRunning && _myDeviceName != null) {
      await _discovery.registerSelf(
        deviceName: _myDeviceName!,
        port: _serverPort,
        ip: _currentIp,
        networkPassword: cleanPass,
      );
    }
    await _discovery.refreshDiscovery();
    notifyListeners();
  }

  // --- Вспомогательные внутренние методы ---
  void _onFilesUpdatedByPeer() {
    _updateCounter++;
    notifyListeners();
  }

  void _onDiscoveryChanged() {
    notifyListeners();
  }

  Future<void> _notifyPeersAboutUpdate() async {
    if (!_server.isRunning || _discovery.peers.isEmpty) return;
    final myName = _myDeviceName ?? 'Unknown';
    await _client.notifyPeers(
      _discovery.peers,
      myName,
      onPeerFailed: (p) => _discovery.removePeer(p),
    );
  }

  Future<void> _loadNetworkPassword() async {
    final pass = ConfigService.netPass;
    if (pass != null && pass.isNotEmpty) {
      _discovery.setSelfInfo(
        deviceName: _myDeviceName ?? 'Device',
        currentIp: _currentIp,
        networkPassword: pass,
      );
    }
  }

  @override
  void dispose() {
    _discovery.removeListener(_onDiscoveryChanged);
    _discovery.dispose();
    _server.stop();
    super.dispose();
  }
}
