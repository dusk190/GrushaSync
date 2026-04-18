import 'package:flutter/material.dart';

class LeaveFilesDialog extends StatefulWidget {
  const LeaveFilesDialog({super.key});

  @override
  State<LeaveFilesDialog> createState() => _LeaveFilesDialogState();
}

class _LeaveFilesDialogState extends State<LeaveFilesDialog> {

  @override
  Widget build(BuildContext dcontext) {
    return AlertDialog(
      constraints: BoxConstraints(maxWidth: 340, maxHeight: 300),
      title: Text('Сбросить выбор файлов и выйти в меню?',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2),
      content: Row(mainAxisAlignment: MainAxisAlignment.center,
        spacing: 100,
        children: [
          TextButton(onPressed: () {
            Navigator.pop(dcontext, true);
          }, child: Text('Да',
              style: Theme.of(context).textTheme.bodyMedium),

          ),
          TextButton(onPressed: () {
            Navigator.pop(dcontext, false);
          }, child: Text('Нет',
              style: Theme.of(context).textTheme.bodyMedium)
          )
        ],)
    );
  }
}

