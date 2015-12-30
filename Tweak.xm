#import <AudioToolbox/AudioToolbox.h>
#import "SpringBoard/SBUIController.h"
//#import <SpringBoard/SBUIController.h>

@interface SBReachabilityTrigger
- (void)_debounce;
@end

%hook SBReachabilityTrigger
- (void)_debounce
{
	[[%c(SBUIController) sharedInstance]clickedMenuButton];
	%orig;
}
%end

%hook SBUIBiometricEventMonitor

//If either of these methods are enabled, they prevent touchID events from being sent to
//the touch unlock controller while the device is locked and a passcode isn't enabled.
//So, we make them do nothing if the device doesn't have a passcode, so this tweak can work.
- (void)noteScreenDidTurnOff {
}
- (void)noteScreenWillTurnOff {
}

%end
