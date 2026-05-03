import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled3333333/services/dualModeService.dart';

// Виджет: файл с текущего устройства, который пользователь расшарил другому устройству

class MySentFile extends StatefulWidget {
  final SharedFile file;

  const MySentFile({super.key, required this.file});

  @override
  createState() => MySentFileState();
}

class MySentFileState extends State<MySentFile> {
  @override
  Widget build(BuildContext context) {
    // Панель с информацией о файле
    return Center(child: Container(
      width: 380,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),

      ),
      // Содержание
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
                    _formatSize(widget.file.size),
                    style: Theme.of(context).textTheme.bodySmall,),
                ]
                ),
              ],
            ),
          ),

          // Иконка-кнопка удаления файла из общих/расшаренных
          const SizedBox(width: 16),
          IconButton(
              onPressed: () {
                final service = Provider.of<DualModeService>(context, listen: false);
                // Тут уведомляются устройства, которым мы расшарили этот файл,
                // и у них перерисовывается список файлов
                service.removeSharedFile(widget.file.name);
              },
              icon: const Icon(Icons.close, color: Colors.grey)
          ),
        ],
      ),
    ));
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
