import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

class FileTransferService {
  ServerSocket? _server;
  Socket? _client;
  RawDatagramSocket? _udpSocket;

  /// Desktop: Start file server and announce via UDP broadcast
  Future<void> startServer(int port, Function(File, String) onReceive,
      {int broadcastPort = 4568}) async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    print('Server listening on port $port');

    // Start broadcasting presence every 2 seconds
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    Timer.periodic(const Duration(seconds: 2), (timer) {
      final message = 'FILE_SERVER:$port';
      _udpSocket!.send(
        message.codeUnits,
        InternetAddress('255.255.255.255'),
        broadcastPort,
      );
    });

    _server!.listen((client) async {
      print('Client connected: ${client.remoteAddress.address}');
      final file = File(
          'received_${DateTime.now().millisecondsSinceEpoch}');
      final sink = file.openWrite();
      await client.cast<Uint8List>().pipe(sink as StreamConsumer<Uint8List>);
      await sink.close();
      onReceive(file, client.remoteAddress.address);
      client.destroy();
    });
  }

  /// Mobile: Discover servers on LAN
  Future<void> discoverServers(
      {int broadcastPort = 4568,
        Function(String ip, int port)? onServerFound}) async {
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _udpSocket!.broadcastEnabled = true;

    _udpSocket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = _udpSocket!.receive();
        if (dg != null) {
          final message = String.fromCharCodes(dg.data);
          if (message.startsWith('FILE_SERVER:')) {
            final portStr = message.split(':')[1];
            final ip = dg.address.address;
            final port = int.tryParse(portStr) ?? 4567;
            if (onServerFound != null) onServerFound(ip, port);
          }
        }
      }
    });
  }

  Future<void> sendFile(
      String filePath, String serverIp, int port, Function(double)? onProgress) async {
    final file = File(filePath);
    final length = await file.length();

    _client = await Socket.connect(serverIp, port);
    int sentBytes = 0;

    await for (final chunk in file.openRead()) {
      _client!.add(chunk);
      sentBytes += chunk.length;
      if (onProgress != null) {
        onProgress(sentBytes / length);
      }
    }

    await _client!.flush();
    await _client!.close();
  }

  void dispose() {
    _server?.close();
    _udpSocket?.close();
  }
}
