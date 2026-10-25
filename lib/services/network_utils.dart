import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

class NetworkUtils {
  /// Получение локального IPv4-адреса устройства.
  /// На мобильных платформах опрашивает Wi-Fi, на десктопе отсекает VPN и виртуальные интерфейсы.
  static Future<String?> getLocalIp() async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final info = NetworkInfo();
        final wifiIp = await info.getWifiIP();
        if (wifiIp != null && wifiIp.isNotEmpty && wifiIp != '0.0.0.0') {
          if (kDebugMode) print('Найден Wi-Fi IP через NetworkInfo: $wifiIp');
          return wifiIp;
        }
      } catch (e) {
        if (kDebugMode) print('Ошибка получения Wi-Fi IP: $e');
      }
    }

    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
      );

      bool isVirtual(String name) {
        final lower = name.toLowerCase();
        return lower.contains('virtual') ||
            lower.contains('vmware') ||
            lower.contains('vbox') ||
            lower.contains('wsl') ||
            lower.contains('docker') ||
            lower.contains('tailscale') ||
            lower.contains('hamachi') ||
            lower.contains('radmin') ||
            lower.contains('fam') ||
            lower.contains('wireguard') ||
            lower.contains('zerotier') ||
            lower.contains('tap') ||
            lower.contains('tun') ||
            lower.contains('vpn') ||
            lower.contains('vethernet') ||
            lower.contains('hyper-v') ||
            lower.contains('loopback') ||
            lower.contains('bluetooth') ||
            lower.contains('pseudo') ||
            lower.contains('teredo') ||
            lower.contains('pcap');
      }

      final candidates = <_CandidateIp>[];

      for (var interface in interfaces) {
        final virtual = isVirtual(interface.name);
        for (var addr in interface.addresses) {
          if (addr.type != InternetAddressType.IPv4) continue;
          final ip = addr.address;
          if (ip.startsWith('127.') || ip.startsWith('169.254.') || ip == '0.0.0.0') {
            continue;
          }

          int score = 0;
          if (!virtual) {
            score += 1000;
          }

          if (ip.startsWith('192.168.')) {
            score += 500;
          } else if (ip.startsWith('10.')) {
            score += 300;
          } else if (_isPrivate172(ip)) {
            score += 200;
          } else if (ip.startsWith('26.')) {
            // Radmin VPN
            score -= 500;
          } else {
            score += 100;
          }

          final lower = interface.name.toLowerCase();
          if (lower.contains('wi-fi') ||
              lower.contains('wifi') ||
              lower.contains('wlan') ||
              lower.contains('беспроводн') ||
              lower.contains('ethernet') ||
              lower.contains('eth') ||
              lower.contains('lan')) {
            score += 100;
          }

          candidates.add(_CandidateIp(ip, interface.name, score));
        }
      }

      if (candidates.isNotEmpty) {
        candidates.sort((a, b) => b.score.compareTo(a.score));
        if (kDebugMode) {
          for (var c in candidates) {
            print('IP-кандидат: ${c.ip} (${c.interfaceName}) score=${c.score}');
          }
        }
        return candidates.first.ip;
      }
    } catch (e) {
      if (kDebugMode) print('Ошибка NetworkInterface: $e');
    }
    return null;
  }

  static bool _isPrivate172(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4 || parts[0] != '172') return false;
    final second = int.tryParse(parts[1]);
    return second != null && second >= 16 && second <= 31;
  }

  /// Читаемое имя модели устройства
  static Future<String> getReadableModel() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.model.isNotEmpty ? androidInfo.model : 'Android';
    } else if (Platform.isWindows) {
      return Platform.localHostname.split('.').first;
    }
    return 'Device';
  }

  /// Уникальное имя устройства для сети (Модель-ОкончаниеIP)
  static Future<String> getDeviceName() async {
    final deviceModel = await getReadableModel();
    final ip = await getLocalIp();
    final suffix = ip?.split('.').last ?? 'unknown';
    return '$deviceModel-$suffix';
  }

  /// Форматирование размера файла в B, KB, MB, GB
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Форматирование хоста для URL с поддержкой IPv6
  static String formatHostForUrl(String host, int port) {
    if (host.contains(':') && !host.contains('.')) {
      return '[$host]:$port';
    }
    return '$host:$port';
  }

  /// Резолвинг .local хостнейма в IPv4 (fallback)
  static Future<String?> resolveLocalHostname(String hostname) async {
    try {
      final cleanHost = hostname.endsWith('.') ? hostname.substring(0, hostname.length - 1) : hostname;
      final addresses = await InternetAddress.lookup(cleanHost);

      for (var addr in addresses) {
        if (addr.type == InternetAddressType.IPv4) {
          if (kDebugMode) print('Разрешено (IPv4): ${addr.address}');
          return addr.address;
        }
      }
    } catch (_) {}

    if (hostname.contains('.local')) {
      try {
        final cleanHostname = hostname.replaceAll('.local.', '').replaceAll('.local', '');
        final addresses = await InternetAddress.lookup(cleanHostname);

        for (var addr in addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            if (kDebugMode) print('Разрешено без .local (IPv4): ${addr.address}');
            return addr.address;
          }
        }
      } catch (e) {
        if (kDebugMode) print('Ошибка разрешения $hostname: $e');
      }
    }

    if (kDebugMode) print('IPv4 не найден для $hostname, пропускаем');
    return null;
  }

  /// Папка для сохранения скачанных файлов (Downloads/GrushaSync)
  static Future<Directory> getDownloadDirectory() async {
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
      const downloadsPath = '/storage/emulated/0/Download';
      final grushaDir = Directory('$downloadsPath/GrushaSync');
      try {
        if (!await grushaDir.exists()) {
          await grushaDir.create(recursive: true);
        }
        return grushaDir;
      } catch (e) {
        if (kDebugMode) print('Не удалось создать папку GrushaSync: $e');
        return Directory(downloadsPath);
      }
    }
  }
}

class _CandidateIp {
  final String ip;
  final String interfaceName;
  final int score;

  _CandidateIp(this.ip, this.interfaceName, this.score);
}
