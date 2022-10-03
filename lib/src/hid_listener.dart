import 'dart:collection';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';

import 'hid_listener_bindings.dart' as bindings;
export 'hid_listener_bindings.dart' show KeyboardEvent, HidListenerKeycodes;

const String _libName = 'hid_listener_plugin';

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

HashMap<int, void Function(bindings.KeyboardEvent)> keyboardListeners =
    HashMap.identity();
int _lastKeyboardListenerId = 0;

bool _keyboardRegistered = false;
bool _apiInitialized = false;

void keyboardProc(dynamic event) {
  final eventAddr = ffi.Pointer<bindings.KeyboardEvent>.fromAddress(event);

  for (var listener in keyboardListeners.values) {
    listener(eventAddr.ref);
  }
}

void _initializeDartAPI() {
  if (!_apiInitialized) {
    _bindings.InitializeDartAPI(ffi.NativeApi.initializeApiDLData);
    _apiInitialized = true;
  }
}

int registerKeyboardListener(void Function(bindings.KeyboardEvent) listener) {
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
