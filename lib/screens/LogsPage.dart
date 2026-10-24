import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/log_service.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        // Если пользователь отмотал вверх больше чем на 100px — выключаем автоскролл
        if (maxScroll - currentScroll > 100) {
          if (_autoScroll) setState(() => _autoScroll = false);
        } else {
          if (!_autoScroll) setState(() => _autoScroll = true);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return const Color(0xFFFF5252);
      case LogLevel.warn:
        return const Color(0xFFFFB74D);
      case LogLevel.debug:
        return const Color(0xFFB0BEC5);
      case LogLevel.info:
        return const Color(0xFF69F0AE);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF212121);
    const consoleBg = Color(0xFF181818);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B2B2B),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Вернуться обратно',
        ),
        title: const Text(
          'Логи разработчика',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
            tooltip: 'Скопировать все логи',
            onPressed: () {
              final text = LogService.instance.getAllLogsAsText();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Логи пусты')),
                );
                return;
              }
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Все логи скопированы в буфер обмена')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 22),
            tooltip: 'Очистить логи',
            onPressed: () {
              LogService.instance.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Логи очищены')),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: consoleBg,
        child: ValueListenableBuilder<List<LogEntry>>(
          valueListenable: LogService.instance.logsNotifier,
          builder: (context, logs, _) {
            if (logs.isEmpty) {
              return const Center(
                child: Text(
                  'Событий пока не зафиксировано...\nЛоги будут отображаться здесь в реальном времени.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              );
            }

            _scrollToBottom();

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final entry = logs[index];
                final levelColor = _getLevelColor(entry.level);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: SelectableText.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                      children: [
                        TextSpan(
                          text: '[${entry.timeFormatted}] ',
                          style: const TextStyle(color: Color(0xFF757575)),
                        ),
                        TextSpan(
                          text: '[${entry.levelLabel}] ',
                          style: TextStyle(
                            color: levelColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: '[${entry.tag}] ',
                          style: const TextStyle(
                            color: Color(0xFF80DEEA),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: entry.message,
                          style: const TextStyle(color: Color(0xFFE0E0E0)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
