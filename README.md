# hid_listener

HidListener is a library that allows you to listen to hid events cross-platform.


## Windows

Add this into your `main.cpp` file

```cpp
#include <hid_listener/hid_listener_plugin_windows.h>
```

and add this inside `wWinMain` funciton

```cpp
HidListener listener;
```

## MacOS 

Add this into your `MainFlutterWindow.swift` file

```swift
import hid_listener
```

and add this inside `MainFlutterWindow` class

```swift
let listener = HidListener()
```

The file should now look something like this:

```swift
...
import hid_listener

class MainFlutterWindow: NSWindow {
  let listener = HidListener()
...
```

## Linux

Add this into your `main.cc` file

```cpp
#include <hid_listener/hid_listener_plugin.h>
```

and add this inside `main` funciton

```cpp
HidListener listener;
```

## Dart

To use the library, you first have to initialize the listener backend:

```dart
if (getListenerBackend() != null) {
  if (!getListenerBackend().initialize()) {
    print("Failed to initialize listener backend");
  }
} else {
  print("No listener backend for this platform")
}
```

After successfully initializing the listener backend, register listeners like this:

```dart
final keyboardListenerId = getListenerBackend()!.addKeyboardListener((event) {
  print("${event.logicalKey.debugName}")
});

getListenerBackend()!.addMouseListener((event) { ... })
```

Removing listeners can be done using `remove(keyboard/Mouse)Listener` method call:

```dart
getListenerBackend()!.removeKeyboardListener(keyboardListenerId);
```


