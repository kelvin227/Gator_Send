import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gator_send/src/common/file_transfer_service.dart';

class MobileScreen extends StatefulWidget {
  const MobileScreen({super.key});

  @override
  State<MobileScreen> createState() => _MobileScreenState();
}

class _MobileScreenState extends State<MobileScreen> {
  final FileTransferService _service = FileTransferService();
  String? _filePath;
  final Map<String, int> discoveredDevices = {};

  double _progress = 0.0;


  @override
  void initState() {
    super.initState();
    discoverServers(onServerFound: (ip, port) {
      setState(() {
        discoveredDevices[ip] = port;
      });
    },
    );
  }
  
  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    setState(() {
      _filePath = result.files.single.path;
      _progress = 0.0;
    });
  }

  Future<void> discoverServers({ required Function(String ip, int port) onServerFound,}) async {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      54545,
      reuseAddress: true,
    );

    socket.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = socket.receive();
        if (datagram == null) return;

        final message = String.fromCharCodes(datagram.data);

        if (message.startsWith("GATOR_PC")) {
          final parts = message.split(";");

          if (parts.length == 2) {
            final serverPort = int.tryParse(parts[1]);
            final serverIp = datagram.address.address;

            if (serverPort != null) {
              onServerFound(serverIp, serverPort);
            }
          }
        }
      }
    });
  }


  void _sendFile(String ip, int port) async {

    if (_filePath == null || ip.isEmpty || port == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select file and enter valid IP/Port")),
      );
      return;
    }

    await _service.sendFile(_filePath!, ip, port, (progress) {
      setState(() => _progress = progress);
    });

    setState(() {
      _filePath = null;
      _progress = 0.0;
    });
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mobile File Sender')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Pick File'),
            ),

            if (_filePath != null) Text('Selected: $_filePath'),

            const SizedBox(height: 10),
            LinearProgressIndicator(value: _progress),

            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: discoveredDevices.entries.map((entry) {
                  return ListTile(
                    title: Text("PC: ${entry.key}:${entry.value}"),
                    trailing: ElevatedButton(
                      onPressed: () => _sendFile(entry.key, entry.value),
                      child: const Text("Send"),
                    ),
                  );
                }).toList(),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
