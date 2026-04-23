import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart' as nsd;

/// Сервис поиска устройств в локальной сети
class DeviceDiscoveryService extends ChangeNotifier {
  nsd.Discovery? _discovery;

  final List<DiscoveredDevice> _devices = [];
  List<DiscoveredDevice> get devices => _devices;

  bool get isDiscovering => _discovery != null;

  static const String serviceType = '_grushasync._tcp.';

  // --- Запуск поиска ---
  Future<void> startDiscovery() async {
    await stopDiscovery();
    _devices.clear();

    try {
      _discovery = await nsd.startDiscovery(serviceType);

      _discovery?.addListener(() {
        _updateDevicesList();
      });

      _updateDevicesList();

      if (kDebugMode) {
        print('🔍 Поиск устройств запущен');
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ Ошибка запуска поиска: $e');
      }
    }
  }

  // --- Обновление списка устройств (ИСПРАВЛЕНО) ---
  void _updateDevicesList() {
    if (_discovery == null) return;

    final newDevices = <DiscoveredDevice>[];

    for (var service in _discovery!.services) {
      final serviceName = service.name ?? 'Unknown Device';

      final Map<String, List<int>>? convertedTxt = service.txt?.map(
            (key, value) => MapEntry(key, value?.toList() ?? []),
      );
      final attributes = _parseTxtAttributes(convertedTxt);

      final deviceName = attributes['device_name'] ?? serviceName;

      final device = DiscoveredDevice(
        id: serviceName,
        name: deviceName,
        ip: service.host ?? '0.0.0.0',
        port: service.port ?? 0,
        platform: attributes['platform'] ?? 'unknown',
        version: attributes['version'] ?? '1.0',
        lastSeen: DateTime.now(),
        rawService: service,
      );

      newDevices.add(device);
    }

    _devices.clear();
    _devices.addAll(newDevices);
    notifyListeners();

    if (kDebugMode) {
      print('📡 Найдено устройств: ${_devices.length}');
      for (var d in _devices) {
        print('   - ${d.name} (${d.ip}:${d.port})');
      }
    }
  }


  Map<String, String> _parseTxtAttributes(Map<String, List<int>>? txt) {
    if (txt == null) return {};

    final result = <String, String>{};
    for (var entry in txt.entries) {
      try {
        result[entry.key] = utf8.decode(entry.value);
      } catch (e) {
        result[entry.key] = '';
      }
    }
    return result;
  }

  // --- Остановка поиска ---
  Future<void> stopDiscovery() async {
    if (_discovery != null) {
      await nsd.stopDiscovery(_discovery!);
      _discovery = null;
      _devices.clear();
      notifyListeners();

      if (kDebugMode) {
        print('🔍 Поиск устройств остановлен');
      }
    }
  }

  // --- Обновление списка ---
  Future<void> refreshDevices() async {
    if (_discovery != null) {
      _updateDevicesList();
    } else {
      await startDiscovery();
    }
  }

  @override
  void dispose() {
    stopDiscovery();
    super.dispose();
  }
}

// --- Модель устройства ---
class DiscoveredDevice {
  final String id;
  final String name;
  final String ip;
  final int port;
  final String platform;
  final String version;
  DateTime lastSeen;
  final nsd.Service rawService;

  DiscoveredDevice({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
    required this.platform,
    required this.version,
    required this.lastSeen,
    required this.rawService,
  });

  String get description => '$name ($platform) - $ip:$port';

  @override
  String toString() => description;
}