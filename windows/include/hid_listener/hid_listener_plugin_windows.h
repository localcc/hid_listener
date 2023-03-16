#ifndef FLUTTER_PLUGIN_HID_LISTENER_PLUGIN_C_API_H_
#define FLUTTER_PLUGIN_HID_LISTENER_PLUGIN_C_API_H_

#include <hid_listener_shared.h>
#include <flutter_plugin_registrar.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C"
{
#endif

#if defined(__cplusplus)
#include <Windows.h>
	class FLUTTER_PLUGIN_EXPORT HidListener
	{
	public:
		HidListener();
		~HidListener();

		static HidListener* Get() { return HidListener::listenerInstance; }

	private:
		HHOOK m_keyboardHook;
		HHOOK m_mouseHook;

		static HidListener* listenerInstance;
	};
#endif

    FLUTTER_PLUGIN_EXPORT void HidListenerPluginWindowsRegisterWithRegistrar(
        FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
} // extern "C"
#endif

#endif // FLUTTER_PLUGIN_HID_LISTENER_PLUGIN_C_API_H_
