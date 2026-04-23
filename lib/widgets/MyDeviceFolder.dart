import 'package:flutter/material.dart';
import 'package:untitled3333333/screens/MyFilesPage.dart';
import 'package:untitled3333333/services/dualModeService.dart';

class MyDeviceFolder extends StatefulWidget {
  final PeerDevice peer;

  const MyDeviceFolder(this.peer, {super.key});

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
      onPressed: () => enterFolder(widget.peer),
      child:
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.peer.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  '${widget.peer.host}:${widget.peer.port}',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
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
    )
    );
  }

  void enterFolder(PeerDevice peer) {
    Navigator.push(context, PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => MyFilesPage(peer),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
/*
  void availToFalse () {
    setState(() {
      deviceConnected = false;
    });
  }

  void availToTrue () {
    setState(() {
      deviceAvailable = true;
    });
  } */
}
