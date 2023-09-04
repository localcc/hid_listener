import 'dart:ffi' as ffi;
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:hid_listener/src/hid_listener.dart';
import 'package:hid_listener/src/shared/hid_listener_shared.dart' as shared;

import 'hid_listener_bindings_windows.dart' as bindings;

class WindowsHidListenerBackend extends HidListenerBackend {
  WindowsHidListenerBackend(ffi.DynamicLibrary library)
      : _bindings = bindings.HidListenerBindingsWindows(library) {
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

  void _keyboardProc(dynamic event) {
    final eventAddr =
        ffi.Pointer<bindings.WindowsKeyboardEvent>.fromAddress(event);

    final vkCode = eventAddr.ref.vkCode;
    final pressed =
        eventAddr.ref.eventType == bindings.WindowsKeyboardEventType.WKE_KeyDown
            ? 0xffffffff
            : 0x0;

    final physicalKey = kWindowsToPhysicalKey[vkCode];

    if (physicalKey == PhysicalKeyboardKey.altLeft) _lAltPressed = pressed;
    if (physicalKey == PhysicalKeyboardKey.altRight) _rAltPressed = pressed;

    if (physicalKey == PhysicalKeyboardKey.controlLeft) {
      _lControlPressed = pressed;
    }
    if (physicalKey == PhysicalKeyboardKey.controlRight) {
      _rControlPressed = pressed;
    }

    if (physicalKey == PhysicalKeyboardKey.metaLeft) _lMetaPressed = pressed;
    if (physicalKey == PhysicalKeyboardKey.metaRight) _rMetaPressed = pressed;

    if (physicalKey == PhysicalKeyboardKey.shiftLeft) _lShiftPressed = pressed;
    if (physicalKey == PhysicalKeyboardKey.shiftRight) _rShiftPressed = pressed;

    final altModifiers =
        (RawKeyEventDataWindows.modifierAlt & (_lAltPressed | _rAltPressed)) |
            (RawKeyEventDataWindows.modifierLeftAlt & _lAltPressed) |
            (RawKeyEventDataWindows.modifierRightAlt & _rAltPressed);

    final controlModifiers = (RawKeyEventDataWindows.modifierControl &
            (_lControlPressed | _rControlPressed)) |
        (RawKeyEventDataWindows.modifierLeftControl & _lControlPressed) |
        (RawKeyEventDataWindows.modifierRightControl & _rControlPressed);

    final metaModifiers =
        (RawKeyEventDataWindows.modifierLeftMeta & _lMetaPressed) |
            (RawKeyEventDataWindows.modifierRightMeta & _rMetaPressed);

    final shiftModifiers = (RawKeyEventDataWindows.modifierShift &
            (_lShiftPressed | _rShiftPressed)) |
        (RawKeyEventDataWindows.modifierLeftShift & _lShiftPressed) |
        (RawKeyEventDataWindows.modifierRightShift);

    final modifiers =
        altModifiers | controlModifiers | metaModifiers | shiftModifiers;

    final eventData = RawKeyEventDataWindows(
        keyCode: vkCode,
        scanCode: eventAddr.ref.scanCode,
        modifiers: modifiers);

    final RawKeyEvent rawEvent;

    if (pressed == 0xffffffff) {
      rawEvent = RawKeyDownEvent(data: eventData);
    } else {
      rawEvent = RawKeyUpEvent(data: eventData);
    }

    for (final listener in keyboardListeners.values) {
      listener(rawEvent);
    }
  }

  void _mouseProc(dynamic e) {
    final event = shared.mouseProc(e);
    if (event == null) return;

    for (final listener in mouseListeners.values) {
      listener(event);
    }
  }

  final bindings.HidListenerBindingsWindows _bindings;

  int _lAltPressed = 0;
  int _rAltPressed = 0;

  int _lControlPressed = 0;
  int _rControlPressed = 0;

  int _lMetaPressed = 0;
  int _rMetaPressed = 0;

  int _lShiftPressed = 0;
  int _rShiftPressed = 0;
}
