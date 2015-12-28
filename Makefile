ARCHS = arm64 armv7
include theos/makefiles/common.mk

TWEAK_NAME = touchoriginal
touchoriginal_FILES = Tweak.xm
touchoriginal_FRAMEWORKS = UIKit AudioToolbox 

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
