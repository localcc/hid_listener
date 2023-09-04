import 'dart:ffi' as ffi;
import 'package:hid_listener/hid_listener.dart';

import 'hid_listener_bindings_shared.dart' as bindings;

MouseEvent? mouseProc(dynamic event) {
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

  return mouseEvent;
}
