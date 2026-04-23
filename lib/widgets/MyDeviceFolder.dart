import 'package:flutter/material.dart';
import 'package:untitled3333333/screens/MyFilesPage.dart';

class MyDeviceFolder extends StatefulWidget {
  final String _deviceName;

  const MyDeviceFolder(this._deviceName, {super.key});

  @override
  createState() => MyDeviceFolderState();
}

class MyDeviceFolderState extends State<MyDeviceFolder> {
  bool deviceConnected = true;

  @override
  Widget build(BuildContext context) {
    // hi
    return Center(child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(380, 70),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2
            )
        ),
        elevation: 0,
      ),
      onPressed: () {enterFolder(widget._deviceName);},
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget._deviceName,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 16),
          // кружочек
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: deviceConnected ? const Color(0xff3bff28) : const Color(0xffd33535),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    ));
  }

  void enterFolder(String devicename) {
    Navigator.push(context, PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => MyFilesPage(devicename),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void availToFalse () {
    setState(() {
      deviceConnected = false;
    });
  }
  /*
  void availToTrue () {
    setState(() {
      deviceAvailable = true;
    });
  } */
}
