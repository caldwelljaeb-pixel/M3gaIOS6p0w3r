TARGET := iphone:clang:9.3:6.0
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME := M3gaEmojiVault
M3gaEmojiVault_FILES := main.m
M3gaEmojiVault_FRAMEWORKS := UIKit Foundation QuartzCore
M3gaEmojiVault_RESOURCE_FILES := Emoji.tsv
M3gaEmojiVault_INFOPLIST := Info.plist
M3gaEmojiVault_CFLAGS := -fno-objc-arc -Wno-deprecated-declarations
M3gaEmojiVault_INSTALL_PATH := /Applications

include $(THEOS_MAKE_PATH)/application.mk
include $(THEOS_MAKE_PATH)/package.mk
