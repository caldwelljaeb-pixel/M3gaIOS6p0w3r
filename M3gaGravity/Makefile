TARGET := iphone:clang:9.3:6.0
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := M3gaGravity
M3gaGravity_FILES := Tweak.x
M3gaGravity_FRAMEWORKS := UIKit Foundation QuartzCore CoreFoundation
M3gaGravity_CFLAGS := -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME := M3gaGravityPrefs
M3gaGravityPrefs_FILES := M3GRootListController.m
M3gaGravityPrefs_INSTALL_PATH := /Library/PreferenceBundles
M3gaGravityPrefs_BUNDLE_EXTENSION := bundle
M3gaGravityPrefs_FRAMEWORKS := UIKit Foundation CoreFoundation
M3gaGravityPrefs_PRIVATE_FRAMEWORKS := Preferences
M3gaGravityPrefs_RESOURCE_DIRS := M3gaGravityPrefs/Resources
M3gaGravityPrefs_CFLAGS := -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
include $(THEOS_MAKE_PATH)/package.mk
