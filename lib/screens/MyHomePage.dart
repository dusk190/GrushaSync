import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:grushasync/widgets/MyDialButton.dart';
import 'package:provider/provider.dart';

import '../widgets/MyDeviceFolder.dart';
import '../services/dualModeService.dart';
import '../screens/PasswordSettingScreen.dart';
import '../services/OpenGrushaFolder.dart';
import '../screens/LogsPage.dart';
import '../services/network_utils.dart';

// Экран главного меню

class MyHomePage extends StatefulWidget {
  final VoidCallback changeTheme;
  const MyHomePage({super.key, required this.changeTheme});

  @override
  createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    final service = Provider.of<DualModeService>(context, listen: false);
    await service.initialize();
  }

  Future<void> _showEditDeviceNameDialog(DualModeService service) async {
    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final currentName = service.myDeviceName ?? await service.getCachedDeviceName();
    final defaultSystemName = await NetworkUtils.getDeviceName();
    final controller = TextEditingController(text: currentName);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          title: Text(
            'Имя устройства',
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Под этим именем ваше устройство будут видеть другие участники сети:',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 32,
                decoration: InputDecoration(
                  hintText: 'Например: Ноутбук Артема',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: controller.clear,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'По умолчанию: $defaultSystemName',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await service.setDeviceName(null);
                messenger.showSnackBar(
                  SnackBar(content: Text('Имя сброшено к системному: $defaultSystemName')),
                );
              },
              child: const Text('По умолчанию'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newName = controller.text.trim();
                Navigator.of(dialogCtx).pop();
                if (newName.isNotEmpty && newName != currentName) {
                  await service.setDeviceName(newName);
                  messenger.showSnackBar(
                    SnackBar(content: Text('Имя устройства изменено на "$newName"')),
                  );
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
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
                buttonSize: const Size(46, 46),
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
                      icon: const Icon(Icons.folder_open),
                      onTap: Opengrushafolder.openFolder,
                      context: context),
                  // Изменение пароля сети (переход на другой экран)
                  MyDialButton(
                      icon: const Icon(Icons.lock_outline),
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
                  // Логи приложения (Консоль)
                  MyDialButton(
                      icon: const Icon(Icons.terminal),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LogsPage()),
                        );
                      },
                      context: context),
                  if (Platform.isWindows)
                    MyDialButton(
                      icon: const Icon(Icons.refresh),
                      onTap: service.refreshMdns,
                      context: context)
                ]),
              const SizedBox(width: 5,)
            ],

            backgroundColor: Theme.of(context).colorScheme.secondary,
            // Название нашего устройства с возможностью редактирования по клику
            titleTextStyle: Theme.of(context).textTheme.displayLarge,
            title: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showEditDeviceNameDialog(service),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        "GS (${service.myDeviceName ?? 'загрузка...'})",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit, size: 16, color: Colors.grey),
                  ],
                ),
              ),
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
        (Platform.isAndroid ? SingleChildScrollView(
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
        ) : const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_find_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Другие устройства'),
              Text('в сети не обнаружены')
            ],
          ),
        )
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
    );
  }
}
