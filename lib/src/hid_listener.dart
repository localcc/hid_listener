import 'dart:collection';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';

import 'hid_listener_bindings_wrapper.dart';
import 'hid_listener_bindings_universal.dart' as bindings;
export 'hid_listener_bindings_universal.dart'
    show KeyboardEvent, HidListenerKeycodes;

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

HidListenerBindingsWrapper initializeBindings(ffi.DynamicLibrary library) {
  if (Platform.isMacOS || Platform.isIOS) {
    return SwiftHidListenerBindings(library);
  } else {
    return UniversalHidListenerBindings(library);
  }
}

final HidListenerBindingsWrapper _bindings = initializeBindings(_dylib);

class MouseEvent {
  MouseEvent({required this.x, required this.y});
  double x;
  double y;
}

enum MouseButtonEventType {
  leftButtonUp,
  leftButtonDown,
  rightButtonUp,
  rightButtonDown,
}

class MouseButtonEvent extends MouseEvent {
  MouseButtonEvent({required super.x, required super.y, required this.type});

  MouseButtonEventType type;
}

class MouseMoveEvent extends MouseEvent {
  MouseMoveEvent({required super.x, required super.y});
}

class MouseWheelEvent extends MouseEvent {
  MouseWheelEvent(
      {required super.x,
      required super.y,
      required this.wheelDelta,
      required this.isHorizontal});

  int wheelDelta;
  bool isHorizontal;
}

HashMap<int, void Function(RawKeyEvent)> keyboardListeners = HashMap.identity();
HashMap<int, void Function(MouseEvent)> mouseListeners = HashMap.identity();
int _lastKeyboardListenerId = 0;
int _lastMouseListenerId = 0;

bool _keyboardRegistered = false;
bool _mouseRegistered = false;

bool _apiInitialized = false;
bool _listenersInitialized = false;

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

void mouseProc(dynamic event) {
  final eventAddr = ffi.Pointer<bindings.MouseEvent>.fromAddress(event);

  MouseEvent? mouseEvent;

  if (eventAddr.ref.eventType == bindings.MouseEventType.LeftButtonDown) {
    mouseEvent = MouseButtonEvent(
        x: eventAddr.ref.x,
        y: eventAddr.ref.y,
        type: MouseButtonEventType.leftButtonDown);
  } else if (eventAddr.ref.eventType == bindings.MouseEventType.LeftButtonUp) {
    mouseEvent = MouseButtonEvent(
        x: eventAddr.ref.x,
        y: eventAddr.ref.y,
        type: MouseButtonEventType.leftButtonUp);
  } else if (eventAddr.ref.eventType ==
      bindings.MouseEventType.RightButtonDown) {
    mouseEvent = MouseButtonEvent(
        x: eventAddr.ref.x,
        y: eventAddr.ref.y,
        type: MouseButtonEventType.rightButtonDown);
  } else if (eventAddr.ref.eventType == bindings.MouseEventType.RightButtonUp) {
    mouseEvent = MouseButtonEvent(
        x: eventAddr.ref.x,
        y: eventAddr.ref.y,
        type: MouseButtonEventType.rightButtonUp);
  } else if (eventAddr.ref.eventType == bindings.MouseEventType.MouseMove) {
    mouseEvent = MouseMoveEvent(x: eventAddr.ref.x, y: eventAddr.ref.y);
  } else if (eventAddr.ref.eventType == bindings.MouseEventType.MouseWheel ||
      eventAddr.ref.eventType == bindings.MouseEventType.MouseHorizontalWheel) {
    mouseEvent = MouseWheelEvent(
        x: eventAddr.ref.x,
        y: eventAddr.ref.y,
        wheelDelta: eventAddr.ref.wheelDelta,
        isHorizontal: eventAddr.ref.eventType ==
            bindings.MouseEventType.MouseHorizontalWheel);
  }

  if (mouseEvent == null) return;

  for (var listener in mouseListeners.values) {
    listener(mouseEvent);
  }
}

void _initializeDartAPI() {
  if (!_apiInitialized) {
    _bindings.initializeDartApi(ffi.NativeApi.initializeApiDLData);
    _apiInitialized = true;
  }
}

bool _initializeListeners() {
  if (!_listenersInitialized) {
    _listenersInitialized = _bindings.initializeListeners();
  }
  return _listenersInitialized;
}

int? registerKeyboardListener(void Function(RawKeyEvent) listener) {
  if (!_keyboardRegistered) {
    _initializeDartAPI();
    final requests = ReceivePort()..listen(keyboardProc);
    final int nativePort = requests.sendPort.nativePort;

    if (!_initializeListeners() || !_bindings.setKeyboardListener(nativePort)) {
      return null;
    }

    _keyboardRegistered = true;
  }

  keyboardListeners.addAll({_lastKeyboardListenerId: listener});
  return _lastKeyboardListenerId++;
}

int? registerMouseListener(void Function(MouseEvent) listener) {
  if (!_mouseRegistered) {
    _initializeDartAPI();

    final requests = ReceivePort()..listen(mouseProc);
    final int nativePort = requests.sendPort.nativePort;

    if (!_initializeListeners() || !_bindings.setMouseListener(nativePort)) {
      return null;
    }

    _mouseRegistered = true;
  }

  mouseListeners.addAll({_lastMouseListenerId: listener});
  return _lastMouseListenerId++;
}

void unregisterKeyboardListener(int listenerId) {
  keyboardListeners.remove(listenerId);
}

void unregisterMouseListener(int listenerId) {
  mouseListeners.remove(listenerId);
}
