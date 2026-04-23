import 'package:flutter/material.dart';
import 'package:untitled3333333/widgets/MyFile.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/dualModeService.dart';

class MyFilesPage extends StatefulWidget {
  final PeerDevice peer;
  const MyFilesPage(this.peer, {super.key});

  @override
  createState() => MyFilesPageState();
}

class MyFilesPageState extends State<MyFilesPage> {
  @override
  Widget build(BuildContext context) {
    final service = Provider.of<DualModeService>(context);

    return Scaffold(
        appBar: AppBar(
          leadingWidth: 56*2,
          leading: Row(children: [const SizedBox(width: 5),
            IconButton(
              padding: const EdgeInsets.only(left: 10),
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 5),
            //here been sortdialog
            ],
          ),
            title: Text(widget.peer.name),
            titleTextStyle: Theme.of(context).textTheme.displayLarge,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: Container(
                color: Theme.of(context).colorScheme.primary,
                height: 2,
              ),)
        ),

        body: FutureBuilder<List<PeerFile>>(
          future: service.fetchPeerFiles(widget.peer),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Ошибка: ${snapshot.error}'));
            }

            final files = snapshot.data ?? [];
            if (files.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Нет доступных файлов'),
                    Text('Нажмите + чтобы добавить свои файлы',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MyFile(
                    file: file,
                    peer: widget.peer,
                  ),
                );
              },
            );
          },
        ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await FilePicker.pickFiles(allowMultiple: true);
          if (result != null) {
            final service = Provider.of<DualModeService>(context, listen: false);
            // Этот метод внутри себя отправляет уведомления всем пирам
            service.addSharedFiles(result.paths.whereType<String>().toList());

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Файлы добавлены и синхронизированы (${result.files.length} шт.)')),
              );
            }
          }
        },
        tooltip: 'Добавить файлы в общий доступ',
        child: const Icon(Icons.add), // Меняем иконку на плюс для единообразия
      ),
    );
  }
}


/*IconButton(
              icon: Icon(Icons.sync_alt),
              onPressed: () async {
                final SortType? sortType = await showDialog<SortType>(
                  context: context,
                  builder: (context) => FileSortDialog(),
                );
                if (sortType != null) {
                  setState(() {

                  });
                }
              },
            ),*/