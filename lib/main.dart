import 'package:app_nfc_tool/presentation/screen/nfc_tool.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NFC Tool',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: NFCTool(),
    );
  }
}
