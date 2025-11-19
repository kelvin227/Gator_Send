import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gator_send/src/common/file_transfer_service.dart';

class DesktopScreen extends StatefulWidget {
  const DesktopScreen({super.key});

  @override
  State<DesktopScreen> createState() => _DesktopScreenState();
}

class _DesktopScreenState extends State<DesktopScreen> {
  final FileTransferService _service = FileTransferService();
  final List<String> _receivedFiles = [];
  String _status = "Initializing...";
  String _lanIp = "Unknown";

  @override
  void initState() {
    super.initState();
    _initServer();
  }

  Future<void> _initServer() async {
    // Get desktop LAN IP
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      if (interfaces.isNotEmpty) {
        final iface = interfaces.firstWhere(
              (i) => !i.name.toLowerCase().contains('loopback'),
          orElse: () => interfaces.first,
        );
        _lanIp = iface.addresses.first.address;
      }
    } catch (e) {
      _lanIp = "Error: $e";
    }

    // Start file server
    await _service.startServer(4567, (file, ip) {
      setState(() {
        _receivedFiles.add('${file.path} from $ip');
        _status = 'Received file from $ip';
      });
    });

    setState(() {
      _status = "Server running on $_lanIp:4567 (broadcasting)";
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
      appBar: AppBar(title: const Text('Desktop File Receiver')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("LAN IP: $_lanIp", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Status: $_status", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text("Received Files:", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _receivedFiles.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_receivedFiles[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
