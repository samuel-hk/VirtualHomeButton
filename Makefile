ARCHS = arm64 armv7
include theos/makefiles/common.mk

TWEAK_NAME = virtualtouchhome
virtualtouchhome_FILES = Tweak.xm
virtualtouchhome_FRAMEWORKS = UIKit AudioToolbox 
virtualtouchhome_FRAMEWORKS = UIKit AudioToolbox 
virtualtouchhome_PRIVATE_FRAMEWORKS = BiometricKit GraphicsServices

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
