import 'package:flutter/foundation.dart';

enum LogLevel { info, warn, error, debug }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
  });

  String get timeFormatted {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get levelLabel {
    switch (level) {
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.warn:
        return 'WARN';
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
    }
  }

  @override
  String toString() => '[$timeFormatted] [$levelLabel] [$tag] $message';
}

class LogService {
  LogService._();
  static final LogService instance = LogService._();

  static const int maxLogs = 1000;
  final ValueNotifier<List<LogEntry>> logsNotifier = ValueNotifier<List<LogEntry>>([]);

  List<LogEntry> get logs => logsNotifier.value;

  void log(LogLevel level, String tag, String message) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
    );

    if (kDebugMode) {
      debugPrint(entry.toString());
    }

    final current = List<LogEntry>.from(logsNotifier.value);
    if (current.length >= maxLogs) {
      current.removeAt(0);
    }
    current.add(entry);
    logsNotifier.value = current;
  }

  static void info(String tag, String message) =>
      instance.log(LogLevel.info, tag, message);

  static void warn(String tag, String message) =>
      instance.log(LogLevel.warn, tag, message);

  static void error(String tag, String message, [dynamic error]) {
    final fullMsg = error != null ? '$message: $error' : message;
    instance.log(LogLevel.error, tag, fullMsg);
  }

  static void debug(String tag, String message) =>
      instance.log(LogLevel.debug, tag, message);

  void clear() {
    logsNotifier.value = [];
  }

  String getAllLogsAsText() {
    return logsNotifier.value.map((e) => e.toString()).join('\n');
  }
}
