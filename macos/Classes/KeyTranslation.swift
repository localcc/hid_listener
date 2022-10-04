import HidListenerShared

let MacToWin32: [HidListenerKeycodes] = [
  VK_A, VK_S, VK_D, VK_F, VK_H, VK_G,
  VK_Z, VK_X, VK_C, VK_V, HidListenerKeycodes(0), VK_B,
  VK_Q, VK_W, VK_E, VK_R, VK_Y, VK_T,
  VK_1, VK_2, VK_3, VK_4, VK_6, VK_5,
  VK_OEM_PLUS, VK_9, VK_7, VK_OEM_MINUS, VK_8, VK_0,
  VK_OEM_6, VK_O, VK_U, VK_OEM_4, VK_I, VK_P,
  VK_RETURN, VK_L, VK_J, VK_OEM_7, VK_K, VK_OEM_1,
  VK_OEM_5, VK_OEM_COMMA, VK_OEM_2, VK_N, VK_M, VK_OEM_PERIOD,
  VK_TAB, VK_SPACE, VK_OEM_3, VK_BACK, HidListenerKeycodes(0), VK_ESCAPE,
  HidListenerKeycodes(0), VK_LWIN, VK_LSHIFT, VK_CAPITAL, VK_LMENU, VK_LCONTROL,
  VK_RSHIFT, VK_RMENU, VK_RCONTROL, HidListenerKeycodes(0), VK_F17, VK_DECIMAL,
  HidListenerKeycodes(0), VK_MULTIPLY, HidListenerKeycodes(0), VK_ADD, HidListenerKeycodes(0),
  HidListenerKeycodes(0),
  VK_VOLUME_UP, VK_VOLUME_DOWN, VK_VOLUME_MUTE, VK_DIVIDE, VK_RETURN, HidListenerKeycodes(0),
  VK_SUBTRACT, VK_F18, VK_F19, HidListenerKeycodes(0), VK_NUMPAD0, VK_NUMPAD1,
  VK_NUMPAD2, VK_NUMPAD3, VK_NUMPAD4, VK_NUMPAD5, VK_NUMPAD6, VK_NUMPAD7,
  VK_F20, VK_NUMPAD8, VK_NUMPAD9, HidListenerKeycodes(0), HidListenerKeycodes(0),
  HidListenerKeycodes(0),
  VK_F5, VK_F6, VK_F7, VK_F3, VK_F8, VK_F9,
  HidListenerKeycodes(0), VK_F11, HidListenerKeycodes(0), VK_F13, VK_F16, VK_F14,
  HidListenerKeycodes(0), VK_F10, HidListenerKeycodes(0), VK_F12, HidListenerKeycodes(0), VK_F15,
  VK_HELP, VK_HOME, VK_PRIOR, VK_DELETE, VK_F4, VK_END,
  VK_F2, VK_NEXT, VK_F1, VK_LEFT, VK_RIGHT, VK_DOWN,
  VK_UP,
]

func translateMacToWin32(vkCode: Int) -> UInt32 {
  if vkCode > MacToWin32.count {
    return 0
  }

  return MacToWin32[vkCode].rawValue
}
