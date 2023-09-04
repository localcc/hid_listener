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
