import 'package:flutter/material.dart';
import '../widgets/MyFile.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/dualModeService.dart';
import '../widgets/MySentFile.dart';

// Экран с файлами, которыми обменивается текущее устройство с выбранным пиром

class MyFilesPage extends StatefulWidget {
  final PeerDevice peer;
  const MyFilesPage(this.peer, {super.key});

  @override
  createState() => MyFilesPageState();
}

class MyFilesPageState extends State<MyFilesPage> {
  List<PeerFile> _receivedFiles = [];
  bool _isLoading = true;
  late int _lastUpdateCounter;

  @override
  void initState() {
    super.initState();
    _lastUpdateCounter = context.read<DualModeService>().updateCounter;
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    final files = await context.read<DualModeService>().fetchPeerFiles(widget.peer);
    if (mounted) {
      setState(() {
        _receivedFiles = files;
        _isLoading = false;
      });
    }
  }

  void _removeLocalFile(String fileName) {
    setState(() {
      _receivedFiles.removeWhere((f) => f.name == fileName);
    });
  }


  @override
  Widget build(BuildContext context) {
    // Следим за updateCounter сервиса
    final currentCounter = context.select<DualModeService, int>(
          (service) => service.updateCounter,
    );

    if (currentCounter != _lastUpdateCounter) {
      _lastUpdateCounter = currentCounter;
      _loadFiles();
    }

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 56,
        leading: Row(children: [const SizedBox(width: 5),
          // Выход в главное меню
          IconButton(
            padding: const EdgeInsets.only(left: 10),
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
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

      // Две вкладки с файлами, относящимися к данному устройству
      body: DefaultTabController(
          length: 2,
          child: Column(children: [
            // Полоска с вкладками
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.download), text: 'Полученные'),
                Tab(icon: Icon(Icons.upload), text: 'Отправленные'),
              ],
            ),
        // Сами вкладки в той же очереди, что они объявлены в TabBar tabs:
            Expanded(child: TabBarView(
                children: [
                  //Вкладка с полученными файлами
                  _buildReceivedTab(),
                  // Вкладка с отправленными файлами
                  _buildSentTab(),
                ]
              )
            )
          ])
        ),

      // Кнопка выбора файлов
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
        child: const Icon(Icons.add),
      ),
    );
  }

  //Вкладка с полученными файлами
  Widget _buildReceivedTab() {
    // Вкладка с отправлеными файлами
        // Пока ждём получения списка файлов - индикатор загрузки
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        // Нет файлов - на экране отображается об этом сообщение
        if (_receivedFiles.isEmpty) {
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
        // Список файлов, доступных к скачиванию
        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: _receivedFiles.length,
          itemBuilder: (context, index) {
            final file = _receivedFiles[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MyFile(
                key: ValueKey(file.name),
                file: file,
                peer: widget.peer,
                onDownloaded: () {
                  _removeLocalFile(file.name);
            },
              ),
            );
          },
        );
  }


  //Вкладка с отправленными файлами
  Widget _buildSentTab() {
    return Consumer<DualModeService>(
      builder: (context, service, _) {
        if (service.mySharedFiles.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Вы ещё не отправляли файлы'),
                Text('на это устройство'),
              ],

            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: service.mySharedFiles.length,
          itemBuilder: (context, index) {
            final file = service.mySharedFiles[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MySentFile(file: file),
            );
          },
        );
      },
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