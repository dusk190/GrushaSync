import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:path_provider/path_provider.dart';

class Opengrushafolder {
  static Future<void> openFolder() async {
    try {
      Directory grushaDir;
      if (Platform.isWindows){
        final downloadPath = '${Platform.environment['USERPROFILE']}\\Downloads\\GrushaSync';
        grushaDir = Directory(downloadPath);
        if (!await grushaDir.exists()){
          await grushaDir.create(recursive: true);
        }
        await Process.start('explorer', [grushaDir.path]);
      }
      else if (Platform.isAndroid){
        final downloadDir = await getDownloadsDirectory();
        if (downloadDir == null){
          print("Не удалось получить доступ к папке Загрузки");
          return;
        }
        grushaDir = Directory("${downloadDir.path}/GrushaSync");
        if (!await grushaDir.exists()){
          await grushaDir.create(recursive: true);
        }
        final AndroidIntent intent = AndroidIntent(
          action: "android.intent.action.VIEW",
          data: Uri.encodeFull(grushaDir.path),
          type: '*/*',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();

      }

    } catch (e){
      print("Ошибка открытия папки $e");

    }
  }
}