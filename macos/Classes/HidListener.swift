import AppKit
import CoreGraphics
import Foundation
import HidListenerShared

var listenerInstance: HidListener?

var prevFlags = UInt64(256)

func keyboardEventCallback(
  proxy _: CGEventTapProxy, type: CGEventType, event: CGEvent, _: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
  DispatchQueue.main.async {
    if let nsEvent = NSEvent(cgEvent: event) {
      let eventType = {
        if type == .flagsChanged {
          return prevFlags < event.flags.rawValue ? MacOsKeyboardEventType.KeyDown : MacOsKeyboardEventType.KeyUp
        } else if type == .keyDown {
          return MacOsKeyboardEventType.KeyDown
        }
        return MacOsKeyboardEventType.KeyUp
      }()

      let characters = nsEvent.characters ?? " "
      let charactersIgnoringModifiers = nsEvent.charactersIgnoringModifiers ?? " "
      let keyCode = Int(nsEvent.keyCode)
      let modifiers = Int(nsEvent.modifierFlags.rawValue)
      let keyboardEvent = Unmanaged<MacOsKeyboardEvent>.passRetained(MacOsKeyboardEvent(
        eventType: eventType,
        characters: characters,
        charactersIgnoringModifiers: charactersIgnoringModifiers,
        keyCode: keyCode,
        modifiers: modifiers,
        isMedia: false,
        mediaEventType: MacOsMediaEventType.Play
      ))

      let pointerEvent = UnsafeMutablePointer<MacOsKeyboardEvent>.allocate(capacity: 1)
      pointerEvent.initialize(to: keyboardEvent.takeRetainedValue())

      notifyDart(port: keyboardListenerPort, data: pointerEvent)
    }
  }

  return Unmanaged.passRetained(event)
}

func mediaEventCallback(
  proxy _: CGEventTapProxy, type _: CGEventType, event: CGEvent, _: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
  if let nsEvent = NSEvent(cgEvent: event) {
    let keyCode = (nsEvent.data1 & 0xFFFF_0000) >> 16
    let keyDown = ((nsEvent.data1 & 0xFF00) >> 8) == 0xA

    let mediaEventType: MacOsMediaEventType? = {
      switch Int32(keyCode) {
      case NX_KEYTYPE_PLAY: return MacOsMediaEventType.Play
      case NX_KEYTYPE_PREVIOUS: return MacOsMediaEventType.Previous
      case NX_KEYTYPE_NEXT: return MacOsMediaEventType.Next
      case NX_KEYTYPE_REWIND: return MacOsMediaEventType.Rewind
      case NX_KEYTYPE_FAST: return MacOsMediaEventType.Fast
      case NX_KEYTYPE_MUTE: return MacOsMediaEventType.Mute
      case NX_KEYTYPE_BRIGHTNESS_UP: return MacOsMediaEventType.BrightnessUp
      case NX_KEYTYPE_BRIGHTNESS_DOWN: return MacOsMediaEventType.BrightnessDown
      case NX_KEYTYPE_SOUND_UP: return MacOsMediaEventType.VolumeUp
      case NX_KEYTYPE_SOUND_DOWN: return MacOsMediaEventType.VolumeDown
      default: return nil
      }
    }()

    if mediaEventType != nil {
      let eventType = {
        switch keyDown {
        case true: return MacOsKeyboardEventType.KeyDown
        case false: return MacOsKeyboardEventType.KeyUp
        }
      }()

      let keyboardEvent = Unmanaged<MacOsKeyboardEvent>.passRetained(MacOsKeyboardEvent(
        eventType: eventType,
        characters: " ",
        charactersIgnoringModifiers: " ",
        keyCode: 0,
        modifiers: 0,
        isMedia: true,
        mediaEventType: mediaEventType!
      ))

      let pointerEvent = UnsafeMutablePointer<MacOsKeyboardEvent>.allocate(capacity: 1)
      pointerEvent.initialize(to: keyboardEvent.takeRetainedValue())

      notifyDart(port: keyboardListenerPort, data: pointerEvent)
    }
  }

  return Unmanaged.passRetained(event)
}

func mouseEventCallback(
  proxy _: CGEventTapProxy, type: CGEventType, event: CGEvent, _: UnsafeMutableRawPointer?
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
        | (1 << CGEventType.keyUp.rawValue)

    guard
      let keyboardEventTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
        eventsOfInterest: CGEventMask(keyboardEventMask), callback: keyboardEventCallback, userInfo: nil
      )
    else {
      return false
    }

    guard
      let mediaEventTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
        eventsOfInterest: CGEventMask(1 << NX_SYSDEFINED), callback: mediaEventCallback, userInfo: nil
      )
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
        eventsOfInterest: CGEventMask(mouseEventMask), callback: mouseEventCallback, userInfo: nil
      )
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

  _ = Dart_PostCObject_DL(port, &cObject)
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

@objc public enum MacOsKeyboardEventType: Int {
  case KeyDown, KeyUp
}

@objc public enum MacOsMediaEventType: Int {
  case Play, Previous, Next, Rewind, Fast, Mute, BrightnessUp, BrightnessDown, VolumeUp, VolumeDown
}

@objc public class MacOsKeyboardEvent: NSObject {
  @objc public var eventType: MacOsKeyboardEventType
  @objc public var characters: String
  @objc public var charactersIgnoringModifiers: String
  @objc public var keyCode: Int
  @objc public var modifiers: Int
  @objc public var isMedia: Bool
  @objc public var mediaEventType: MacOsMediaEventType

  init(eventType: MacOsKeyboardEventType, characters: String, charactersIgnoringModifiers: String, keyCode: Int, modifiers: Int, isMedia: Bool, mediaEventType: MacOsMediaEventType) {
    self.eventType = eventType
    self.characters = characters
    self.charactersIgnoringModifiers = charactersIgnoringModifiers
    self.keyCode = keyCode
    self.modifiers = modifiers
    self.isMedia = isMedia
    self.mediaEventType = mediaEventType
  }
}

@objc public class HidListenerBindings: NSObject {
  @objc public static func InitializeDartAPI(data: UnsafeMutableRawPointer) {
    Internal_InitializeDartAPI(data: data)
  }

  @objc public static func InitializeListeners() -> Bool {
    return Internal_InitializeListeners()
  }

  @objc public static func SetKeyboardListener(port: Int64) -> Bool {
    return Internal_SetKeyboardListener(port: Dart_Port(port))
  }

  @objc public static func SetMouseListener(port: Int64) -> Bool {
    return Internal_SetMouseListener(port: Dart_Port(port))
  }
}
