import 'package:flutter/material.dart';
import '../services/checkLocalIp.dart';
import '../services/echoServer.dart';

class ServerScreen extends StatefulWidget {
  @override
  _ServerScreenState createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  final TcpServer _server = TcpServer();
  final List<String> _logs = [];
  final TextEditingController _portController = TextEditingController(text: '8080');
  String? _localIp;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLocalIp();
    _server.addMessageListener(_addLog);
  }

  Future<void> _loadLocalIp() async {
    final ip = await IpService.getLocalIp();
    setState(() {
      _localIp = ip;
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $message');
      if (_logs.length > 100) _logs.removeLast();
    });
  }

  Future<void> _startServer() async {
    final port = int.tryParse(_portController.text);
    if (port == null) {
      _addLog('❌ Неверный порт');
      return;
    }

    setState(() => _isLoading = true);
    final success = await _server.start(port);
    setState(() => _isLoading = false);

    if (success && _localIp != null) {
      _addLog('📡 IP адрес сервера: $_localIp:$port');
      _addLog('💡 Передайте этот IP клиенту');
    }
  }

  Future<void> _stopServer() async {
    setState(() => _isLoading = true);
    await _server.stop();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Сервер'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Информация об IP
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.wifi, color: _localIp != null ? Colors.green : Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Локальный IP:', style: TextStyle(fontSize: 12)),
                          Text(
                            _localIp ?? 'Не определён',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Порт
            TextField(
              controller: _portController,
              decoration: InputDecoration(
                labelText: 'Порт',
                border: OutlineInputBorder(),
                suffixText: 'обычно 8080',
              ),
              keyboardType: TextInputType.number,
              enabled: !_server.isRunning,
            ),

            SizedBox(height: 16),

            // Кнопки
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _server.isRunning || _isLoading ? null : _startServer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Запустить сервер'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: !_server.isRunning || _isLoading ? null : _stopServer,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Остановить'),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Статус
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _server.isRunning ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _server.isRunning ? Icons.check_circle : Icons.circle_outlined,
                    color: _server.isRunning ? Colors.green : Colors.grey,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _server.isRunning ? 'Сервер запущен' : 'Сервер остановлен',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Логи
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Лог событий:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        reverse: true,
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              _logs[index],
                              style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}