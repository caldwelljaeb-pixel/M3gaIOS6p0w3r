#import <Foundation/Foundation.h>

// EXPERIMENTAL Doodle Jump 1.26 test.
// Candidate: PowerUpObject type 0. Its tick logic contains a rocket-related
// shouldShakeRocket: call near the low-fuel threshold. This is a clue, not
// proof that type 0 is the jetpack.

@interface PowerUpObject : NSObject
- (int)objType;
- (int)objFuel;
- (void)setObjFuel:(int)fuel;
- (void)tick;
@end

%group DoodleJump126Experimental

%hook PowerUpObject
- (void)tick {
    %orig;

    // Experimental candidate: restore type 0 fuel when it runs out.
    if ([self objType] == 0 && [self objFuel] <= 0) {
        [self setObjFuel:180];
    }
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
