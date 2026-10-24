class SharedFile {
  final String id;
  final String name;
  final String path;
  final int size;

  SharedFile({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
  });

  String get nameWithoutExtension {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex <= 0) return name;
    return name.substring(0, dotIndex);
  }

  String get extension {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex <= 0) return '';
    return name.substring(dotIndex);
  }
}
