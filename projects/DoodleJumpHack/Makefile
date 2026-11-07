TARGET := iphone:clang:9.3:6.0
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DoodleJumpHack
DoodleJumpHack_FILES = Tweak.x
DoodleJumpHack_FRAMEWORKS = Foundation
DoodleJumpHack_CFLAGS = -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk
