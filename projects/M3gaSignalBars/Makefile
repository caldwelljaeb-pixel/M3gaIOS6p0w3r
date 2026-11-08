TARGET := iphone:clang:9.3:6.0
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := M3gaSignalBars
M3gaSignalBars_FILES := Tweak.x
M3gaSignalBars_FRAMEWORKS := Foundation
M3gaSignalBars_CFLAGS := -fblocks -Wno-deprecated-declarations

BUNDLE_NAME := M3gaSignalBarsPrefs
M3gaSignalBarsPrefs_FILES := Preferences/M3gaSignalBarsController.m
M3gaSignalBarsPrefs_RESOURCE_FILES := Preferences/Root.plist
M3gaSignalBarsPrefs_INSTALL_PATH := /Library/PreferenceBundles
M3gaSignalBarsPrefs_FRAMEWORKS := UIKit Foundation
M3gaSignalBarsPrefs_PRIVATE_FRAMEWORKS := Preferences
M3gaSignalBarsPrefs_INFOPLIST := Info.plist

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk
include $(THEOS_MAKE_PATH)/package.mk
