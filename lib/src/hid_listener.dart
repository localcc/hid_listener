import 'dart:collection';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:hid_listener/src/macos/hid_listener_macos.dart';
import 'package:hid_listener/src/windows/hid_listener_windows.dart';
import 'package:hid_listener/src/linux/hid_listener_linux.dart';

import 'hid_listener_types.dart';
export 'hid_listener_types.dart'
    show
        MouseEvent,
        MouseButtonEventType,
        MouseButtonEvent,
        MouseMoveEvent,
        MouseWheelEvent;

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

abstract class HidListenerBackend {
  int? addKeyboardListener(void Function(RawKeyEvent) listener) {
    if (!_keyboardRegistered) {
      if (!registerKeyboard()) return null;
      _keyboardRegistered = true;
    }

    keyboardListeners.addAll({_lastKeyboardListenerId: listener});
    return _lastKeyboardListenerId++;
  }

  void removeKeyboardListener(int listenerId) {
    keyboardListeners.remove(listenerId);
  }

  int? addMouseListener(void Function(MouseEvent) listener) {
    if (!_mouseRegistered) {
      if (!registerMouse()) return null;
      _mouseRegistered = true;
    }

    mouseListeners.addAll({_lastMouseListenerId: listener});
    return _lastMouseListenerId++;
  }

  void removeMouseListener(int listenerId) {
    mouseListeners.remove(listenerId);
  }

  bool initialize();
  bool registerKeyboard();
  bool registerMouse();

  @protected
  HashMap<int, void Function(RawKeyEvent)> keyboardListeners =
      HashMap.identity();
  @protected
  HashMap<int, void Function(MouseEvent)> mouseListeners = HashMap.identity();

  int _lastKeyboardListenerId = 0;
  int _lastMouseListenerId = 0;

  bool _keyboardRegistered = false;
  bool _mouseRegistered = false;
}

HidListenerBackend? _createPlatformBackend() {
  if (Platform.isWindows) return WindowsHidListenerBackend(_dylib);
  if (Platform.isMacOS) return MacOsHidListenerBackend(_dylib);
  if (Platform.isLinux) return LinuxHidListenerBackend(_dylib);
  return null;
}

HidListenerBackend? _backend = _createPlatformBackend();

HidListenerBackend? getListenerBackend() {
  return _backend;
}
