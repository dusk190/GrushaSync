import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/dualModeService.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final service = Provider.of<DualModeService>(context, listen: false);
    await service.initialize();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(allowMultiple: true);
    if (result != null) {
      final service = Provider.of<DualModeService>(context, listen: false);
      service.addSharedFiles(result.paths.whereType<String>().toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<DualModeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GrushaSync'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Индикатор статуса
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  service.isServerRunning ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  service.peers.length.toString(),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.folder), text: 'Мои файлы'),
                Tab(icon: Icon(Icons.devices), text: 'Устройства'),
                Tab(icon: Icon(Icons.download), text: 'Загрузки'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Вкладка "Мои файлы"
                  _buildMyFilesTab(service),

                  // Вкладка "Устройства"
                  _buildDevicesTab(service),

                  // Вкладка "Загрузки"
                  _buildDownloadsTab(service),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickFiles,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMyFilesTab(DualModeService service) {
    if (service.mySharedFiles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Нет общих файлов'),
            Text('Нажмите + чтобы добавить', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: service.mySharedFiles.length,
      itemBuilder: (context, index) {
        final file = service.mySharedFiles[index];
        return ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text(file.name),
          subtitle: Text(_formatSize(file.size)),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => service.removeSharedFile(file.name),
          ),
        );
      },
    );
  }

  Widget _buildDevicesTab(DualModeService service) {
    if (service.peers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Устройства не найдены'),
            Text('Убедитесь, что другие устройства запущены', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: service.peers.length,
      itemBuilder: (context, index) {
        final peer = service.peers[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ExpansionTile(
            leading: const Icon(Icons.devices, color: Colors.blue),
            title: Text(peer.name),
            subtitle: Text('${peer.host}:${peer.port}'),
            children: [
              FutureBuilder(
                future: service.fetchPeerFiles(peer),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final files = snapshot.data ?? [];
                  if (files.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Нет доступных файлов'),
                    );
                  }

                  return Column(
                    children: files.map((file) {
                      return ListTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(file.name),
                        subtitle: Text(file.sizeFormatted),
                        trailing: ElevatedButton(
                          onPressed: () => _downloadFile(service, peer, file),
                          child: const Text('Скачать'),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDownloadsTab(DualModeService service) {
    // Здесь будет история скачиваний
    return const Center(
      child: Text('История загрузок появится здесь'),
    );
  }

  Future<void> _downloadFile(DualModeService service, PeerDevice peer, PeerFile file) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Скачивание'),
        content: StatefulBuilder(
          builder: (ctx, setState) {
            double progress = 0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 8),
                Text('${(progress * 100).toInt()}%'),
              ],
            );
          },
        ),
      ),
    );

    await service.downloadFile(peer, file, (progress) {
      // Обновляем прогресс в диалоге
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл "${file.name}" скачан')),
      );
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}