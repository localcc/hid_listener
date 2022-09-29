#ifndef FLUTTER_PLUGIN_HID_LISTENER_PLUGIN_H_
#define FLUTTER_PLUGIN_HID_LISTENER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace hid_listener {

class HidListenerPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  HidListenerPlugin();

  virtual ~HidListenerPlugin();

  // Disallow copy and assign.
  HidListenerPlugin(const HidListenerPlugin&) = delete;
  HidListenerPlugin& operator=(const HidListenerPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace hid_listener

#endif  // FLUTTER_PLUGIN_HID_LISTENER_PLUGIN_H_
