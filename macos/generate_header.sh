#!/bin/bash
swiftc -framework CoreGraphics -c Classes/HidListener.swift -I ../shared/module -module-name HidListener -emit-objc-header-path Bindings/HidListener.h
