include theos/makefiles/common.mk

TWEAK_NAME = CellDia
CellDia_FILES = celldia.xm
CellDia_FRAMEWORKS = CydiaSubstrate Foundation CoreGraphics UIKit CoreImage

CellDia_LDFLAGS = -Wl,-segalign,4000

export ARCHS = armv7 arm64
CellDia_ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/tweak.mk
	
	
all::
	@echo "[+] Copying Files..."
	@cp ./obj/obj/debug/CellDia.dylib //Library/MobileSubstrate/DynamicLibraries/CellDia.dylib
	@/usr/bin/ldid -S //Library/MobileSubstrate/DynamicLibraries/CellDia.dylib
	@echo "DONE"
	#@killall SpringBoard
	