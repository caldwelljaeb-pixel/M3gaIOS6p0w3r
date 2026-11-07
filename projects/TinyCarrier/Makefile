TARGET := iphone:clang:6.1:6.0
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TinyCarrier
TinyCarrier_FILES = Tweak.xm
TinyCarrier_CFLAGS = -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk
