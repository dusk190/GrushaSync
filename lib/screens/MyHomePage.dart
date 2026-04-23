import 'package:flutter/material.dart';
import 'package:untitled3333333/widgets/MyDeviceFolder.dart';
import 'package:untitled3333333/widgets/DeviceSelectionDialog.dart';

class MyHomePage extends StatefulWidget {
  final VoidCallback changeTheme;
  const MyHomePage({super.key, required this.changeTheme});

  @override
  createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  /*List<String> currentDevices = [
    'Xiaomi Mi 11 Xiaomi Mi 11 Xiaomi Mi 11 Xiaomi Mi 11',
    'iPhone 13',
    'Acer m54',
    'Pixel 6'
  ];*/
  List<String> currentDevices = List.filled(3, "Nokia 100400", growable: true);

  // сюда втыкать бек поиск устройств будем
  List<String> availableDevices = ['Poco3', 'Smartfon vivo', 'Ipod2', 'Macbok'];

  @override
  Widget build(BuildContext context) {
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
            padding: EdgeInsets.all(14),
            itemCount: currentDevices.length,
            itemBuilder: (context, index) {
              final deviceName = currentDevices[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: MyDeviceFolder(deviceName),
              );
            }),

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
        )
    );
  }
}
