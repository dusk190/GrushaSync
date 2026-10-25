import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

import 'network_utils.dart';
import 'log_service.dart';

class Opengrushafolder {
  static Future<void> openFolder() async {
    try {
      final grushaDir = await NetworkUtils.getDownloadDirectory();
      if (!await grushaDir.exists()) {
        await grushaDir.create(recursive: true);
      }

      if (Platform.isWindows) {
        await Process.start('explorer', [grushaDir.path]);
        LogService.info('App', 'Папка GrushaSync открыта в проводнике Windows: ${grushaDir.path}');
      } else if (Platform.isAndroid) {
        await _openAndroidFolder(grushaDir);
      }
    } catch (e) {
      LogService.error('App', 'Ошибка открытия папки GrushaSync', e);
    }
  }

  static Future<void> _openAndroidFolder(Directory grushaDir) async {
    final folderPath = grushaDir.path;
    // SAF URI для доступа к папке Download/GrushaSync
    const contentUri = 'content://com.android.externalstorage.documents/document/primary%3ADownload%2FGrushaSync';
    final fileUri = 'file://$folderPath';

    // Список специализированных интентов встроенных проводников для разных вендоров:
    final candidateIntents = <AndroidIntent>[
      // 1. Samsung "Мои файлы" (Samsung My Files)
      const AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'com.sec.android.app.myfiles',
        data: contentUri,
        type: 'resource/folder',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'com.sec.android.app.myfiles',
        data: fileUri,
        type: 'resource/folder',
        flags: const [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'com.sec.android.app.myfiles',
        componentName: 'com.sec.android.app.myfiles.external.ui.MainActivity',
        data: fileUri,
        flags: const [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      // 2. Google Pixel / DocumentsUI / Files by Google (чистый Android)
      const AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'com.google.android.documentsui',
        data: contentUri,
        type: 'vnd.android.document/directory',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'com.google.android.apps.nbu.files',
        data: contentUri,
        type: 'vnd.android.document/directory',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      // 3. Xiaomi / Redmi / POCO (MIUI & HyperOS)
      const AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'com.mi.android.globalFileexplorer',
        data: contentUri,
        type: 'resource/folder',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'com.android.fileexplorer',
        data: contentUri,
        type: 'resource/folder',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      // 4. OnePlus / OPPO / Realme (ColorOS, OxygenOS)
      const AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'com.coloros.filemanager',
        data: contentUri,
        type: 'resource/folder',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'com.oplus.filemanager',
        data: contentUri,
        type: 'resource/folder',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      // 5. Huawei / Honor
      const AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'com.huawei.hidisk',
        data: contentUri,
        type: 'resource/folder',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      // 6. Transsion (Tecno, Infinix, itel)
      const AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'com.transsion.filemanager',
        data: contentUri,
        type: 'resource/folder',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      // 7. Универсальный интент просмотра директории (показывает ТОЛЬКО файловые менеджеры, отсекая плееры/браузеры)
      const AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: contentUri,
        type: 'resource/folder',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: contentUri,
        type: 'vnd.android.document/directory',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      // 8. Системный переход в "Загрузки" (гарантированно открывает встроенный проводник)
      const AndroidIntent(
        action: 'android.intent.action.VIEW_DOWNLOADS',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
    ];

    // Фаза 1: проверяем через canResolveActivity для точного попадания
    for (final intent in candidateIntents) {
      try {
        final canResolve = await intent.canResolveActivity();
        if (canResolve == true) {
          await intent.launch();
          LogService.info('App', 'Папка открыта через проводник (${intent.package ?? intent.action})');
          return;
        }
      } catch (_) {}
    }

    // Фаза 2: если canResolveActivity ограничен системой Package Visibility, пробуем прямой запуск
    for (final intent in candidateIntents) {
      try {
        await intent.launch();
        LogService.info('App', 'Папка открыта через проводник (${intent.package ?? intent.action})');
        return;
      } catch (_) {}
    }

    LogService.warn('App', 'Ни один проводник не смог открыть папку');
  }
}
