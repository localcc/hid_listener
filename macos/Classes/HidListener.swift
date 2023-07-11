import Foundation
import HidListenerShared

var listenerInstance: HidListener? = nil

var prevFlags = UInt64(256)

func keyboardEventCallback(
  proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, _: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

  let vkCode = event.getIntegerValueField(.keyboardEventKeycode)
  let translatedVkCode = translateMacToWin32(vkCode: Int(vkCode))

  if translatedVkCode != 0 {
    let keyboardEvent = UnsafeMutablePointer<KeyboardEvent>.allocate(capacity: 1)

    if type == .flagsChanged {
      keyboardEvent.pointee.eventType = KeyboardEventType(prevFlags < event.flags.rawValue ? 1 : 0)

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

func mediaEventCallback(
  proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, _: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
  if let nsEvent = NSEvent(cgEvent: event) {
    let keyCode = (nsEvent.data1 & 0xffff0000) >> 16
    let keyDown = ((nsEvent.data1 & 0xff00) >> 8) == 0xa;

    let translatedVkCode = {
      switch Int32(keyCode) {
        case NX_KEYTYPE_PLAY: return HL_VK_MEDIA_PLAY_PAUSE
        case NX_KEYTYPE_PREVIOUS: return HL_VK_MEDIA_PREV_TRACK
        case NX_KEYTYPE_NEXT: return HL_VK_MEDIA_NEXT_TRACK
        default: return HidListenerKeycodes(0)
      }
    }().rawValue;

    if translatedVkCode != 0 {
      let keyboardEvent = UnsafeMutablePointer<KeyboardEvent>.allocate(capacity: 1)

      keyboardEvent.pointee.eventType = KeyboardEventType(keyDown ? 1 : 0)
      keyboardEvent.pointee.vkCode = translatedVkCode
      keyboardEvent.pointee.scanCode = 0

      notifyDart(port: keyboardListenerPort, data: keyboardEvent)
    }
  }

  return Unmanaged.passRetained(event)
}

func mouseEventCallback(
  proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, _: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

  let mouseLoc = NSEvent.mouseLocation
  let mouseEvent = UnsafeMutablePointer<MouseEvent>.allocate(capacity: 1)

  mouseEvent.pointee.x = mouseLoc.x
  mouseEvent.pointee.y = mouseLoc.y

  if type == .leftMouseDown {
    mouseEvent.pointee.eventType = MouseEventType(0)
  } else if type == .leftMouseUp {
    mouseEvent.pointee.eventType = MouseEventType(1)
  } else if type == .rightMouseDown {
    mouseEvent.pointee.eventType = MouseEventType(2)
  } else if type == .rightMouseUp {
    mouseEvent.pointee.eventType = MouseEventType(3)
  } else if type == .mouseMoved || type == .leftMouseDragged || type == .rightMouseDragged {
    mouseEvent.pointee.eventType = MouseEventType(4)
  } else if type == .scrollWheel {
    let verticalScroll = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
    let horizontalScroll = event.getIntegerValueField(.scrollWheelEventDeltaAxis2)

    if verticalScroll != 0 {
      mouseEvent.pointee.eventType = MouseEventType(5)
      mouseEvent.pointee.wheelDelta = verticalScroll
    } else if horizontalScroll != 0 {
      mouseEvent.pointee.eventType = MouseEventType(6)
      mouseEvent.pointee.wheelDelta = horizontalScroll
    }
  }

  notifyDart(port: mouseListenerPort, data: mouseEvent)

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
    let keyboardEventMask =
      (1 << CGEventType.keyDown.rawValue)
      | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

    guard
      let keyboardEventTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
        eventsOfInterest: CGEventMask(keyboardEventMask), callback: keyboardEventCallback, userInfo: nil)
    else {
      return false
    }

    guard
      let mediaEventTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
        eventsOfInterest: CGEventMask(1 << NX_SYSDEFINED), callback: mediaEventCallback, userInfo: nil)
    else {
      return false
    }

    let mouseEventMask = 
      (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.leftMouseUp.rawValue) |
      (1 << CGEventType.rightMouseDown.rawValue) | (1 << CGEventType.rightMouseUp.rawValue) |
      (1 << CGEventType.mouseMoved.rawValue) | (1 << CGEventType.scrollWheel.rawValue) |
      (1 << CGEventType.leftMouseDragged.rawValue) | (1 << CGEventType.rightMouseDragged.rawValue)
    
    guard
      let mouseEventTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
        eventsOfInterest: CGEventMask(mouseEventMask), callback: mouseEventCallback, userInfo: nil)
    else {
      return false
    }

    keyboardQueue.async {
      let keyboardRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, keyboardEventTap, 0)
      let mediaRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, mediaEventTap, 0)
      let mouseRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, mouseEventTap, 0)
      CFRunLoopAddSource(CFRunLoopGetCurrent(), keyboardRunLoopSource, .commonModes)
      CFRunLoopAddSource(CFRunLoopGetCurrent(), mediaRunLoopSource, .commonModes)
      CFRunLoopAddSource(CFRunLoopGetCurrent(), mouseRunLoopSource, .commonModes)
      CGEvent.tapEnable(tap: keyboardEventTap, enable: true)
      CGEvent.tapEnable(tap: mediaEventTap, enable: true)
      CGEvent.tapEnable(tap: mouseEventTap, enable: true)
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
var mouseListenerPort: Dart_Port = 0

func notifyDart(port: Dart_Port, data: UnsafeMutableRawPointer) {
  if port == 0 {
    return
  }

  var cObject = Dart_CObject()
  cObject.type = Dart_CObject_kInt64
  cObject.value.as_int64 = Int64(UInt(bitPattern: data))

  let _ = Dart_PostCObject_DL(port, &cObject)
}

func Internal_SetKeyboardListener(port: Dart_Port) -> Bool {
  if !(listenerInstance?.initialized ?? false) {
    return false
  }
  keyboardListenerPort = port
  return true
}

func Internal_SetMouseListener(port: Dart_Port) -> Bool {
  if !(listenerInstance?.initialized ?? false) {
    return false
  }
  mouseListenerPort = port
  return true
}

func Internal_InitializeDartAPI(data: UnsafeMutableRawPointer) {
  Dart_InitializeApiDL(data)
}

func Internal_InitializeListeners() -> Bool {
  if listenerInstance == nil {
    listenerInstance = HidListener()
  }
  return listenerInstance?.initialize() ?? false
}

@objc public class HidListenerBindings: NSObject {

  @objc public static func InitializeDartAPI(data: UnsafeMutableRawPointer) {
    Internal_InitializeDartAPI(data: data)
  }

  @objc public static func InitializeListeners() -> Bool {
    return Internal_InitializeListeners()
  }

  @objc public static func SetKeyboardListener(port: Dart_Port) -> Bool {
    return Internal_SetKeyboardListener(port: port)
  }

  @objc public static func SetMouseListener(port: Dart_Port) -> Bool {
    return Internal_SetMouseListener(port: port)
  }
}
