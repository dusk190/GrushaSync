import 'package:flutter/material.dart';
import 'package:untitled3333333/widgets/MyDeviceFolder.dart';
import 'package:provider/provider.dart';
import '../services/dualModeService.dart';

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
    // Инициализация сервиса при старте экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = Provider.of<DualModeService>(context, listen: false);
      service.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<DualModeService>(context);
    final peers = service.peers;

    return Scaffold(
        appBar: AppBar(
            actions: [
              IconButton(
                icon: Icon(Theme.of(context).brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode),
                onPressed: widget.changeTheme,
              ), SizedBox(width: 5,)
            ],
            titleTextStyle: Theme.of(context).textTheme.displayLarge,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            title: Text("GrushaSync"),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: Container(
                color: Theme.of(context).colorScheme.primary,
                height: 2,
              ),)
        ),

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
