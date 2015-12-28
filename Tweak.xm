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
	AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
	%orig;
}
%end
