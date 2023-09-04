# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "hid_listener")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "hid_listener_plugin")

add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../shared" shared)

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "hid_listener_plugin.cpp"
  "hid_listener_plugin.h"
)

get_filename_component(SHARED_INC ${CMAKE_CURRENT_SOURCE_DIR}/../shared ABSOLUTE)
# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
add_library(${PLUGIN_NAME} SHARED
  "include/hid_listener/hid_listener_plugin_windows.h"
  "hid_listener_plugin_windows.cpp"
  "${SHARED_INC}/dart-sdk/include/dart_api_dl.h"
  "${SHARED_INC}/dart-sdk/include/dart_api_dl.c"
  ${PLUGIN_SOURCES}
)

set_target_properties(${PLUGIN_NAME} PROPERTIES OUTPUT_NAME "hid_listener")

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
# apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.

include_directories(${SHARED_INC})
include_directories(${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  ${SHARED_INC})
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(hid_listener_bundled_libraries
  ""
  PARENT_SCOPE
)
