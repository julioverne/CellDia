include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CellDia
CellDia_FILES = /mnt/d/codes/celldia/celldia.xm
CellDia_FRAMEWORKS = CydiaSubstrate Foundation CoreGraphics UIKit CoreImage
CellDia_PRIVATE_FRAMEWORKS = StoreKitUI
CellDia_LDFLAGS = -Wl,-segalign,4000

export ARCHS = armv7 arm64
CellDia_ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/tweak.mk
	
	
all::
	