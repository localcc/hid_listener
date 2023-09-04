#pragma once
#include <stdint.h>

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

enum MouseEventType
{
    LeftButtonDown,
    LeftButtonUp,
    RightButtonDown,
    RightButtonUp,
    MouseMove,
    MouseWheel,
    MouseHorizontalWheel
};

struct MouseEvent {
    enum MouseEventType eventType;
    double x;
    double y;
    int64_t wheelDelta;
};
