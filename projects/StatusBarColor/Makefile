THEOS_DEVICE_IP = 127.0.0.1
TARGET := iphone:clang:6.1:6.0
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = M3gaStatusBarColor
M3gaStatusBarColor_FILES = Tweak.x
M3gaStatusBarColor_FRAMEWORKS = UIKit
M3gaStatusBarColor_CFLAGS = -Wno-deprecated-declarations

BUNDLE_NAME = M3gaStatusBarColorPrefs
M3gaStatusBarColorPrefs_FILES = Preferences/M3gaStatusBarColorController.m
M3gaStatusBarColorPrefs_INSTALL_PATH = /Library/PreferenceBundles
M3gaStatusBarColorPrefs_FRAMEWORKS = UIKit
M3gaStatusBarColorPrefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard || true"
