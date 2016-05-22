#import <AudioToolbox/AudioToolbox.h>
#import "SpringBoard/SBUIController.h"
#import <SpringBoard/SBBacklightController.h>
#import <SpringBoard/SBDeviceLockController.h>
#import <SpringBoard/SBLockScreenManager.h>
#import <SpringBoardUIServices/SBUIBiometricEventMonitor.h>
#import <BiometricKit/BiometricKit.h>
#import <SpringBoard/SBReachabilityTrigger.h>
#import <SpringBoardUI/SBUISound.h>
#import <SpringBoard/SBSoundController.h>
#import <SpringBoard/SBUserAgent.h>
#import <AccessibilityUtilities/AXSpringBoardServer.h>
#import <SpringBoard/SBControlCenterController.h>
#import <SpotlightUI/SPUISearchViewController.h>

#import "Header.h"

#import <Preferences/PSAssistiveTouchSettingsDetail.h>

#import <float.h>

%hook SBReachabilityManager
- (void)_toggleReachabilityModeWithRequestingObserver:(id)arg1
{
}

%end

%hook SBUIBiometricEventMonitor

/* prevent touchID sensor from being powered off when device is locked */
- (void)noteScreenDidTurnOff {
}
- (void)noteScreenWillTurnOff {
}

%end

@implementation TouchUnlockController

static NSLock *mutex;
static TouchUnlockController *instance;

_Bool secondTap;
_Bool secondTapDisplayed;
static NSLock *lock;
static NSLock *timeLock;
NSDate *runTime;
double runTimeDouble;

-(unsigned long long int)processTapping
{

	NSDate *now = [NSDate date];
	double nowTime = [now timeIntervalSinceReferenceDate];
	bool notTimeToRunYet = NO;
	[lock lock];
	if (nowTime < runTimeDouble)
		notTimeToRunYet = YES;
	[lock unlock];

	// do not run if not scheudle time yet
	if (notTimeToRunYet)
		return 0;


	[lock lock];
	NSUInteger tapNum = _currentTapNum;
	_currentTapNum = 0;
	runTimeDouble = DBL_MAX;
	runTime = nil;
	[lock unlock];

	// dont do anthing for first tap id double tap
	if (tapNum == 3)
	{
		bool assistiveTouchEnabled = [%c(PSAssistiveTouchSettingsDetail) isEnabled];
		if (assistiveTouchEnabled)
			[%c(PSAssistiveTouchSettingsDetail) setEnabled:NO];
		else
			[%c(PSAssistiveTouchSettingsDetail) setEnabled:YES];
		return 0;
	} // end if, triple tap cases

	else if (tapNum == 2)
	{

			/* Second tap and hold */
			BOOL fingerOn = [[%c(SBUIBiometricEventMonitor) sharedInstance] isFingerOn];
			id lockScreen = [%c(SBLockScreenManager) sharedInstance];
			_Bool locked =  MSHookIvar<_Bool>(lockScreen, "_isUILocked");
			if (fingerOn && !locked)
				[[%c(AXSpringBoardServer) server] openSiri];

			
			// not displayed, continue
			secondTapDisplayed = YES;

			/* Second tap only */
			[[%c(SBUIController) sharedInstance]handleMenuDoubleTap];
	} // end if, double tap cases

	/* single tap case below */
	else if (tapNum == 1)
	{
		
		/* single tap and hold */
		bool canLock = [self canDeviceBeLocked];
		BOOL isFingerOn = [[%c(SBUIBiometricEventMonitor) sharedInstance] isFingerOn];
		if (isFingerOn && canLock)
		{
			id lockScreen = [%c(SBLockScreenManager) sharedInstance];
			_Bool locked =  MSHookIvar<_Bool>(lockScreen, "_isUILocked");

			if (!locked)
				[[%c(SBUserAgent) sharedUserAgent] lockAndDimDevice];
		} // single tap and hold

		/* single tap only */
		else
		{
			
			[[%c(SBUIController) sharedInstance]clickedMenuButton];

			/* find out if displaying special view */
			/* view that home button method called does not work as expected*/
			id server = [%c(AXSpringBoardServer) server];

			/* Special View : Siri */
			BOOL siriOn = [server isSiriVisible];

			/* Special View : Notification Center */
			BOOL notficationVisible = [server isNotificationCenterVisible];

			/* Special View : Control Center */
			BOOL controlCenterVisible = [server isControlCenterVisible];

			/* Special View : Spotlight */
			id spotlightViewController = [%c(SPUISearchViewController) sharedInstance];
			bool spotlightVisible = [spotlightViewController isVisible];

			/* dismiss special views */
			if (siriOn)
				[server dismissSiri];
			else if (notficationVisible)
				[server hideNotificationCenter];
			else if (controlCenterVisible)
				[[%c(SBControlCenterController) sharedInstance] dismissAnimated:YES];
			else if (spotlightVisible)
				[spotlightViewController dismissAnimated:YES completionBlock:nil];


		} // end if, single tap only
	} // single tap cases end

	return 0;
} // end method processTapping


