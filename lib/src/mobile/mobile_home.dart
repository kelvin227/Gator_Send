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
  double _progress = 0.0;

  // Discovered servers: map IP -> port
  final Map<String, int> _servers = {};

  @override
  void initState() {
    super.initState();
    _service.discoverServers(onServerFound: (ip, port) {
      setState(() {
        _servers[ip] = port;
      });
    });
  }

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    setState(() {
      _filePath = result.files.single.path;
      _progress = 0.0;
    });
  }

  void _sendFile(String ip, int port) async {
    if (_filePath == null) return;

    await _service.sendFile(_filePath!, ip, port, (progress) {
      setState(() {
        _progress = progress;
      });
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
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Pick File'),
            ),
            if (_filePath != null) Text('Selected: $_filePath'),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 20),
            const Text('Discovered Servers:'),
            Expanded(
              child: ListView(
                children: _servers.entries.map((e) {
                  return ListTile(
                    title: Text('${e.key}:${e.value}'),
                    trailing: ElevatedButton(
                      onPressed: () => _sendFile(e.key, e.value),
                      child: const Text('Send'),
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
