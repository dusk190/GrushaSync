import 'package:flutter/material.dart';
import '../services/client.dart';

class ClientScreen extends StatefulWidget {
  @override
  _ClientScreenState createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  final TcpClient _client = TcpClient();
  final List<String> _logs = [];
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '8080');
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _client.addMessageListener(_addLog);
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $message');
      if (_logs.length > 100) _logs.removeLast();
    });
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text);

    if (ip.isEmpty) {
      _addLog('❌ Введите IP адрес');
      return;
    }
    if (port == null) {
      _addLog('❌ Неверный порт');
      return;
    }

    setState(() => _isLoading = true);
    await _client.connect(ip, port);
    setState(() => _isLoading = false);
  }

  Future<void> _disconnect() async {
    setState(() => _isLoading = true);
    await _client.disconnect();
    setState(() => _isLoading = false);
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _client.sendMessage(message);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Клиент'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // IP и порт
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      labelText: 'IP сервера',
                      hintText: '192.168.1.100',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_client.isConnected,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _portController,
                    decoration: InputDecoration(
                      labelText: 'Порт',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !_client.isConnected,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Кнопки подключения
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _client.isConnected || _isLoading ? null : _connect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Подключиться'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: !_client.isConnected || _isLoading ? null : _disconnect,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Отключиться'),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Статус
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _client.isConnected ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _client.isConnected ? Icons.link : Icons.link_off,
                    color: _client.isConnected ? Colors.green : Colors.grey,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _client.isConnected ? 'Подключено' : 'Не подключено',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Поле ввода сообщения
            if (_client.isConnected) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        labelText: 'Сообщение',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.send),
                          onPressed: _sendMessage,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],

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