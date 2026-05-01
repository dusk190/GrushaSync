import 'package:flutter/material.dart';

// Диалог выбора режима сортировки файлов
// Пока не используется, доработка отсутствует в ближайших планах

class FileSortDialog extends StatefulWidget {
  const FileSortDialog({super.key});

  @override
  State<FileSortDialog> createState() => _FileSortDialogState();
}

enum SortType { byDate, byName, byExt }

class _FileSortDialogState extends State<FileSortDialog> {
  SortType? _type = SortType.byDate;

  @override
  Widget build(BuildContext dcontext) {
    return AlertDialog(
      title: const Text('Сортировка:', textAlign: TextAlign.center),
      content: RadioGroup<SortType>(
        groupValue: _type,
        onChanged: (SortType? value) {
          setState(() => _type = value);
          Navigator.pop(dcontext, value);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            RadioListTile<SortType>(
              title: const Text('По дате добавления'),
              value: SortType.byDate,
            ),
            RadioListTile<SortType>(
              title: const Text('По имени'),
              value: SortType.byName,
            ),
            RadioListTile<SortType>(
              title: const Text('По типу файла'),
              value: SortType.byExt,
            ),
          ],
        ),
      ),
    );
  }
}

