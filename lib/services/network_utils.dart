import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'log_service.dart';

class NetworkUtils {
  /// Проверка, является ли сетевой интерфейс виртуальным или VPN
  static bool isVirtualInterface(String name) {
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

  /// Получение локального IPv4-адреса устройства.
  /// На мобильных платформах опрашивает Wi-Fi, на десктопе отсекает VPN и виртуальные интерфейсы.
  static Future<String?> getLocalIp() async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final info = NetworkInfo();
        final wifiIp = await info.getWifiIP();
        if (wifiIp != null && wifiIp.isNotEmpty && wifiIp != '0.0.0.0') {
          LogService.info('Network', 'Найден Wi-Fi IP через NetworkInfo: $wifiIp');
          return wifiIp;
        }
      } catch (e) {
        LogService.warn('Network', 'Не удалось получить Wi-Fi IP через NetworkInfo: $e');
      }
    }

    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
      );

      final candidates = <_CandidateIp>[];

      for (var interface in interfaces) {
        final virtual = isVirtualInterface(interface.name);
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
        for (var c in candidates) {
          LogService.debug('Network', 'IP-кандидат: ${c.ip} (${c.interfaceName}) score=${c.score}');
        }
        final chosen = candidates.first.ip;
        LogService.info('Network', 'Выбран локальный IP через адаптер "${candidates.first.interfaceName}": $chosen');
        return chosen;
      } else {
        LogService.warn('Network', 'Не найдено подходящих IPv4 кандидатов среди интерфейсов');
      }
    } catch (e) {
      LogService.error('Network', 'Ошибка перечисления NetworkInterface', e);
    }
    return null;
  }

  /// Полная диагностика сети с подробной записью параметров в LogService
  static Future<void> logNetworkDiagnostics() async {
    LogService.info('Network', '================= ДИАГНОСТИКА СЕТИ =================');

    // 1. Wi-Fi параметры
    try {
      final info = NetworkInfo();
      final wifiName = await info.getWifiName();
      final wifiBSSID = await info.getWifiBSSID();
      final wifiIp = await info.getWifiIP();
      final wifiGateway = await info.getWifiGatewayIP();
      final wifiSubmask = await info.getWifiSubmask();
      final wifiBroadcast = await info.getWifiBroadcast();
      final wifiIPv6 = await info.getWifiIPv6();

      LogService.info('Network', '[Wi-Fi] Имя сети (SSID): ${wifiName ?? "недоступно (на Android нужен доступ к геопозиции)"}');
      LogService.info('Network', '[Wi-Fi] MAC точки (BSSID): ${wifiBSSID ?? "недоступно"}');
      LogService.info('Network', '[Wi-Fi] IP устройства: ${wifiIp ?? "не определен"} | Шлюз (роутер): ${wifiGateway ?? "н/д"} | Маска: ${wifiSubmask ?? "н/д"}');
      LogService.info('Network', '[Wi-Fi] Broadcast: ${wifiBroadcast ?? "н/д"} | IPv6: ${wifiIPv6 ?? "н/д"}');
    } catch (e) {
      LogService.warn('Network', 'Сбой чтения данных Wi-Fi: $e');
    }

    // 2. Сетевые адаптеры ОС
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
      );

      LogService.info('Network', '[Сетевые интерфейсы ОС (${interfaces.length} шт.)]:');
      for (var iface in interfaces) {
        final isVirt = isVirtualInterface(iface.name);
        final addrs = iface.addresses.map((a) => '${a.address} (${a.type.name})').join(', ');
        final tag = isVirt ? ' [ВИРТУАЛЬНЫЙ/VPN]' : ' [ФИЗИЧЕСКИЙ]';
        LogService.info('Network', '  • "${iface.name}"$tag: $addrs');
      }
    } catch (e) {
      LogService.warn('Network', 'Сбой перечисления сетевых интерфейсов: $e');
    }

    // 3. Выбранный локальный IP
    final chosenIp = await getLocalIp();
    LogService.info('Network', '[Выбранный рабочий IP]: ${chosenIp ?? "НЕ ОПРЕДЕЛЕН"}');

    // 4. Проверка DNS и выхода в интернет
    try {
      final lookup = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 2));
      if (lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty) {
        LogService.info('Network', '[Связь/Интернет] Доступ в Интернет есть (DNS резолвится корректно)');
      }
    } catch (e) {
      LogService.warn('Network', '[Связь/Интернет] Нет доступа в Интернет или заблокирован DNS (возможен Captive Portal / изоляция клиентов)');
    }

    // 5. Диагностический анализ подсети
    if (chosenIp != null) {
      if (chosenIp.startsWith('192.168.')) {
        LogService.info('Network', '[Анализ] Стандартная домашняя/офисная подсеть Class C (192.168.x.x)');
      } else if (chosenIp.startsWith('10.')) {
        LogService.info('Network', '[Анализ] Корпоративная подсеть Class A (10.x.x.x). Внимание: в крупных сетях телефоны и ПК часто изолируют в разные VLAN!');
      } else if (_isPrivate172(chosenIp)) {
        LogService.info('Network', '[Анализ] Корпоративная подсеть Class B (172.16-31.x.x)');
      } else if (chosenIp.startsWith('169.254.')) {
        LogService.error('Network', '[Анализ] Link-Local/APIPA (169.254.x.x) — DHCP сервер роутера не выдал IP-адрес!');
      } else {
        LogService.warn('Network', '[Анализ] Нестандартный/публичный адрес: $chosenIp');
      }
    }

    LogService.info('Network', '====================================================');
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
          LogService.debug('Network', 'Хостнейм $hostname разрешен (IPv4): ${addr.address}');
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
            LogService.debug('Network', 'Хостнейм разрешен без .local (IPv4): ${addr.address}');
            return addr.address;
          }
        }
      } catch (e) {
        LogService.warn('Network', 'Ошибка разрешения хостнейма $hostname: $e');
      }
    }

    LogService.warn('Network', 'IPv4 не найден для $hostname, пропускаем');
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
    } else if (Platform.isIOS) {
      final docDir = await getApplicationDocumentsDirectory();
      final grushaDir = Directory('${docDir.path}/GrushaSync');
      if (!await grushaDir.exists()) {
        await grushaDir.create(recursive: true);
      }
      return grushaDir;
    } else {
      const downloadsPath = '/storage/emulated/0/Download';
      final grushaDir = Directory('$downloadsPath/GrushaSync');
      try {
        if (!await grushaDir.exists()) {
          await grushaDir.create(recursive: true);
        }
        return grushaDir;
      } catch (e) {
        LogService.error('Network', 'Не удалось создать папку GrushaSync', e);
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
