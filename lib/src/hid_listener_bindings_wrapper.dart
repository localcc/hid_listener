import 'dart:ffi' as ffi;
import 'hid_listener_bindings_universal.dart' as universal_bindings;
import 'hid_listener_bindings_swift.dart' as swift_bindings;

abstract class HidListenerBindingsWrapper {
  void initializeDartApi(ffi.Pointer<ffi.Void> data);
  bool initializeListeners();
  bool setKeyboardListener(int port);
}

class UniversalHidListenerBindings extends HidListenerBindingsWrapper {
  UniversalHidListenerBindings(ffi.DynamicLibrary library)
      : _bindings = universal_bindings.HidListenerBindings(library);

  @override
  void initializeDartApi(ffi.Pointer<ffi.Void> data) {
    _bindings.InitializeDartAPI(data);
  }

  @override
  bool initializeListeners() {
    return _bindings.InitializeListeners();
  }

  @override
  bool setKeyboardListener(int port) {
    return _bindings.SetKeyboardListener(port);
  }

  final universal_bindings.HidListenerBindings _bindings;
}

class SwiftHidListenerBindings extends HidListenerBindingsWrapper {
  SwiftHidListenerBindings(ffi.DynamicLibrary library) : _bindings = swift_bindings.HidListenerBindingsSwift(library);

  @override
  void initializeDartApi(ffi.Pointer<ffi.Void> data) {
    swift_bindings.HidListenerBindings.InitializeDartAPIWithData_(_bindings, data);
  }

  @override
  bool initializeListeners() {
    return swift_bindings.HidListenerBindings.InitializeListeners(_bindings);
  }

  @override
  bool setKeyboardListener(int port) {
    return swift_bindings.HidListenerBindings.SetKeyboardListenerWithPort_(_bindings, port);
  }

  final swift_bindings.HidListenerBindingsSwift _bindings;
}
