import 'dart:ffi' as ffi;
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:hid_listener/src/hid_listener.dart';
import 'package:hid_listener/src/shared/hid_listener_shared.dart' as shared;

import 'hid_listener_bindings_macos.dart' as bindings;

class MacOsHidListenerBackend extends HidListenerBackend {
  MacOsHidListenerBackend(ffi.DynamicLibrary library)
      : _bindings = bindings.HidListenerBindingsSwift(library) {
    bindings.HidListenerBindings.InitializeDartAPIWithData_(
        _bindings, ffi.NativeApi.initializeApiDLData);

    final inverse =
        kMacOsToPhysicalKey.map((key, value) => MapEntry(value, key));

    _muteKeyCode = inverse[PhysicalKeyboardKey.audioVolumeMute]!;
    _volumeUpKeyCode = inverse[PhysicalKeyboardKey.audioVolumeUp]!;
    _volumeDownKeyCode = inverse[PhysicalKeyboardKey.audioVolumeDown]!;
  }

  @override
  bool initialize() {
    return bindings.HidListenerBindings.InitializeListeners(_bindings);
  }

  @override
  bool registerKeyboard() {
    final requests = ReceivePort()..listen(_keyboardProc);
    final int nativePort = requests.sendPort.nativePort;

    return bindings.HidListenerBindings.SetKeyboardListenerWithPort_(
        _bindings, nativePort);
  }

  @override
  bool registerMouse() {
    final requests = ReceivePort()..listen(_mouseProc);
    final int nativePort = requests.sendPort.nativePort;

    return bindings.HidListenerBindings.SetMouseListenerWithPort_(
        _bindings, nativePort);
  }

  void _keyboardProc(dynamic e) {
    final eventAddr =
        ffi.Pointer<ffi.Pointer<bindings.ObjCObject>>.fromAddress(e);
    final event =
        bindings.MacOsKeyboardEvent.castFromPointer(_bindings, eventAddr.value);

    final RawKeyEventData eventData;
    if (!event.isMedia) {
      eventData = _nonMediaKeyboardProc(event);
    } else {
      final data = _mediaKeyboardProc(event);
      if (data == null) return;
      eventData = data;
    }

    final RawKeyEvent rawKeyEvent;
    if (event.eventType ==
        bindings.MacOsKeyboardEventType.MacOsKeyboardEventTypeKeyDown) {
      rawKeyEvent = RawKeyDownEvent(data: eventData);
    } else {
      rawKeyEvent = RawKeyUpEvent(data: eventData);
    }

    for (final listener in keyboardListeners.values) {
      listener(rawKeyEvent);
    }
  }

  RawKeyEventData _nonMediaKeyboardProc(bindings.MacOsKeyboardEvent event) {
    return RawKeyEventDataMacOs(
        characters: event.characters.toString(),
        charactersIgnoringModifiers:
            event.charactersIgnoringModifiers.toString(),
        keyCode: event.keyCode,
        modifiers: event.modifiers);
  }

  RawKeyEventData? _mediaKeyboardProc(bindings.MacOsKeyboardEvent event) {
    LogicalKeyboardKey? specifiedLogicalKey;

    switch (event.mediaEventType) {
      case bindings.MacOsMediaEventType.MacOsMediaEventTypePlay:
        specifiedLogicalKey = LogicalKeyboardKey.mediaPlayPause;
      case bindings.MacOsMediaEventType.MacOsMediaEventTypePrevious:
        specifiedLogicalKey = LogicalKeyboardKey.mediaTrackPrevious;
      case bindings.MacOsMediaEventType.MacOsMediaEventTypeNext:
        specifiedLogicalKey = LogicalKeyboardKey.mediaTrackNext;
      case bindings.MacOsMediaEventType.MacOsMediaEventTypeRewind:
        specifiedLogicalKey = LogicalKeyboardKey.mediaRewind;
      case bindings.MacOsMediaEventType.MacOsMediaEventTypeFast:
        specifiedLogicalKey = LogicalKeyboardKey.mediaFastForward;
      case bindings.MacOsMediaEventType.MacOsMediaEventTypeBrightnessUp:
        specifiedLogicalKey = LogicalKeyboardKey.brightnessUp;
      case bindings.MacOsMediaEventType.MacOsMediaEventTypeBrightnessDown:
        specifiedLogicalKey = LogicalKeyboardKey.brightnessDown;
    }

    if (specifiedLogicalKey != null) {
      return RawKeyEventDataMacOs(
          characters: " ",
          charactersIgnoringModifiers: " ",
          keyCode: 0,
          modifiers: 0,
          specifiedLogicalKey: specifiedLogicalKey.keyId);
    }

    int? keyCode;
    switch (event.mediaEventType) {
      case bindings.MacOsMediaEventType.MacOsMediaEventTypeMute:
        keyCode = _muteKeyCode;
      case bindings.MacOsMediaEventType.MacOsMediaEventTypeVolumeUp:
        keyCode = _volumeUpKeyCode;
      case bindings.MacOsMediaEventType.MacOsMediaEventTypeVolumeDown:
        keyCode = _volumeDownKeyCode;
    }

    if (keyCode == null) return null;
    return RawKeyEventDataMacOs(
        characters: " ",
        charactersIgnoringModifiers: " ",
        keyCode: keyCode,
        modifiers: 0);
  }

  void _mouseProc(dynamic e) {
    final event = shared.mouseProc(e);
    if (event == null) return;

    for (final listener in mouseListeners.values) {
      listener(event);
    }
  }

  final bindings.HidListenerBindingsSwift _bindings;

  late final int _muteKeyCode;
  late final int _volumeUpKeyCode;
  late final int _volumeDownKeyCode;
}
