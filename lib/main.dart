import 'dart:io';
import 'package:flutter/material.dart';
import 'src/desktop/desktop_home.dart';
import 'src/mobile/mobile_home.dart';

void main() {
  runApp(const AudioShareApp());
}

class AudioShareApp extends StatelessWidget {
  const AudioShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AudioShare',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Platform.isWindows || Platform.isLinux || Platform.isMacOS
          ? const DesktopHome()
          : const MobileHome(),
    );
  }
}
