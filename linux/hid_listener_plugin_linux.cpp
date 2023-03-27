#include "include/hid_listener/hid_listener_plugin.h"
#include "include/hid_listener/hid_listener_linux_conversion.h"
#include <hid_listener_shared.h>

#include <X11/XKBlib.h>
#include <X11/extensions/XInput2.h>

#include <dart-sdk/include/dart_native_api.h>
#include <dart-sdk/include/dart_api_dl.h>
#include <dart-sdk/include/dart_api_dl.c>

#include <stdexcept>
#include <string>

HidListener* HidListener::listenerInstance = nullptr;

HidListener::HidListener() {
    if(listenerInstance) return;

    m_rootInitializer = true;

    Display* display = XOpenDisplay(nullptr);

    int xiOpcode, queryEvent, queryError;
    if(!XQueryExtension(display, "XInputExtension", &xiOpcode, &queryEvent, &queryError)) {
        throw std::runtime_error("Failed to get XInput extension");
    }

    int major = 2, minor = 0;
    if(XIQueryVersion(display, &major, &minor) != Success) {
        throw std::runtime_error(std::string("Failed to get XInput 2.0, got ") + std::to_string(major) + "." + std::to_string(minor));
    }

    Window root = DefaultRootWindow(display);
    XIEventMask  mask;
    mask.deviceid = XIAllMasterDevices;
    mask.mask_len = XIMaskLen(XI_LASTEVENT);
    mask.mask = reinterpret_cast<unsigned char*>(calloc(mask.mask_len, sizeof(char)));

    XISetMask(mask.mask, XI_RawKeyPress);
    XISetMask(mask.mask, XI_RawKeyRelease);
    XISetMask(mask.mask, XI_RawButtonPress);
    XISetMask(mask.mask, XI_RawButtonRelease);
    XISetMask(mask.mask, XI_RawMotion);
    XISelectEvents(display, root, &mask, 1);
    XSync(display, false);
    free(mask.mask);

    int xkbOpcode, xkbEventCode;
    if(!XkbQueryExtension(display, &xkbOpcode, &xkbEventCode, &queryError, &major, &minor)) {
        throw std::runtime_error("XKB extension unavailable");
    }

    m_xiOpcode = xiOpcode;
    m_display = display;

    m_running = true;
    m_workerThread = std::thread([&] {
        this->WorkerThread();
    });
    listenerInstance = this;
}

HidListener::~HidListener() {
    if(!m_rootInitializer) return;

    XCloseDisplay(m_display);

    m_running = false;
    m_workerThread.join();
    listenerInstance = nullptr;
}

static Dart_Port keyboardListenerPort = 0;
static Dart_Port mouseListenerPort = 0;

void NotifyDart(Dart_Port port, const void* work) {
    if(port == 0) return;
    const intptr_t workAddr = reinterpret_cast<intptr_t>(work);

    Dart_CObject cObject;
    cObject.type = Dart_CObject_kInt64;
    cObject.value.as_int64 = workAddr;

    Dart_PostCObject_DL(port, &cObject);
}

void HidListener::WorkerThread() {
    while(m_running) {
        XEvent event;
        XNextEvent(m_display, &event);
        XGenericEventCookie* cookie = &event.xcookie;

        if(XGetEventData(m_display, cookie)) {
            if(cookie->type == GenericEvent && cookie->extension == m_xiOpcode) {
                if(cookie->evtype == XI_RawKeyPress || cookie->evtype == XI_RawKeyRelease) {
                    XIRawEvent* rawEvent = (XIRawEvent*)cookie->data;
                    int winKey = ToWinKey(rawEvent->detail);
                    if(winKey != 0) {
                        KeyboardEventType eventType = KeyboardEventType::KeyDown;

                        if(cookie->evtype == XI_RawKeyRelease) {
                            eventType = KeyboardEventType::KeyUp;
                        }

                        KeyboardEvent* keyboardEvent = new KeyboardEvent;
                        keyboardEvent->eventType =eventType;
                        keyboardEvent->vkCode = winKey;
                        keyboardEvent->scanCode = 0;
                        NotifyDart(keyboardListenerPort, keyboardEvent);
                    }
                } else if (cookie->evtype == XI_RawButtonPress || cookie->evtype == XI_RawButtonRelease || cookie->evtype == XI_RawMotion) {
                    XIRawEvent* rawEvent = (XIRawEvent*)cookie->data;

                    MouseEvent* mouseEvent = new MouseEvent;

                    if (rawEvent->detail == 1) {
                        if (cookie->evtype == XI_RawButtonPress) {
                            mouseEvent->eventType = MouseEventType::LeftButtonDown;
                        } else if (cookie->evtype == XI_RawButtonRelease) {
                            mouseEvent->eventType = MouseEventType::LeftButtonUp;
                        }
                    } else if (rawEvent->detail == 3) {
                        if (cookie->evtype == XI_RawButtonPress) {
                            mouseEvent->eventType = MouseEventType::RightButtonDown;
                        } else if (cookie->evtype == XI_RawButtonRelease) {
                            mouseEvent->eventType = MouseEventType::RightButtonUp;
                        }
                    } else if (rawEvent->detail == 4) {
                        mouseEvent->eventType = MouseEventType::MouseWheel;
                        mouseEvent->wheelDelta = -120;
                    } else if (rawEvent->detail == 5) {
                        mouseEvent->eventType = MouseEventType::MouseWheel;
                        mouseEvent->wheelDelta = 120;
                    } else if (rawEvent->detail == 6) {
                        mouseEvent->eventType = MouseEventType::MouseHorizontalWheel;
                        mouseEvent->wheelDelta = -120;
                    } else if (rawEvent->detail == 7) {
                        mouseEvent->eventType = MouseEventType::MouseHorizontalWheel;
                        mouseEvent->wheelDelta = 120;
                    }
                    
                    if (cookie->evtype == XI_RawMotion) {
                        mouseEvent->eventType = MouseEventType::MouseMove;
                    }


                    Window _unusedWindow;
                    int _unusedInt;
                    int x, y;
                    XQueryPointer(m_display, DefaultRootWindow(m_display), (Window*)&_unusedWindow, (Window*)&_unusedWindow, &x, &y, &_unusedInt, &_unusedInt, (unsigned int*)&_unusedInt);

                    mouseEvent->x = x;
                    mouseEvent->y = y;

                    NotifyDart(mouseListenerPort, mouseEvent);
                }
            }
        }
    }
}

bool SetKeyboardListener(Dart_Port port) {
    if(HidListener::Get() == nullptr) return false;
    keyboardListenerPort = port;
    return true;
}

bool SetMouseListener(Dart_Port port) {
    if(HidListener::Get() == nullptr) return false;
    mouseListenerPort = port;
    return true;
}

void InitializeDartAPI(void* data) {
    Dart_InitializeApiDL(data);
}

bool InitializeListeners() {
    return true;
}