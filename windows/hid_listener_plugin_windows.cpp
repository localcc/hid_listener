#include "include/hid_listener/hid_listener_plugin_windows.h"

#include <flutter/plugin_registrar_windows.h>
#include <dart-sdk/include/dart_native_api.h>
#include <dart-sdk/include/dart_api_dl.h>
#include <dart-sdk/include/dart_api_dl.c>

#include <functional>

#include "hid_listener_plugin.h"

static Dart_Port listenerPort = 0;

void NotifyDart(Dart_Port port, const void* work) {
	const intptr_t workAddr = reinterpret_cast<intptr_t>(work);

	Dart_CObject cObject;
	cObject.type = Dart_CObject_kInt64;
	cObject.value.as_int64 = workAddr;

	Dart_PostCObject_DL(port, &cObject);
}

static LRESULT KeyboardProc(int nCode, WPARAM wParam, LPARAM lParam) {
	if (nCode < 0 || listenerPort == 0 || Dart_PostCObject_DL == nullptr) return CallNextHookEx(NULL, nCode, wParam, lParam);

	KeyboardEventType eventType = KeyboardEventType::KeyDown;

	if (wParam == WM_SYSKEYUP || wParam == WM_KEYUP) {
		eventType = KeyboardEventType::KeyUp;
	}

	KBDLLHOOKSTRUCT* info = reinterpret_cast<KBDLLHOOKSTRUCT*>(lParam);

	KeyboardEvent* keyboardEvent = new KeyboardEvent;
	keyboardEvent->eventType = eventType;
	keyboardEvent->vkCode = info->vkCode; 
	keyboardEvent->scanCode = info->scanCode;

	NotifyDart(listenerPort, keyboardEvent);

	return CallNextHookEx(NULL, nCode, wParam, lParam);
}

#if defined(__cplusplus)

HidListener* HidListener::listenerInstance = nullptr;

HidListener::HidListener() {
    m_keyboardHook = SetWindowsHookEx(WH_KEYBOARD_LL, KeyboardProc, NULL, NULL);
    
    listenerInstance = this;
}

HidListener::~HidListener() {
	UnhookWindowsHookEx(m_keyboardHook);

	listenerInstance = nullptr;
}

#endif

bool SetKeyboardListener(Dart_Port port) {
	if(HidListener::Get() == nullptr) return false;
	listenerPort = port;
	return true;
}

void InitializeDartAPI(void* data) {
	Dart_InitializeApiDL(data);
}

bool InitializeListeners() {
	return true;
}

void HidListenerPluginWindowsRegisterWithRegistrar(
	FlutterDesktopPluginRegistrarRef registrar) {
	hid_listener::HidListenerPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarManager::GetInstance()
		->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
