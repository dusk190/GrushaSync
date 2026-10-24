class PeerFile {
  final String id;
  final String name;
  final int size;
  final String sizeFormatted;
  final String peerId;
  final String peerName;

  PeerFile({
    required this.id,
    required this.name,
    required this.size,
    required this.sizeFormatted,
    required this.peerId,
    required this.peerName,
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
