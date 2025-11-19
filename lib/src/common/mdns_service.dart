import 'package:multicast_dns/multicast_dns.dart';
import 'dart:async';

class MDnsService {
  MDnsClient? _mdns;

  Future<void> startDiscovery(Function(String) onDeviceFound) async {
    _mdns = MDnsClient();
    await _mdns!.start();
    await for (final PtrResourceRecord ptr
    in _mdns!.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_fileshare._tcp.local'))) {
      onDeviceFound(ptr.domainName);
    }
  }

  void stopDiscovery() {
    _mdns?.stop();
  }
}
