TARGET := iphone:clang:latest:6.0
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := M3gaGravity
M3gaGravity_FILES := Tweak.x
M3gaGravity_FRAMEWORKS := UIKit QuartzCore
M3gaGravity_CFLAGS := -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/package.mk
