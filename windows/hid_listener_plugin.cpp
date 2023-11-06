#include "hid_listener_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <include/hid_listener/hid_listener_plugin_windows.h>

namespace hid_listener {

// static
void HidListenerPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "hid_listener",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<HidListenerPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  
  registrar->AddPlugin(std::move(plugin));
}

HidListenerPlugin::HidListenerPlugin() {}

HidListenerPlugin::~HidListenerPlugin() {}
static HidListener listener;
void HidListenerPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getPlatformVersion") == 0) {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) {
      version_stream << "10+";
    } else if (IsWindows8OrGreater()) {
      version_stream << "8";
    } else if (IsWindows7OrGreater()) {
      version_stream << "7";
    }
    result->Success(flutter::EncodableValue(version_stream.str()));
  }
  else if (method_call.method_name().compare("Initialize") == 0) {
      listener = HidListener();
      printf("HidListenerPlugin::HandleMethodCall: Initialize\n");
  }
  else if (method_call.method_name().compare("Dispose") == 0) {
      printf("HidListenerPlugin::HandleMethodCall: Dispose\n");
	  listener.~HidListener();
  }
  else {
    result->NotImplemented();
  }
}

}  // namespace hid_listener
