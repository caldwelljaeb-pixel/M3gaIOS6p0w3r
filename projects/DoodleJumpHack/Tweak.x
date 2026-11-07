#import <Foundation/Foundation.h>

// Doodle Jump 1.26 (com.yourcompany.DoodleJump)
// The hook is enabled only when the running app reports version 1.26.
//
// Reverse-engineering notes:
// PowerUpObject stores its active power-up type and fuel in ivars.
// Type 0 initializes with 180 frames of fuel. The tick method reads
// the fuel ivar directly, so the tweak checks it after the original
// tick completes and restores the fuel only if the type-0 object ran out.

@interface PowerUpObject : NSObject
- (int)objType;
- (int)objFuel;
- (void)setObjFuel:(int)fuel;
- (void)tick;
@end

%group DoodleJump126

%hook PowerUpObject

- (void)tick {
    %orig;

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
            %init(DoodleJump126);
        }
    }
}
