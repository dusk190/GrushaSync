import 'package:flutter/material.dart';
import 'package:untitled3333333/widgets/MyDeviceFolder.dart';

class MyHomePage extends StatefulWidget {
  final VoidCallback changeTheme;
  const MyHomePage({super.key, required this.changeTheme});

  @override
  createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  List<String> devices = ['Xiaomi Mi 11 Xiaomi Mi 11 Xiaomi Mi 11 Xiaomi Mi 11', 'iPhone 13', 'Samsung S21', 'Pixel 6'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            actions: [
              IconButton(
                icon: Icon(Theme.of(context).brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode),
                onPressed: widget.changeTheme, // Кнопка под рукой
              )],
            titleTextStyle: Theme.of(context).textTheme.displayLarge,
            backgroundColor: Theme.of(context).colorScheme.primary,
            title: Text("mcDonol")),

        body: ListView.builder(
          padding: EdgeInsets.all(14),
            itemCount: devices.length,
            itemBuilder: (context, index) {
            final deviceName = devices[index];
            return Padding(
                padding: EdgeInsets.only(bottom: 12),
              child: MyDeviceFolder(deviceName),
            );
        }),
    );
  }
}

