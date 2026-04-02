// добавить в зависимости флаттреа network_info_plus: ^5.0.3

import 'package:network_info_plus/network_info_plus.dart';

Future<String?> getLocalIp() async {
  final info = NetworkInfo();

  try {
    final ip = await info.getWifiIP();
    return ip;
  } catch (e) {
    print('Ошибка получения IP: $e');
    return null;
  }
}