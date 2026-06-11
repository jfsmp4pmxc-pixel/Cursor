# Đổi target thành phiên bản iOS thấp để tối ưu thiết bị cũ, dùng clang biên dịch chéo
TARGET := iphone:clang:14.5:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CursorBeta

CursorBeta_FILES = Tweak.x
CursorBeta_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk