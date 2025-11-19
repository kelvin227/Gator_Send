import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gator_send/src/desktop/desktop_home.dart';
import 'package:gator_send/src/mobile/mobile_home.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'File Transfer App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: isDesktop ? const DesktopScreen() : const MobileScreen(),
    );
  }
}