-(void) setInstance:(id)arg1
{
	instance = arg1;
}


+(id) sharedInstance
{
	return instance;
}

-(void)vibrate
{
	int duration = 30;

	// Create your vibration
	SBUISound *sound = [[%c(SBUISound) alloc] init];
	sound.repeats = NO;
	sound.systemSoundID = 0;

	// Create an array for your vibration pattern
	NSMutableArray* vibrationPatternArray = [[NSMutableArray alloc] init];

	// Create your vibration pattern

	// Vibrate for duration specified
	[vibrationPatternArray addObject:@(YES)];
	[vibrationPatternArray addObject:@(duration)];

	// Create a dict to hold vibration pattern and the intensity of the vibration
	NSMutableDictionary* vibrationPatternDict = [[NSMutableDictionary alloc] init];

	[vibrationPatternDict setObject:vibrationPatternArray forKey:@"VibePattern"];
	[vibrationPatternDict setObject:@(1) forKey:@"Intensity"];

	sound.vibrationPattern = vibrationPatternDict;

	// Actually play the vibration
	[(SBSoundController *)[%c(SBSoundController) sharedInstance] _playSystemSound:sound];

	// Clean up
	[vibrationPatternArray release];
	[vibrationPatternDict release];
	[sound release];

}

-(void)biometricEventMonitor: (id)monitor handleBiometricEvent: (unsigned)event
{
/*
	NSDate *mydate = [NSDate date];
	NSTimeInterval secondsInEightHours = 0.1;
	NSDate *dateEightHoursAhead = [mydate dateByAddingTimeInterval:secondsInEightHours];
	[dateEightHoursAhead dateByAddingTimeInterval:secondsInEightHours];
*/


	if (event == 1)
	{
		[self vibrate];

		// light up screen from sleep
		id lockScreen = [%c(SBLockScreenManager) sharedInstance];
		_Bool locked =  MSHookIvar<_Bool>(lockScreen, "_isUILocked");
		if (locked)
			[[%c(SBBacklightController) sharedInstance] turnOnScreenFullyWithBacklightSource:0];
	}

	// event 2 finger held, event 4 finger matched, 10 not matched
	// only lock device after a period passed since last unlock
	if ( event == 4 || event == 10 )
	{

		[self deviceCanLockNow:NO];

		double delayInSeconds = 0.8;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);

		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[self deviceCanLockNow:YES];
		});


	}

	if (event == 1)
	{
		double delayInSeconds = 0.2;
		NSDate *nowDate = [NSDate date];
		
		// reset
		[lock lock];
		runTimeDouble = [nowDate timeIntervalSinceReferenceDate] + delayInSeconds;
		_currentTapNum = _currentTapNum + 1;
		secondTap = NO;
		secondTapDisplayed = NO;
		[lock unlock];

		dispatch_time_t now = DISPATCH_TIME_NOW;
		dispatch_time_t popTime = dispatch_time(now, delayInSeconds * NSEC_PER_SEC);

		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		       [self processTapping];
		});
	}


} // end method biometricEventMonitor

-(void)startMonitoringEvents
{
	id monitor = [%c(SBUIBiometricEventMonitor) sharedInstance];
	[[%c(BiometricKit) manager] setDelegate:monitor];
	[monitor addObserver:self];
	[monitor _setMatchingEnabled:YES];
	[monitor _startMatching];
}

-(void) deviceCanLockNow : (bool)can
{
    [mutex lock];
    _canLock = can;
    [mutex unlock];
}

-(void) displayMsg : (NSString*) str
{
        NSString *msg = str;
	NSString *title = @"title";
	NSString *cancel = @"OK";
	UIAlertView *a = [[UIAlertView alloc] initWithTitle:title
        message:msg delegate:nil cancelButtonTitle:cancel otherButtonTitles:nil];
        [a show];
        [a release];
}

-(bool) canDeviceBeLocked
{
	[mutex lock];
	bool result = _canLock;
	[mutex unlock];
	return result;
}

/* 2 mutex locks used for multi thread data race preventation */
-(void) initVar
{
	mutex = [NSLock new];
	_isUnlocking = NO;
	_canLock = YES;

	lock = [NSLock new];
	secondTapDisplayed = NO;
	secondTap = NO;
	_currentTapNum = 0;

	timeLock = [NSLock new];
}

@end

%ctor
{
	TouchUnlockController *unlockController = [[TouchUnlockController alloc] init];
	[unlockController initVar];
	[unlockController startMonitoringEvents];
	unlockController.instance = unlockController;
}

/*
        NSString *msg = [NSString stringWithFormat:@"Number of Tap : %llu", currentNumTap];
	NSString *title = @"title";
	NSString *cancel = @"OK";
	UIAlertView *a = [[UIAlertView alloc] initWithTitle:title
        message:msg delegate:nil cancelButtonTitle:cancel otherButtonTitles:nil];
        [a show];
        [a release];
*/
