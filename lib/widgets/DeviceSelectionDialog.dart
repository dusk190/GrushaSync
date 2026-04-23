import 'package:flutter/material.dart';

class DeviceSelectionDialog extends StatelessWidget {
  final List<String> availableDevices;

  const DeviceSelectionDialog({super.key, required this.availableDevices});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить устройство', textAlign: TextAlign.center),
      content: SizedBox(
        width: double.maxFinite,
        child: availableDevices.isNotEmpty ? ListView.builder(
          shrinkWrap: true,
          itemCount: availableDevices.length,
          itemBuilder: (context, index) {
            return ListTile(
                title: Text(availableDevices[index]),
                onTap: () {
                  Navigator.pop(context, availableDevices[index]);
                }
            );
          },
        ) : Text("Устройства не найдены.", style: TextStyle(fontSize: 18),),
      ),
    );
  }
}