# iOS 6-compatible plist-only main pane plus a small bundle for the two linked subpages.
TARGET := iphone:clang:9.3:6.0
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := M3gaGravity
M3gaGravity_FILES := Tweak.x
M3gaGravity_FRAMEWORKS := UIKit Foundation QuartzCore CoreFoundation
M3gaGravity_CFLAGS := -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME := M3gaGravityPrefs
M3gaGravityPrefs_FILES := Preferences/M3GPrefsControllers.m
M3gaGravityPrefs_INSTALL_PATH := /Library/PreferenceBundles
M3gaGravityPrefs_RESOURCE_FILES := Preferences/Instructions.plist Preferences/About.plist
M3gaGravityPrefs_FRAMEWORKS := UIKit Foundation
M3gaGravityPrefs_PRIVATE_FRAMEWORKS := Preferences
M3gaGravityPrefs_CFLAGS := -fno-objc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
include $(THEOS_MAKE_PATH)/package.mk
