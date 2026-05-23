import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:grushasync/widgets/MyDialButton.dart';
import 'package:provider/provider.dart';

import '../widgets/MyDeviceFolder.dart';
import '../services/dualModeService.dart';
import '../screens/PasswordSettingScreen.dart';
import '../services/OpenGrushaFolder.dart';


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
              // При нажатии кнопки настроек выдвигаются вниз
              SpeedDial(
                icon: Icons.settings,
                iconTheme: IconThemeData(
                    color: Theme.of(context).colorScheme.onSecondary
                ),
                activeIcon: Icons.close,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                shape: CircleBorder(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    ),
                  ),

                childrenButtonSize: const Size(46, 46),
                elevation: 0,
                spacing: 7,
                buttonSize: Size(46, 46),
                childPadding: EdgeInsets.zero,
                spaceBetweenChildren: 5,

                direction: SpeedDialDirection.down,
                  closeDialOnPop: true,
                visible: true,
                closeManually: false,
                renderOverlay: false,
                children: [
                  // Открытие папки груши в проводнике
                  MyDialButton(
                      icon: Icon(Icons.folder_open),
                      onTap: Opengrushafolder.openFolder,
                      context: context),
                  // Изменение пароля сети (переход на другой экран)
                  MyDialButton(
                      icon: Icon(Icons.lock_outline),
                      onTap: () {
                        Navigator.push(context, PageRouteBuilder(
                          pageBuilder: (context, anim, secAnim) => PasswordSettingsScreen(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),);
                      },
                      context: context),
                  // Переключение темной/светлой темы
                  MyDialButton(icon: Icon(Theme.of(context).brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode),
                      onTap: widget.changeTheme,
                      context: context),
                  if (Platform.isWindows)
                    MyDialButton(
                      icon: Icon(Icons.refresh),
                      onTap: service.refreshMdns,
                      context: context)
                ]),
              SizedBox(width: 5,)
            ],

            backgroundColor: Theme.of(context).colorScheme.secondary,
            // Название нашего устройства
            titleTextStyle: Theme.of(context).textTheme.displayLarge,
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

        // Список пиров, билдится как панели-кнопки,
        // либо сообщение об отсутствии устройств в области видимости
        body: RefreshIndicator(
        onRefresh: service.refreshMdns,
        child: peers.isEmpty ?
        SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              // Растягиваем контейнер на всю высоту экрана минус высота AppBar и отступов
              height: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top,
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_find_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Другие устройства'),
                  Text('в сети не обнаружены'),
                ],
              ),
            ),
        )
         :
        ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: peers.length,
            itemBuilder: (context, index) {
              final peer = peers[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MyDeviceFolder(peer),
              );
            }),
        )

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
