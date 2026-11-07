#import <Foundation/Foundation.h>

// EXPERIMENTAL Doodle Jump 1.26 test.
// Candidate: PowerUpObject type 0. The binary's tick method decrements fuel
// and can change a non-type-2 object's type when that decrement reaches zero.
// Refuel immediately BEFORE the original tick so the transition is prevented.
// Type 0 remains a candidate, not a confirmed jetpack mapping.

@interface PowerUpObject : NSObject
- (int)objType;
- (int)objFuel;
- (void)setObjFuel:(int)fuel;
- (void)tick;
@end

%group DoodleJump126Experimental

%hook PowerUpObject
- (void)tick {
    // In the original ARMv7 tick method, fuel is decremented and the
    // zero-fuel transition is handled in the same call. Refill at 1 or less
    // before %orig, so the original method never sees a zero-producing tick.
    if ([self objType] == 0 && [self objFuel] <= 1) {
        [self setObjFuel:180];
    }

    %orig;
}
%end
%end

%ctor {
    @autoreleasepool {
        NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        if ([appVersion isEqualToString:@"1.26"]) {
            %init(DoodleJump126Experimental);
        }
    }
}
