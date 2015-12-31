#import <AudioToolbox/AudioToolbox.h>
#import "SpringBoard/SBUIController.h"
#import <SpringBoard/SBBacklightController.h>
#import <SpringBoard/SBDeviceLockController.h>
#import <SpringBoard/SBLockScreenManager.h>
#import <SpringBoardUIServices/SBUIBiometricEventMonitor.h>
#import <BiometricKit/BiometricKit.h>


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

@interface TouchUnlockController : NSObject
@end

@implementation TouchUnlockController

-(void)biometricEventMonitor: (id)monitor handleBiometricEvent: (unsigned)event
{
	// event 2 finger held, event 4 finger matched, 10 not matched
	if (event == 0 || event == 1 || event == 2 || event == 4 || event == 10)
		[[%c(SBBacklightController) sharedInstance] turnOnScreenFullyWithBacklightSource:0];

}

-(void)startMonitoringEvents
{
	id monitor = [%c(SBUIBiometricEventMonitor) sharedInstance];
	[[%c(BiometricKit) manager] setDelegate:monitor];
	[monitor addObserver:self];
	[monitor _setMatchingEnabled:YES];
	[monitor _startMatching];
}

@end

%ctor
{
   TouchUnlockController *unlockController = [[TouchUnlockController alloc] init];
   [unlockController startMonitoringEvents];
}
