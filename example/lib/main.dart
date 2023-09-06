import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hid_listener/hid_listener.dart';

void listener(RawKeyEvent event) {
  print(
      "${event is RawKeyDownEvent} ${event.logicalKey.debugName} ${event.isShiftPressed} ${event.isAltPressed} ${event.isControlPressed}");
}

void mouseListener(MouseEvent event) {
  print("${event}");
}

var registerResult = "";

void main() {
  if (!getListenerBackend()!.initialize()) {
    print("Failed to initialize listener backend");
  }

  getListenerBackend()!.addKeyboardListener(listener);
  getListenerBackend()!.addMouseListener(mouseListener);

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
