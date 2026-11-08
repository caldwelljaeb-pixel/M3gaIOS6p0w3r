# iOS 6-compatible plist-only preferences; no executable PreferenceBundle required.
TARGET := iphone:clang:9.3:6.0
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := M3gaGravity
M3gaGravity_FILES := Tweak.x
M3gaGravity_FRAMEWORKS := UIKit Foundation QuartzCore CoreFoundation
M3gaGravity_CFLAGS := -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/package.mk
