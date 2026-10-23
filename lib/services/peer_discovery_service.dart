import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart' as nsd;
import '../models/peer_device.dart';
import 'mdnsService.dart';
import 'network_utils.dart';

class PeerDiscoveryService extends ChangeNotifier {
  final MdnsService _mdns = MdnsService();
  final List<PeerDevice> _peers = [];
  String? _myDeviceName;
  String? _currentIp;
  String? _networkPassword;

  List<PeerDevice> get peers => _peers;
  MdnsService get mdns => _mdns;
  String? get networkPassword => _networkPassword;

  PeerDiscoveryService() {
    _mdns.addListener(_onMdnsChanged);
  }

  void setSelfInfo({required String deviceName, required String? currentIp, String? networkPassword}) {
    _myDeviceName = deviceName;
    _currentIp = currentIp;
    _networkPassword = networkPassword;
  }

  Future<void> registerSelf({
    required String deviceName,
    required int port,
    String? ip,
    String? networkPassword,
  }) async {
    _myDeviceName = deviceName;
    _currentIp = ip;
    _networkPassword = networkPassword;
    await _mdns.registerService(
      deviceName,
      port,
      ip: ip,
      networkPassword: networkPassword,
    );
  }

  Future<void> startDiscovery() async {
    await _mdns.startDiscovery();
  }

  Future<void> stopDiscovery() async {
    await _mdns.stopDiscovery();
  }

  Future<void> refreshDiscovery() async {
    await _mdns.stopDiscovery();
    _peers.clear();
    notifyListeners();
    await _mdns.startDiscovery();
    await _updatePeersFromMdns();
  }

  void removePeer(PeerDevice peer) {
    final beforeCount = _peers.length;
    _peers.removeWhere((p) => p.id == peer.id || (p.host == peer.host && p.port == peer.port));
    if (_peers.length != beforeCount) {
      if (kDebugMode) {
        print('Оффлайн-устройство удалено: ${peer.name} (${peer.host})');
      }
      notifyListeners();
    }
  }

  Future<void> _onMdnsChanged() async {
    await _updatePeersFromMdns();
  }

  Future<void> _updatePeersFromMdns() async {
    final servicesCopy = _mdns.services.toList();
    _peers.clear();

    for (var service in servicesCopy) {
      final serviceName = service.name ?? '';
      final serviceHost = service.host ?? '';

      // Пропускаем своё устройство по имени
      if (_myDeviceName != null && serviceName == _myDeviceName) {
        if (kDebugMode) print('Пропускаем своё устройство: $serviceName');
        continue;
      }

      // Фильтрация по паролю сети
      final servicePassword = _getPasswordFromService(service);
      if (_networkPassword != null && _networkPassword!.isNotEmpty) {
        if (servicePassword != _networkPassword) {
          if (kDebugMode) print('Пропускаем устройство $serviceName, пароль не совпадает');
          continue;
        }
      } else if (servicePassword != null && servicePassword.isNotEmpty) {
        if (kDebugMode) print('Пропускаем устройство $serviceName, защищено паролем');
        continue;
      }

      // Определение IP-адреса пира
      String? resolvedIp;

      // 1. IP из mDNS TXT-записи (мгновенно и надежно)
      final txtIp = _getIpFromService(service);
      if (txtIp != null && txtIp.isNotEmpty) {
        resolvedIp = txtIp;
        if (kDebugMode) print('IP получен из TXT-записи $serviceName: $resolvedIp');
      }

      // 2. IP из разрешенных адресов nsd
      if (resolvedIp == null && service.addresses != null) {
        for (var addr in service.addresses!) {
          if (addr.type == InternetAddressType.IPv4) {
            resolvedIp = addr.address;
            if (kDebugMode) print('IP получен из service.addresses: $resolvedIp');
            break;
          }
        }
      }

      // 3. Если serviceHost уже является корректным IPv4
      if (resolvedIp == null) {
        final parsed = InternetAddress.tryParse(serviceHost);
        if (parsed != null && parsed.type == InternetAddressType.IPv4) {
          resolvedIp = parsed.address;
        }
      }

      // 4. Fallback-резолвинг хостнейма
      if (resolvedIp == null) {
        if (serviceHost.contains(':') || serviceHost.contains('%')) {
          if (kDebugMode) print('Пропускаем IPv6 адрес: $serviceHost');
          continue;
        }

        if (kDebugMode) print('Разрешаем имя: $serviceHost');
        resolvedIp = await NetworkUtils.resolveLocalHostname(serviceHost);
      }

      if (resolvedIp == null) {
        if (kDebugMode) print('Не удалось разрешить $serviceHost, пропускаем');
        continue;
      }

      // Пропускаем собственный IP
      if (_currentIp != null && resolvedIp == _currentIp) {
        if (kDebugMode) print('Пропускаем свой собственный IP: $resolvedIp');
        continue;
      }

      final exist = _peers.any((peer) =>
          peer.id == service.name ||
          (peer.host == resolvedIp && peer.port == (service.port ?? 8080)));

      if (!exist) {
        _peers.add(PeerDevice(
          id: service.name ?? 'unknown',
          name: service.name ?? 'Unknown',
          host: resolvedIp,
          port: service.port ?? 8080,
          lastSeen: DateTime.now(),
        ));
        if (kDebugMode) print('Устройство добавлено: $serviceName → $resolvedIp:${service.port}');
      }
    }

    notifyListeners();

    if (kDebugMode) {
      print('Обновлён список пиров: ${_peers.length} устройств');
      for (var p in _peers) {
        print('   - ${p.name} (${p.host}:${p.port})');
      }
    }
  }

  String? _getPasswordFromService(nsd.Service service) {
    final passwordBytes = service.txt?['password'];
    if (passwordBytes != null) {
      try {
        return utf8.decode(passwordBytes);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  String? _getIpFromService(nsd.Service service) {
    final ipBytes = service.txt?['ip'];
    if (ipBytes != null) {
      try {
        return utf8.decode(ipBytes);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _mdns.removeListener(_onMdnsChanged);
    _mdns.unregisterService();
    _mdns.stopDiscovery();
    super.dispose();
  }
}
