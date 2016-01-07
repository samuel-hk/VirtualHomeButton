ARCHS = arm64 armv7
include theos/makefiles/common.mk

TWEAK_NAME = TapID
TapID_FILES = Tweak.xm
TapID_FRAMEWORKS = UIKit AudioToolbox
TapID_FRAMEWORKS = UIKit AudioToolbox
TapID_PRIVATE_FRAMEWORKS = BiometricKit GraphicsServices

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
