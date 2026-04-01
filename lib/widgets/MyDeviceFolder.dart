import 'package:flutter/material.dart';

class MyDeviceFolder extends StatefulWidget {
  final String _deviceName;

  const MyDeviceFolder(this._deviceName, {super.key});

  @override
  createState() => MyDeviceFolderState();
}

class MyDeviceFolderState extends State<MyDeviceFolder> {

  bool deviceAvailable = true;


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
                color: Theme.of(context).colorScheme.primary, width: 1
            )
        ),
        elevation: 0,
      ),
      onPressed: availToFalse, //потом поменять на навигацию в экран со списком файлов
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget._deviceName,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.left,
              // 2. Добавляем обрезку текста, если он слишком длинный
              overflow: TextOverflow.ellipsis,
              maxLines: 1, // Чтобы текст всегда был в одну строку
            ),
          ),
          const SizedBox(width: 16),
          // кружочек
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: deviceAvailable ? const Color(0xff3bff28) : const Color(0xffd33535),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    ));
  }

  void availToFalse () {
    setState(() {
      deviceAvailable = false;
    });
  }
  /*
  void availToTrue () {
    setState(() {
      deviceAvailable = true;
    });
  } */
}
