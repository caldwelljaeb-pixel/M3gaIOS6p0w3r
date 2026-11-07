#import <Foundation/Foundation.h>

// EXPERIMENTAL Doodle Jump 1.26 test.
// Candidate: PowerUpObject type 2. This is a hypothesis, not a confirmed
// jetpack mapping. Type 2 initializes with 600 fuel in the inspected binary.

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

    // Experimental candidate: keep type 2 fueled.
    if ([self objType] == 2 && [self objFuel] <= 0) {
        [self setObjFuel:600];
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
