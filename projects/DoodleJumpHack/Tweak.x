#import <Foundation/Foundation.h>

// Doodle Jump 1.26 (com.yourcompany.DoodleJump)
// The hook is enabled only when the running app reports version 1.26.
//
// Static analysis of the supplied ARMv7 executable identified:
//   PowerUpObject type 0 = jetpack
//   objFuel is an int, initialized to 180 for type 0
//
// The game checks objFuel through its getter before ending a boost.
// When a type-0 power-up reaches zero fuel, refill it to the original
// 180-frame value. Other power-up types are not modified.

@interface PowerUpObject : NSObject
- (int)objType;
- (int)objFuel;
- (void)setObjFuel:(int)fuel;
@end

%group DoodleJump126

%hook PowerUpObject

- (int)objFuel {
    int fuel = %orig;

    if ([self objType] == 0 && fuel <= 0) {
        [self setObjFuel:180];
        return 180;
    }

    return fuel;
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
