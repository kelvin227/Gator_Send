import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class FileTransferService {
  ServerSocket? _server;
  Socket? _client;

  /// ---- Start server (Desktop) ----
  /// `port`: listening port
  /// `onReceive`: callback with received File and sender IP
  Future<void> startServer(int port, Function(File, String) onReceive) async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    print('Server listening on port $port');

    _server!.listen((client) async {
      print('Client connected: ${client.remoteAddress.address}');

      final file = File(
        'received_from_mobile_${DateTime.now().millisecondsSinceEpoch}',
      );
      final sink = file.openWrite();

      // Fix: cast Socket (Stream<Uint8List>) to match IOSink
      await client.cast<Uint8List>().pipe(sink as StreamConsumer<Uint8List>);

      await sink.close();
      onReceive(file, client.remoteAddress.address);

      client.destroy();
    });
  }

  /// ---- Connect to server and send a file (Mobile) ----
  /// `filePath`: path of file to send
  /// `serverIp`: IP address of desktop/server
  /// `port`: server port
  Future<void> sendFile(String filePath, String serverIp, int port) async {
    final file = File(filePath);

    _client = await Socket.connect(serverIp, port);
    print('Connected to server: $serverIp:$port');

    await _client!.addStream(file.openRead());
    await _client!.flush();
    await _client!.close();

    print('File sent successfully.');
  }

  /// ---- Stop server ----
  void disposeServer() {
    _server?.close();
  }
}
