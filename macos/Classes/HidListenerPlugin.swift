import Cocoa
import Dispatch
import FlutterMacOS
import Foundation
import HidListenerShared

public class HidListenerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
  }
}

var listenerInstance: HidListener? = nil

var prevFlags = UInt64(256)

func eventCallback(
  proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, _: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

  let vkCode = event.getIntegerValueField(.keyboardEventKeycode)
  let translatedVkCode = translateMacToWin32(vkCode: Int(vkCode))

  if translatedVkCode != 0 {
    let keyboardEvent = UnsafeMutablePointer<KeyboardEvent>.allocate(capacity: 1)

    if type == .flagsChanged {
      keyboardEvent.pointee.eventType = KeyboardEventType(prevFlags < event.flags.rawValue ? 0 : 1)

      prevFlags = event.flags.rawValue
    } else if type == .keyDown {
      keyboardEvent.pointee.eventType = KeyboardEventType(1)
    } else {
      keyboardEvent.pointee.eventType = KeyboardEventType(0)
    }

    keyboardEvent.pointee.vkCode = translatedVkCode
    keyboardEvent.pointee.scanCode = 0

    notifyDart(port: keyboardListenerPort, data: keyboardEvent)
  }

  return Unmanaged.passRetained(event)
}

public class HidListener {
  let keyboardQueue = DispatchQueue(label: "HidListener Keyboard Queue")
  var initialized = false
  var rootInitializer = false

  public init() {
    if listenerInstance != nil {
      return
    }

    rootInitializer = true
    listenerInstance = self
  }

  public func initialize() -> Bool {
    let eventMask =
      (1 << CGEventType.keyDown.rawValue)
      | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

    guard
      let eventTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
        eventsOfInterest: CGEventMask(eventMask), callback: eventCallback, userInfo: nil)
    else {
      return false
    }

    keyboardQueue.async {
      let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
      CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
      CGEvent.tapEnable(tap: eventTap, enable: true)
      CFRunLoopRun()
    }

    initialized = true

    return initialized
  }

  deinit {
    if rootInitializer {
      listenerInstance = nil
    }
  }
}

var keyboardListenerPort: Dart_Port = 0

func notifyDart(port: Dart_Port, data: UnsafeMutableRawPointer) {
  if port == 0 {
    return
  }

  var cObject = Dart_CObject()
  cObject.type = Dart_CObject_kInt64
  cObject.value.as_int64 = Int64(UInt(bitPattern: data))

  let _ = Dart_PostCObject_DL(port, &cObject)
}

@_cdecl("SetKeyboardListener")
func SetKeyboardListener(port: Dart_Port) -> Bool {
  if !(listenerInstance?.initialized ?? false) {
    return false
  }
  keyboardListenerPort = port
  return true
}

@_cdecl("InitializeDartAPI")
func InitializeDartAPI(data: UnsafeMutableRawPointer) {
  Dart_InitializeApiDL(data)
}

@_cdecl("InitializeListeners")
func InitializeListeners() -> Bool {
  if listenerInstance == nil {
    listenerInstance = HidListener()
  }
  return listenerInstance?.initialize() ?? false
}
