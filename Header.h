@interface TouchUnlockController : NSObject
-(void) vibrate;
-(void) initVar;

@property (getter=isUnlockingNow) BOOL isUnlocking;

@property BOOL canLock;
-(void) deviceCanLockNow : (bool)can;
-(bool) canDeviceBeLocked;

@end
