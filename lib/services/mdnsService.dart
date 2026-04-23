import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart' as nsd;

class MdnsService extends ChangeNotifier {
  nsd.Registration? _registration;
  nsd.Discovery? _discovery;

  final List<nsd.Service> _services = [];
  List<nsd.Service> get services => _services;

  bool get isRegistered => _registration != null;
  bool get isDiscovering => _discovery != null;

  // Тип сервиса. Для nsd лучше не использовать точку в конце.
  static const String serviceType = '_fileshare._tcp';

  // --- Регистрация сервиса ---
  Future<bool> registerService(String serviceName, int port) async {
    await unregisterService();

    try {
      _registration = await nsd.register(nsd.Service(
        name: serviceName,
        type: serviceType,
        port: port,
        // Атрибуты в nsd должны быть в формате Map<String, Uint8List?>
        txt: {
          'device_name': Uint8List.fromList(utf8.encode(serviceName)),
          'version': Uint8List.fromList(utf8.encode('1.0')),
        },
      ));

      notifyListeners();

      if (kDebugMode) {
        print('✅ mDNS: Сервис "$serviceName" зарегистрирован на порту $port');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ mDNS: Ошибка регистрации: $e');
      }
      return false;
    }
  }

  // --- Поиск сервисов ---
  Future<void> startDiscovery() async {
    await stopDiscovery();
    _services.clear();

    try {
      // Используем префикс nsd для вызова функции из пакета
      _discovery = await nsd.startDiscovery(serviceType);

      _discovery?.addListener(() {
        _services.clear();
        // Добавляем найденные сервисы в наш список
        _services.addAll(_discovery!.services);
        notifyListeners();

        if (kDebugMode) {
          print('🔍 mDNS: Найдено ${_services.length} сервисов');
        }
      });

      notifyListeners();

      if (kDebugMode) {
        print('mDNS: Поиск сервисов запущен');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ mDNS: Ошибка поиска: $e');
      }
    }
  }

  // --- Остановка поиска ---
  Future<void> stopDiscovery() async {
    final discovery = _discovery;
    if (discovery != null) {
      await nsd.stopDiscovery(discovery);
      _discovery = null;
      _services.clear();
      notifyListeners();

      if (kDebugMode) {
        print('mDNS: Поиск сервисов остановлен');
      }
    }
  }

  // --- Остановка регистрации ---
  Future<void> unregisterService() async {
    final registration = _registration;
    if (registration != null) {
      await nsd.unregister(registration);
      _registration = null;
      notifyListeners();

      if (kDebugMode) {
        print('mDNS: Регистрация сервиса остановлена');
      }
    }
  }

  // --- Безопасное получение хоста ---
  String getServiceHost(nsd.Service service) {
    return service.host ?? 'Unknown Host';
  }

  // --- Безопасное получение порта ---
  int getServicePort(nsd.Service service) {
    return service.port ?? 0;
  }

  @override
  void dispose() {
    // В dispose вызываем функции пакета напрямую
    if (_registration != null) nsd.unregister(_registration!);
    if (_discovery != null) nsd.stopDiscovery(_discovery!);
    super.dispose();
  }
}
