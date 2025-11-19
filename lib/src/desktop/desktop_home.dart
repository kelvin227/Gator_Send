import 'dart:io';
import 'package:flutter/material.dart';
import '../common/file_transfer_service.dart';
import '../common/mdns_service.dart';

class DesktopHome extends StatefulWidget {
  const DesktopHome({super.key});

  @override
  State<DesktopHome> createState() => _DesktopHomeState();
}

class _DesktopHomeState extends State<DesktopHome> {
  final FileTransferService _fts = FileTransferService();
  final MDnsService _mdns = MDnsService();
  final List<String> _receivedFiles = [];

  @override
  void initState() {
    super.initState();
    _fts.startServer(5000, (file, ip) {
      setState(() {
        _receivedFiles.add("${file.path} from $ip");
      });
    });
  }

  @override
  void dispose() {
    _fts.disposeServer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Desktop File Share")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text("Listening on port 5000"),
            const SizedBox(height: 12),
            const Text("Received files:"),
            Expanded(
              child: ListView.builder(
                itemCount: _receivedFiles.length,
                itemBuilder: (context, index) {
                  return ListTile(title: Text(_receivedFiles[index]));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
