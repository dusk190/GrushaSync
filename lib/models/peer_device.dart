class PeerDevice {
  final String id;
  final String name;
  final String host;
  final int port;
  DateTime lastSeen;

  PeerDevice({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.lastSeen,
  });
}
