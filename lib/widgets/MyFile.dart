import 'package:flutter/material.dart';

class MyFile extends StatefulWidget {
  final String _fileName;
  final String _fileExtension;

  const MyFile(this._fileName, this._fileExtension, {super.key});

  @override
  createState() => MyFileState();
}

class MyFileState extends State<MyFile> {

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
      onPressed: openFile, //потом поменять на открытие файла
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget._fileName,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 16),
          // кружочек
          Text(
            widget._fileExtension,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.right,
          ),
        ],
      ),
    ));
  }

  void openFile () {

  }
}
