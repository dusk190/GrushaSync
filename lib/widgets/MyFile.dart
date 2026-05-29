import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/dualModeService.dart';

// Виджет: полученный от пира файл, который можно скачать

class MyFile extends StatefulWidget {
  final PeerFile file;
  final PeerDevice peer;
  final VoidCallback? onDownloaded;   // новый колбэк

  const MyFile({
    Key? key,
    required this.file,
    required this.peer,
    this.onDownloaded,
  }) : super(key: key);

  @override
  createState() => MyFileState();
}

class MyFileState extends State<MyFile> {
  // Функция загрузки данного файла с устройства-пира в папку GrushaSync в дефолтной директории загрузок
  Future<void> _downloadFile() async {
    final service = Provider.of<DualModeService>(context, listen: false);
    final fileName = widget.file.name;
    try {
      await service.downloadFile(
          widget.peer,
          widget.file,
              (progress) {
            service.getProgressNotifier(fileName).value = progress;
          }
      );
      widget.onDownloaded?.call();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    // hi
    final service = Provider.of<DualModeService>(context);
    final isDownloading = service.isFileDownloading(widget.file.name);
    final progressNotifier = service.getProgressNotifier(widget.file.name);
    return Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: Platform.isWindows ? 16 : 0),
        child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 70),
        maximumSize: const Size(double.infinity, 70),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2
            )
        ),
        elevation: 0,
      ),
      // Логика, вызывается при нажатии на всю табличку файла
      onPressed: isDownloading ? null : _downloadFile,
      // Содержание кнопки
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Название файла без расширения
                Text(
                  widget.file.name.substring(0, widget.file.name.lastIndexOf('.')),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                // Доп информация под названием файла
                Row(children: [
                  // Расширение файла
                  Text(
                    widget.file.name.substring(widget.file.name.lastIndexOf('.')),
                    style: Theme.of(context).textTheme.bodySmall,),
                  SizedBox(width: 15, height: 10,),
                  // Размер файла
                  Text(
                    widget.file.sizeFormatted, // Используем готовое форматирование размера файла
                    style: Theme.of(context).textTheme.bodySmall,),
                  ]
                ),
                if (isDownloading)
                  ValueListenableBuilder<double>(
                    valueListenable: progressNotifier,
                    builder: (context, progressValue, child) {
                      return LinearProgressIndicator(
                        value: progressValue,
                        color: Colors.green,
                      );
                    },
                  ),
              ],
            ),
          ),

          // Иконка загрузки в правой части виджета, которая меняется на индикатор на время скачивания
          const SizedBox(width: 16),
          if (isDownloading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.download, color: Colors.grey),
        ],
      ),
    ));
  }
}
