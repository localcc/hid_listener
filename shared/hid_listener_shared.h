#pragma once
#include <stdint.h>

#include "hid_listener_keycodes.h"
#include "dart-sdk/include/dart_native_api.h"
#include "dart-sdk/include/dart_api_dl.h"

#ifndef __APPLE__
#ifndef FLUTTER_PLUGIN_EXPORT
#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif
#endif
#else
#define FLUTTER_PLUGIN_EXPORT
#endif

enum KeyboardEventType
{
    KeyUp,
    KeyDown
};

struct KeyboardEvent
{
    enum KeyboardEventType eventType;
    uint32_t vkCode;
    uint32_t scanCode;
};

typedef int (*KeyboardListener)(struct KeyboardEvent keyboardEvent);

#if defined(__cplusplus)
extern "C"
{
#endif
    FLUTTER_PLUGIN_EXPORT bool SetKeyboardListener(Dart_Port port);
    FLUTTER_PLUGIN_EXPORT void InitializeDartAPI(void* data);
    FLUTTER_PLUGIN_EXPORT bool InitializeListeners();
#if defined(__cplusplus)
}
#endif
