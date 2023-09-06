#pragma once
#include <stdint.h>

#include "dart-sdk/include/dart_native_api.h"
#include "dart-sdk/include/dart_api_dl.h"

#ifdef _MSC_VER
#define PLUGIN_DLLEXPORT __declspec(dllexport)
#define PLUGIN_DLLIMPORT __declspec(dllimport)
#else

#ifdef __cplusplus
#define DLLEXPORT [[gnu::dllexport]]
#define DLLIMPORT [[gnu::dllimport]]
#else
#define DLLEXPORT __attribute__((visibility("default")))
#define DLLIMPORT
#endif

#define PLUGIN_DLLEXPORT DLLEXPORT __attribute__((used))
#define PLUGIN_DLLIMPORT DLLIMPORT __attribute__((used))

#endif

#ifndef __APPLE__
#ifndef FLUTTER_PLUGIN_EXPORT
#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT PLUGIN_DLLEXPORT
#else
#define FLUTTER_PLUGIN_EXPORT PLUGIN_DLLIMPORT
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
