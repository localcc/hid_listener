import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hid_listener/hid_listener.dart';

void listener(RawKeyEvent event) {
  print("${event is RawKeyDownEvent} ${event.logicalKey.keyLabel}");
}

var registerResult = "";

void main() {
  if (registerKeyboardListener(listener) == null) {
    registerResult = "Failed to register listener";
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text(registerResult),
        ),
      ),
    );
  }
}
