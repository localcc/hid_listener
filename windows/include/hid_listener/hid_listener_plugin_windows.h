#ifndef FLUTTER_PLUGIN_HID_LISTENER_PLUGIN_C_API_H_
#define FLUTTER_PLUGIN_HID_LISTENER_PLUGIN_C_API_H_

#include <hid_listener_shared.h>
#include <flutter_plugin_registrar.h>

#if defined(__cplusplus)
extern "C"
{
#endif

#if defined(__cplusplus)
#include <Windows.h>
	class HidListener
	{
	public:
		HidListener();
		~HidListener();

		static HidListener* Get() { return HidListener::ListenerInstance; }

	private:
		HHOOK m_keyboardHook;
		HHOOK m_mouseHook;

		static HidListener* ListenerInstance;
	};
#endif

    FLUTTER_PLUGIN_EXPORT void HidListenerPluginWindowsRegisterWithRegistrar(
        FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
} // extern "C"
#endif

#endif // FLUTTER_PLUGIN_HID_LISTENER_PLUGIN_C_API_H_
