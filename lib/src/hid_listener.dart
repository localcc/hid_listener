import 'dart:collection';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';

import 'hid_listener_bindings.dart' as bindings;
export 'hid_listener_bindings.dart' show KeyboardEvent, HidListenerKeycodes;

const String _libName = 'hid_listener';

final ffi.DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return ffi.DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return ffi.DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return ffi.DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

final bindings.HidListenerBindings _bindings =
    bindings.HidListenerBindings(_dylib);

HashMap<int, void Function(RawKeyEvent)> keyboardListeners = HashMap.identity();
int _lastKeyboardListenerId = 0;

bool _keyboardRegistered = false;
bool _apiInitialized = false;

int _lAltPressed = 0;
int _rAltPressed = 0;

int _lControlPressed = 0;
int _rControlPressed = 0;

int _lMetaPressed = 0;
int _rMetaPressed = 0;

int _lShiftPressed = 0;
int _rShiftPressed = 0;

void keyboardProc(dynamic event) {
  final eventAddr = ffi.Pointer<bindings.KeyboardEvent>.fromAddress(event);

  final vkCode = eventAddr.ref.vkCode;
  final pressed = eventAddr.ref.eventType == bindings.KeyboardEventType.KeyDown
      ? 0xffffffff
      : 0;

  if (vkCode == bindings.HidListenerKeycodes.VK_LMENU) _lAltPressed = pressed;
  if (vkCode == bindings.HidListenerKeycodes.VK_RMENU) _rAltPressed = pressed;
  if (vkCode == bindings.HidListenerKeycodes.VK_LCONTROL) {
    _lControlPressed = pressed;
  }
  if (vkCode == bindings.HidListenerKeycodes.VK_RCONTROL) {
    _rControlPressed = pressed;
  }
  if (vkCode == bindings.HidListenerKeycodes.VK_LWIN) _rMetaPressed = pressed;
  if (vkCode == bindings.HidListenerKeycodes.VK_RWIN) _rMetaPressed = pressed;
  if (vkCode == bindings.HidListenerKeycodes.VK_LSHIFT) {
    _lShiftPressed = pressed;
  }
  if (vkCode == bindings.HidListenerKeycodes.VK_RSHIFT) {
    _rShiftPressed = pressed;
  }

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

  final data = RawKeyEventDataWindows(keyCode: vkCode, modifiers: modifiers);

  final RawKeyEvent rawEvent;

  if (pressed == 0xffffffff) {
    rawEvent = RawKeyDownEvent(data: data);
  } else {
    rawEvent = RawKeyUpEvent(data: data);
  }

  for (var listener in keyboardListeners.values) {
    listener(rawEvent);
  }
}

void _initializeDartAPI() {
  if (!_apiInitialized) {
    _bindings.InitializeDartAPI(ffi.NativeApi.initializeApiDLData);
    _apiInitialized = true;
  }
}

int registerKeyboardListener(void Function(RawKeyEvent) listener) {
  if (!_keyboardRegistered) {
    _initializeDartAPI();
    final requests = ReceivePort()..listen(keyboardProc);
    final int nativePort = requests.sendPort.nativePort;

    _bindings.SetKeyboardListener(nativePort);
    _keyboardRegistered = true;
  }

  keyboardListeners.addAll({_lastKeyboardListenerId: listener});
  return _lastKeyboardListenerId++;
}

void unregisterKeyboardListener(int listenerId) {
  keyboardListeners.remove(listenerId);
}
