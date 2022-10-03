#pragma once
#include <stdint.h>
#include <hid_listener_keycodes.h>

const uint8_t X11ToWin32[] = {
        0, 0, 0, 0, 0, 0, 0,
        0, 0, VK_ESCAPE, VK_1, VK_2, VK_3,
        VK_4, VK_5, VK_6, VK_7, VK_8, VK_9,
        VK_0, VK_OEM_MINUS, VK_OEM_PLUS, VK_BACK, VK_TAB, VK_Q,
        VK_W, VK_E, VK_R, VK_T, VK_Y, VK_U,
        VK_I, VK_O, VK_P, VK_OEM_4, VK_OEM_6, VK_RETURN,
        VK_LCONTROL, VK_A, VK_S, VK_D, VK_F, VK_G,
        VK_H, VK_J, VK_K, VK_L, VK_OEM_1, VK_OEM_8,
        VK_OEM_3, VK_LSHIFT, VK_OEM_5, VK_Z, VK_X, VK_C,
        VK_V, VK_B, VK_N, VK_M, VK_OEM_COMMA, VK_OEM_PERIOD,
        VK_OEM_2, VK_RSHIFT, VK_MULTIPLY, VK_LMENU, VK_SPACE, VK_CAPITAL,
        VK_F1, VK_F2, VK_F3, VK_F4, VK_F5, VK_F6,
        VK_F7, VK_F8, VK_F9, VK_F10, VK_NUMLOCK, VK_SCROLL,
        VK_NUMPAD7, VK_NUMPAD8, VK_NUMPAD9, VK_SUBTRACT, VK_NUMPAD4, VK_NUMPAD5,
        VK_NUMPAD6, VK_ADD, VK_NUMPAD1, VK_NUMPAD2, VK_NUMPAD3, VK_NUMPAD0,
        VK_DECIMAL, 0, 0, 0, VK_F11, VK_F12,
        VK_HOME, VK_UP, VK_PRIOR, VK_LEFT, 0, VK_RIGHT,
        VK_END, VK_DOWN, VK_NEXT, VK_INSERT, VK_DELETE, 0,
        VK_RCONTROL, VK_PAUSE, VK_SNAPSHOT, VK_DIVIDE, VK_RMENU, 0,
        VK_LWIN, VK_RWIN,
};
const int X11ToWin32Size = sizeof(X11ToWin32) / sizeof(uint8_t);

int ToWinKey(int x11Code) {
    if(x11Code >= X11ToWin32Size) return 0;
    return X11ToWin32[x11Code];
}