TARGET := iphone:clang:9.3:6.0
ARCHS := armv7
include $(THEOS)/makefiles/common.mk
TWEAK_NAME := M3gaAppCustomizer
M3gaAppCustomizer_FILES := Tweak.x
M3gaAppCustomizer_FRAMEWORKS := UIKit Foundation CoreGraphics
M3gaAppCustomizer_CFLAGS := -fobjc-arc -Wno-deprecated-declarations
include $(THEOS_MAKE_PATH)/tweak.mk
BUNDLE_NAME := M3gaAppCustomizerPrefs
M3gaAppCustomizerPrefs_FILES := Preferences/M3GAppCustomizerPrefs.m
M3gaAppCustomizerPrefs_INSTALL_PATH := /Library/PreferenceBundles
M3gaAppCustomizerPrefs_RESOURCE_FILES := Preferences/Root.plist Preferences/Instructions.plist Preferences/About.plist Preferences/Info.plist
M3gaAppCustomizerPrefs_FRAMEWORKS := UIKit Foundation CoreGraphics
M3gaAppCustomizerPrefs_PRIVATE_FRAMEWORKS := Preferences MobileCoreServices
M3gaAppCustomizerPrefs_CFLAGS := -fno-objc-arc -Wno-deprecated-declarations
include $(THEOS_MAKE_PATH)/bundle.mk
include $(THEOS_MAKE_PATH)/package.mk
