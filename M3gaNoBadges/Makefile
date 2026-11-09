TARGET := iphone:clang:9.3:6.0
ARCHS := armv7
include $(THEOS)/makefiles/common.mk

TWEAK_NAME := M3gaNoBadges
M3gaNoBadges_FILES := Tweak.x
M3gaNoBadges_FRAMEWORKS := Foundation
M3gaNoBadges_CFLAGS := -fobjc-arc -Wno-deprecated-declarations
include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME := M3gaNoBadgesPrefs
M3gaNoBadgesPrefs_FILES := Preferences/RootListController.m
M3gaNoBadgesPrefs_INSTALL_PATH := /Library/PreferenceBundles
M3gaNoBadgesPrefs_RESOURCE_FILES := Preferences/Root.plist Preferences/Info.plist
M3gaNoBadgesPrefs_FRAMEWORKS := UIKit Foundation
M3gaNoBadgesPrefs_PRIVATE_FRAMEWORKS := Preferences
M3gaNoBadgesPrefs_CFLAGS := -fno-objc-arc -Wno-deprecated-declarations
include $(THEOS_MAKE_PATH)/bundle.mk

include $(THEOS_MAKE_PATH)/package.mk
