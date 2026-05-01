import 'package:flutter/material.dart';
import 'package:untitled3333333/screens/MyFilesPage.dart';
import 'package:untitled3333333/services/dualModeService.dart';

// Виджет: папка-устройство (пир)

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
    // Кнопка-папка
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
      // При нажатии переход в папку (на экран MyFilesPage)
      onPressed: () => enterFolder(widget.peer),
      // Содержание кнопки
      child:
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Фиктивное имя устройства-пира
                Text(
                  widget.peer.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                // Ip-адрес и порт пира
                Text(
                  '${widget.peer.host}:${widget.peer.port}',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Индикатор доступности пира, на данный момент чисто как декорация,
          // ибо отслеживать одно устроство как будто у него постоянный адрес
          // наше приложение, насколько понимаю, не умеет
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

  // Навигация: переход на экран MyFilesPage для данного устройства (пира)
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
