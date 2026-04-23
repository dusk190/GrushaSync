import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:nsd/nsd.dart' as nsd;

/// Сервис регистрации устройства в локальной сети
/// Устройство вещает: "Я здесь, меня зовут X, мой IP Y, порт Z"
class DeviceRegistrationService extends ChangeNotifier {
  // NSD компоненты
  nsd.Registration? _registration;

  // Состояние
  bool _isRegistered = false;
  String? _registeredName;
  int? _registeredPort;
  String? _currentIp;

  // Геттеры
  bool get isRegistered => _isRegistered;
  String? get registeredName => _registeredName;
  int? get registeredPort => _registeredPort;
  String? get currentIp => _currentIp;

  // Тип сервиса (все устройства в сети используют один и тот же)
  static const String serviceType = '_grushasync._tcp.';

  // --- Получение текущего IP адреса ---
  Future<String?> getCurrentIp() async {
    try {
      final info = NetworkInfo();
      final ip = await info.getWifiIP();
      _currentIp = ip;
      return ip;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения IP: $e');
      }
      return null;
    }
  }

  // --- Генерация уникального имени устройства ---
  Future<String> generateDeviceName() async {
    final ip = await getCurrentIp();
    final lastIpPart = ip?.split('.').last ?? 'unknown';

    // Пытаемся получить имя устройства с хоста
    String hostName = '';
    try {
      hostName = Platform.localHostname.split('.').first;
    } catch (e) {
      hostName = 'Device';
    }

    return '$hostName-$lastIpPart';
  }

  // --- Регистрация устройства в сети ---
  /// Устройство начинает вещать: "Я здесь, меня зовут [name], мой IP [ip], порт [port]"
  Future<bool> registerDevice({
    required String deviceName,
    required int port,
    Map<String, String>? additionalAttributes,
  }) async {
    // Останавливаем предыдущую регистрацию
    await unregisterDevice();

    try {
      // Получаем текущий IP
      final ip = await getCurrentIp();
      if (ip == null) {
        if (kDebugMode) {
          print('Не удалось получить IP адрес');
        }
        return false;
      }

      // Подготавливаем атрибуты (TXT record)
      final Map<String, Uint8List> txtAttributes = {
        'device_name': Uint8List.fromList(utf8.encode(deviceName)),
        'device_ip': Uint8List.fromList(utf8.encode(ip)),
        'version': Uint8List.fromList(utf8.encode('1.0')),
        'platform': Uint8List.fromList(utf8.encode(Platform.operatingSystem)),
      };

      // Добавляем дополнительные атрибуты
      if (additionalAttributes != null) {
        additionalAttributes.forEach((key, value) {
          txtAttributes[key] = Uint8List.fromList(utf8.encode(value));
        });
      }

      // Создаём сервис
      final service = nsd.Service(
        name: deviceName,
        type: serviceType,
        port: port,
        txt: txtAttributes,
      );

      // Регистрируем в сети
      _registration = await nsd.register(service);

      _isRegistered = true;
      _registeredName = deviceName;
      _registeredPort = port;
      _currentIp = ip;

      notifyListeners();

      if (kDebugMode) {
        print('УСТРОЙСТВО ЗАРЕГИСТРИРОВАНО');
        print('Имя:     $deviceName');
        print('IP:      $ip');
        print('Порт:    $port');
        print('Тип:     $serviceType');

      }

      return true;

    } catch (e) {
      if (kDebugMode) {
        print(' Ошибка регистрации устройства: $e');
      }
      return false;
    }
  }

  // --- Обновление информации устройства ---
  /// Если изменился IP или порт, нужно перерегистрироваться
  Future<bool> updateRegistration({
    String? deviceName,
    int? port,
    Map<String, String>? additionalAttributes,
  }) async {
    if (!_isRegistered) {
      if (kDebugMode) {
        print(' Устройство не зарегистрировано');
      }
      return false;
    }

    final newName = deviceName ?? _registeredName!;
    final newPort = port ?? _registeredPort!;

    return await registerDevice(
      deviceName: newName,
      port: newPort,
      additionalAttributes: additionalAttributes,
    );
  }

  // --- Остановка регистрации (устройство уходит из сети) ---
  Future<void> unregisterDevice() async {
    if (_registration != null) {
      await nsd.unregister(_registration!);
      _registration = null;
    }

    _isRegistered = false;
    _registeredName = null;
    _registeredPort = null;

    notifyListeners();

    if (kDebugMode) {
      print(' Устройство отключено от сети (регистрация остановлена)');
    }
  }

  // --- Получение информации о себе в виде строки (для отладки) ---
  String getRegistrationInfo() {
    if (!_isRegistered) {
      return ' Устройство не зарегистрировано';
    }

    return '''
   ИНФОРМАЦИЯ О УСТРОЙСТВЕ:
   Имя:     $_registeredName
   IP:      $_currentIp
   Порт:    $_registeredPort
   Тип:     $serviceType
   Статус:  Активен ✓
    ''';
  }

  @override
  void dispose() {
    unregisterDevice();
    super.dispose();
  }
}