TARGET := iphone:clang:9.3:6.0
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := M3gaSignalBars
M3gaSignalBars_FILES := Tweak.m
M3gaSignalBars_FRAMEWORKS := UIKit Foundation CoreFoundation
M3gaSignalBars_LIBRARIES := substrate
M3gaSignalBars_CFLAGS := -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME := M3gaSignalBarsPrefs
M3gaSignalBarsPrefs_FILES := Preferences/M3GPrefsControllers.m
M3gaSignalBarsPrefs_INSTALL_PATH := /Library/PreferenceBundles
M3gaSignalBarsPrefs_RESOURCE_FILES := Preferences/Info.plist Preferences/Root.plist Preferences/Instructions.plist Preferences/About.plist
M3gaSignalBarsPrefs_FRAMEWORKS := UIKit Foundation
M3gaSignalBarsPrefs_PRIVATE_FRAMEWORKS := Preferences
M3gaSignalBarsPrefs_CFLAGS := -fno-objc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
include $(THEOS_MAKE_PATH)/package.mk
