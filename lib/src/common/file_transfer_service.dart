import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

class FileTransferService {
  Socket? _socket;
  ServerSocket? _server;



  // ============================================================
  //                 MOBILE → SEND FILE TO DESKTOP
  // ============================================================
  Future<void> sendFile(
      String filePath,
      String serverIp,
      int port,
      Function(double progress) onProgress,
      ) async {
    final file = File(filePath);
    final fileName = p.basename(file.path);
    final fileBytes = await file.readAsBytes();
    final totalSize = fileBytes.length;

    _socket = await Socket.connect(serverIp, port);
    print("Connected to server $serverIp:$port");

    // 1️⃣ Send filename length
    final nameBytes = Uint8List.fromList(fileName.codeUnits);
    _socket!.add(_int32ToBytes(nameBytes.length));

    // 2️⃣ Send filename
    _socket!.add(nameBytes);

    // 3️⃣ Send file size
    _socket!.add(_int64ToBytes(totalSize));

    // 4️⃣ Stream file chunks
    const int chunkSize = 64 * 1024; // 64 KB
    int offset = 0;

    while (offset < totalSize) {
      final end = (offset + chunkSize < totalSize) ? offset + chunkSize : totalSize;

      final chunk = fileBytes.sublist(offset, end);

      _socket!.add(chunk);

      offset = end;
      onProgress(offset / totalSize);

      await Future.delayed(const Duration(milliseconds: 1));
    }

    await _socket!.flush();
    await _socket!.close();
    print("File sent successfully!");
  }

  // ============================================================
  //                 DESKTOP → RECEIVE FILE
  // ============================================================
  Future<void> startServer(
      int port,
      Function(File file, String senderIp) onFileReceived,
      ) async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    print("Server running on port $port...");

    _server!.listen((client) {
      print("Client connected: ${client.remoteAddress.address}");
      _handleClient(client, onFileReceived);
    });
  }

  Future<void> _handleClient(
      Socket client,
      Function(File file, String senderIp) onFileReceived,
      ) async {
    try {
      final reader = _SocketReader(client);

      // 1️⃣ Read filename length
      final nameLengthBytes = await reader.readExact(4);
      final nameLength =
      ByteData.sublistView(nameLengthBytes).getInt32(0, Endian.big);

      // 2️⃣ Read filename
      final nameBytes = await reader.readExact(nameLength);
      final fileName = String.fromCharCodes(nameBytes);

      // 3️⃣ Read file size
      final sizeBytes = await reader.readExact(8);
      final fileSize =
      ByteData.sublistView(sizeBytes).getInt64(0, Endian.big);

      print("Receiving: $fileName ($fileSize bytes)");

      // Create save folder
      final saveDir = Directory("received_files");
      if (!saveDir.existsSync()) saveDir.createSync();

      final file = File(p.join(saveDir.path, fileName));
      final sink = file.openWrite();

      // 4️⃣ Receive file data
      int received = 0;

      while (received < fileSize) {
        final remaining = fileSize - received;
        final chunkSize = remaining > 64 * 1024 ? 64 * 1024 : remaining;

        final chunk = await reader.readExact(chunkSize);
        sink.add(chunk);

        received += chunk.length;
      }

      await sink.close();
      print("File saved: ${file.path}");

      onFileReceived(file, client.remoteAddress.address);
    } catch (e) {
      print("Receive error: $e");
    } finally {
      client.close();
    }
  }

  // ============================================================
  //                       HELPERS
  // ============================================================
  Uint8List _int32ToBytes(int value) {
    final b = ByteData(4);
    b.setInt32(0, value, Endian.big);
    return b.buffer.asUint8List();
  }

  Uint8List _int64ToBytes(int value) {
    final b = ByteData(8);
    b.setInt64(0, value, Endian.big);
    return b.buffer.asUint8List();
  }

  void dispose() {
    _socket?.destroy();
    _server?.close();
  }
}

// ============================================================
//          INTERNAL CLASS TO HANDLE EXACT BYTE READS
// ============================================================
class _SocketReader {
  final Socket socket;
  final List<int> _buffer = [];

  _SocketReader(this.socket) {
    socket.listen(_buffer.addAll);
  }

  Future<Uint8List> readExact(int count) async {
    while (_buffer.length < count) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    final chunk = Uint8List.fromList(_buffer.sublist(0, count));
    _buffer.removeRange(0, count);
    return chunk;
  }
}
