import HidListenerShared

let MacToWin32: [HidListenerKeycodes] = [
  HL_VK_A, HL_VK_S, HL_VK_D, HL_VK_F, HL_VK_H, HL_VK_G,
  HL_VK_Z, HL_VK_X, HL_VK_C, HL_VK_V, HidListenerKeycodes(0), HL_VK_B,
  HL_VK_Q, HL_VK_W, HL_VK_E, HL_VK_R, HL_VK_Y, HL_VK_T,
  HL_VK_1, HL_VK_2, HL_VK_3, HL_VK_4, HL_VK_6, HL_VK_5,
  HL_VK_OEM_PLUS, HL_VK_9, HL_VK_7, HL_VK_OEM_MINUS, HL_VK_8, HL_VK_0,
  HL_VK_OEM_6, HL_VK_O, HL_VK_U, HL_VK_OEM_4, HL_VK_I, HL_VK_P,
  HL_VK_RETURN, HL_VK_L, HL_VK_J, HL_VK_OEM_7, HL_VK_K, HL_VK_OEM_1,
  HL_VK_OEM_5, HL_VK_OEM_COMMA, HL_VK_OEM_2, HL_VK_N, HL_VK_M, HL_VK_OEM_PERIOD,
  HL_VK_TAB, HL_VK_SPACE, HL_VK_OEM_3, HL_VK_BACK, HidListenerKeycodes(0), HL_VK_ESCAPE,
  HidListenerKeycodes(0), HL_VK_LWIN, HL_VK_LSHIFT, HL_VK_CAPITAL, HL_VK_LMENU, HL_VK_LCONTROL,
  HL_VK_RSHIFT, HL_VK_RMENU, HL_VK_RCONTROL, HidListenerKeycodes(0), HL_VK_F17, HL_VK_DECIMAL,
  HidListenerKeycodes(0), HL_VK_MULTIPLY, HidListenerKeycodes(0), HL_VK_ADD, HidListenerKeycodes(0),
  HidListenerKeycodes(0),
  HL_VK_VOLUME_UP, HL_VK_VOLUME_DOWN, HL_VK_VOLUME_MUTE, HL_VK_DIVIDE, HL_VK_RETURN, HidListenerKeycodes(0),
  HL_VK_SUBTRACT, HL_VK_F18, HL_VK_F19, HidListenerKeycodes(0), HL_VK_NUMPAD0, HL_VK_NUMPAD1,
  HL_VK_NUMPAD2, HL_VK_NUMPAD3, HL_VK_NUMPAD4, HL_VK_NUMPAD5, HL_VK_NUMPAD6, HL_VK_NUMPAD7,
  HL_VK_F20, HL_VK_NUMPAD8, HL_VK_NUMPAD9, HidListenerKeycodes(0), HidListenerKeycodes(0),
  HidListenerKeycodes(0),
  HL_VK_F5, HL_VK_F6, HL_VK_F7, HL_VK_F3, HL_VK_F8, HL_VK_F9,
  HidListenerKeycodes(0), HL_VK_F11, HidListenerKeycodes(0), HL_VK_F13, HL_VK_F16, HL_VK_F14,
  HidListenerKeycodes(0), HL_VK_F10, HidListenerKeycodes(0), HL_VK_F12, HidListenerKeycodes(0), HL_VK_F15,
  HL_VK_HELP, HL_VK_HOME, HL_VK_PRIOR, HL_VK_DELETE, HL_VK_F4, HL_VK_END,
  HL_VK_F2, HL_VK_NEXT, HL_VK_F1, HL_VK_LEFT, HL_VK_RIGHT, HL_VK_DOWN,
  HL_VK_UP,
]

func translateMacToWin32(vkCode: Int) -> UInt32 {
  if vkCode > MacToWin32.count {
    return 0
  }

  return MacToWin32[vkCode].rawValue
}
