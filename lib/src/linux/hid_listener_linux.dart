import 'dart:ffi' as ffi;
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:hid_listener/src/hid_listener.dart';
import 'package:hid_listener/src/shared/hid_listener_shared.dart' as shared;

import 'hid_listener_bindings_linux.dart' as bindings;

class LinuxHidListenerBackend extends HidListenerBackend {
  LinuxHidListenerBackend(ffi.DynamicLibrary library)
      : _bindings = bindings.HidListenerBindingsLinux(library) {
    _bindings.InitializeDartAPI(ffi.NativeApi.initializeApiDLData);
  }

  @override
  bool initialize() {
    return _bindings.InitializeListeners();
  }

  @override
  bool registerKeyboard() {
    final requests = ReceivePort()..listen(_keyboardProc);
    final int nativePort = requests.sendPort.nativePort;

    return _bindings.SetKeyboardListener(nativePort);
  }

  @override
  bool registerMouse() {
    final requests = ReceivePort()..listen(_mouseProc);
    final int nativePort = requests.sendPort.nativePort;

    return _bindings.SetMouseListener(nativePort);
  }

  void _keyboardProc(dynamic e) {
    final eventAddr = ffi.Pointer<bindings.LinuxKeyboardEvent>.fromAddress(e);

    final pressed =
        eventAddr.ref.eventType == bindings.LinuxKeyboardEventType.LKE_KeyDown
            ? 0xffffffff
            : 0x0;

    final keyHelper = GtkKeyHelper();
    final firstEventData = RawKeyEventDataLinux(
        keyHelper: keyHelper,
        unicodeScalarValues: eventAddr.ref.unicodeScalarValues,
        scanCode: eventAddr.ref.scanCode,
        keyCode: eventAddr.ref.keyCode,
        isDown: pressed == 0xffffffff,
        modifiers: 0);

    if (firstEventData.logicalKey == LogicalKeyboardKey.capsLock) {
      _capslockEnabled = ~_capslockEnabled;
    }

    if (firstEventData.logicalKey == LogicalKeyboardKey.altLeft ||
        firstEventData.logicalKey == LogicalKeyboardKey.altRight) {
      _altPressed = pressed;
    }

    if (firstEventData.logicalKey == LogicalKeyboardKey.controlLeft ||
        firstEventData.logicalKey == LogicalKeyboardKey.controlRight) {
      _controlPressed = pressed;
    }

    if (firstEventData.logicalKey == LogicalKeyboardKey.metaLeft ||
        firstEventData.logicalKey == LogicalKeyboardKey.metaRight) {
      _metaPressed = pressed;
    }

    if (firstEventData.logicalKey == LogicalKeyboardKey.shiftLeft ||
        firstEventData.logicalKey == LogicalKeyboardKey.shiftRight) {
      _shiftPressed = pressed;
    }

    final modifiers = (GtkKeyHelper.modifierCapsLock & _capslockEnabled) |
        (GtkKeyHelper.modifierMod1 & _altPressed) |
        (GtkKeyHelper.modifierControl & _controlPressed) |
        (GtkKeyHelper.modifierMeta & _metaPressed) |
        (GtkKeyHelper.modifierShift & _shiftPressed);

    final eventData = RawKeyEventDataLinux(
        keyHelper: keyHelper,
        unicodeScalarValues: eventAddr.ref.unicodeScalarValues,
        scanCode: eventAddr.ref.scanCode,
        keyCode: eventAddr.ref.keyCode,
        isDown: pressed == 0xffffffff,
        modifiers: modifiers);

    final RawKeyEvent event;

    if (pressed == 0xffffffff) {
      event = RawKeyDownEvent(data: eventData);
    } else {
      event = RawKeyUpEvent(data: eventData);
    }

    for (final listener in keyboardListeners.values) {
      listener(event);
    }
  }

  void _mouseProc(dynamic e) {
    final event = shared.mouseProc(e);
    if (event == null) return;

    for (final listener in mouseListeners.values) {
      listener(event);
    }
  }

  final bindings.HidListenerBindingsLinux _bindings;

  int _capslockEnabled = 0;
  int _altPressed = 0;
  int _controlPressed = 0;
  int _metaPressed = 0;
  int _shiftPressed = 0;
}
