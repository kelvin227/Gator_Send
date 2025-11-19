import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../common/file_transfer_service.dart';

class MobileHome extends StatefulWidget {
  const MobileHome({super.key});

  @override
  State<MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends State<MobileHome> {
  final FileTransferService _fts = FileTransferService();
  String _serverIp = "";
  String _status = "No server selected";

  Future<void> _pickAndSend() async {
    final res = await FilePicker.platform.pickFiles();
    if (res == null) return;
    final path = res.files.single.path;
    if (path == null) return;

    if (_serverIp.isEmpty) {
      setState(() => _status = "Set server IP first");
      return;
    }

    setState(() => _status = "Sending...");
    await _fts.sendFile(path, _serverIp, 5000);
    setState(() => _status = "File sent!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mobile File Share")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: "Server IP",
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => _serverIp = val,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _pickAndSend,
              child: const Text("Pick File & Send"),
            ),
            const SizedBox(height: 12),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
