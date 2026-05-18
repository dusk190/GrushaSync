import 'package:flutter/material.dart';
import '../widgets/MyDeviceFolder.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'dart:io';
import '../services/dualModeService.dart';
import '../screens/PasswordSettingScreen.dart';
// Ыункция для открытия папки
Future<void> _openGrushaFolder() async {
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
// Экран главного меню

class MyHomePage extends StatefulWidget {
  final VoidCallback changeTheme;
  const MyHomePage({super.key, required this.changeTheme});

  @override
  createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  late Future<String> _deviceName;
  @override
  void initState() {
    super.initState();
    _deviceName = _initAndGetName();
  }

  Future<String> _initAndGetName() async {
    final service = Provider.of<DualModeService>(context, listen: false);
    await service.initialize();
    return await service.getCachedDeviceName();
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<DualModeService>(context);
    final peers = service.peers;

    return Scaffold(
        // Полоса сверху экрана
        appBar: AppBar(
            actions: [
              IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: _openGrushaFolder,
                tooltip: "Открыть папку GrushaSync",
              ),
              IconButton(
                icon: const Icon(Icons.lock_outline),
                onPressed: () {
                    Navigator.push(context, PageRouteBuilder(
                      pageBuilder: (context, anim, secAnim) => PasswordSettingsScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                    );
                },
                tooltip: 'Настройки сети',
              ),

              // Кнопка переключения темной/светлой темы
              IconButton(
                icon: Icon(Theme.of(context).brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode),
                onPressed: widget.changeTheme,
              ), SizedBox(width: 5,)
            ],
            titleTextStyle: Theme.of(context).textTheme.displayLarge,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            title: FutureBuilder<String>(
                future: _deviceName,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text("GS (${snapshot.data})");
                  }
                  return const Text("GS (загрузка...)");
                },
            ),
            // Декоративная полоска для разделения appBar и body
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: Container(
                color: Theme.of(context).colorScheme.primary,
                height: 2,
              ),)
        ),

        // Список пиров, билдится как панели-кнопки
        body: ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: peers.length,
            itemBuilder: (context, index) {
              final peer = peers[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MyDeviceFolder(peer),
              );
            }),

        /*
        floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final String? selectedName = await showDialog<String>(
                context: context,
                builder: (context) => DeviceSelectionDialog(availableDevices: availableDevices,),
              );
              if (selectedName != null) {
                setState(() {
                  currentDevices.add(selectedName);
                  availableDevices.remove(selectedName);
                });
              }
              },
          tooltip: 'Добавить устройство',
          child: const Icon(Icons.add),
        ),*/
    );
  }
}
