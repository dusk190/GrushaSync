import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Проверка и запрос разрешений на доступ к файлам
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  /// Проверка статуса разрешения storage
  static Future<PermissionStatus> checkStoragePermission() async {
    return await Permission.storage.status;
  }

  /// Открыть системные настройки приложения
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Комплексная проверка и запрос всех необходимых разрешений при старте (Android 10..14)
  static Future<bool> ensurePermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;

      if (sdkInt >= 33) {
        // Android 13+
        final images = await Permission.photos.request();
        final videos = await Permission.videos.request();
        final audio = await Permission.audio.request();
        final storage = await Permission.manageExternalStorage.request();

        final allGranted = images.isGranted && videos.isGranted && audio.isGranted && storage.isGranted;

        if (allGranted) {
          if (kDebugMode) print('Разрешения для медиа получены (Android 13+)');
          return true;
        } else {
          if (images.isPermanentlyDenied || videos.isPermanentlyDenied || audio.isPermanentlyDenied) {
            if (kDebugMode) print('Разрешения отклонены навсегда');
            await openSettings();
          }
          return false;
        }
      } else if (sdkInt >= 30) {
        // Android 11-12
        final status = await Permission.manageExternalStorage.request();
        if (status.isGranted) {
          if (kDebugMode) print('Разрешение manageExternalStorage получено (Android 11-12)');
          return true;
        } else if (status.isPermanentlyDenied) {
          await openSettings();
          return false;
        }
        return false;
      } else {
        // Android 10 и ниже
        final status = await Permission.storage.request();
        if (status.isGranted) {
          return true;
        } else if (status.isPermanentlyDenied) {
          await openSettings();
          return false;
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Ошибка проверки разрешений: $e');
      return false;
    }
  }
}
