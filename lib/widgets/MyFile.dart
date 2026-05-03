import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled3333333/services/dualModeService.dart';

// Виджет: полученный от пира файл, который можно скачать

class MyFile extends StatefulWidget {
  final PeerFile file;
  final PeerDevice peer;

  const MyFile({super.key, required this.file, required this.peer});

  @override
  createState() => MyFileState();
}

class MyFileState extends State<MyFile> {
  bool _isDownloading = false;
  // Функция загрузки данного файла с устройства-пира в папку GrushaSync в дефолтной директории загрузок
  Future<void> _downloadFile() async {
    setState(() => _isDownloading = true);

    final service = Provider.of<DualModeService>(context, listen: false);

    bool success = false;
    try {
      await service.downloadFile(
          widget.peer,
          widget.file,
              (progress) {
            print('Прогресс: ${(progress * 100).toInt()}%');
          }
      );
      success = true;
    } catch (e) {
      success = false;
    }
    // По окончании загрузки уведомляем пользователя, если он не вышел в основное меню
    if (mounted) {
      setState(() => _isDownloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Файл "${widget.file.name}" скачан в папку Загрузки/GrushaSync'
              : 'Ошибка при скачивании "${widget.file.name}"'),
        ),
      );
    }
  }

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
      // Логика, вызывается при нажатии на всю табличку файла
      onPressed: _isDownloading ? null : _downloadFile,
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
              ],
            ),
          ),

          // Иконка загрузки в правой части виджета, которая меняется на индикатор на время скачивания
          const SizedBox(width: 16),
          if (_isDownloading)
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
