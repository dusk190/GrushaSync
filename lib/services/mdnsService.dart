import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'log_service.dart';
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
  Future<bool> registerService(String serviceName, int port, {String? ip, String? networkPassword}) async {
    await unregisterService();

    try {
      final Map<String, Uint8List> txt = {
        "device_name": Uint8List.fromList(utf8.encode(serviceName)),
        "version": Uint8List.fromList(utf8.encode('1.0')),
      };
      if (ip != null && ip.isNotEmpty) {
        txt['ip'] = Uint8List.fromList(utf8.encode(ip));
      }
      if (networkPassword != null && networkPassword.isNotEmpty){
        txt['password'] = Uint8List.fromList(utf8.encode(networkPassword));
      }
      _registration = await nsd.register(nsd.Service(
        name: serviceName,
        type: serviceType,
        port: port,
        // Атрибуты в nsd должны быть в формате Map<String, Uint8List?>
        txt: txt,
      ));

      notifyListeners();

      LogService.info('mDNS', 'Сервис "$serviceName" зарегистрирован в сети на порту $port${ip != null ? " (IP: $ip)" : ""}');
      if (networkPassword != null && networkPassword.isNotEmpty){
        LogService.info('mDNS', 'Пароль сети активирован для объявления');
      }

      return true;
    } catch (e) {
      LogService.error('mDNS', 'Ошибка регистрации сервиса "$serviceName"', e);
      return false;
    }
  }

  // --- Поиск сервисов ---
  Future<void> startDiscovery() async {
    await stopDiscovery();
    _services.clear();

    try {
      // Используем префикс nsd для вызова функции из пакета
      _discovery = await nsd.startDiscovery(serviceType, ipLookupType: nsd.IpLookupType.any);

      _discovery?.addListener(() {
        _services.clear();
        // Добавляем найденные сервисы в наш список
        _services.addAll(_discovery!.services);
        notifyListeners();

        LogService.info('mDNS', 'Событие mDNS: получено ${_services.length} объявлений сервисов');
        for (var s in _services) {
          LogService.debug('mDNS', '  -> объявление: "${s.name}" (хост: ${s.host}, порт: ${s.port})');
        }
      });

      notifyListeners();
      LogService.info('mDNS', 'Поиск устройств запущен в локальной сети (сервис: $serviceType)');
    } catch (e) {
      LogService.error('mDNS', 'Ошибка запуска mDNS поиска', e);
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
      LogService.info('mDNS', 'Поиск mDNS остановлен');
    }
  }

  // --- Остановка регистрации ---
  Future<void> unregisterService() async {
    final registration = _registration;
    if (registration != null) {
      await nsd.unregister(registration);
      _registration = null;
      notifyListeners();
      LogService.info('mDNS', 'Регистрация сервиса mDNS остановлена');
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
