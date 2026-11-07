#import <Foundation/Foundation.h>

// Doodle Jump 1.26 (com.yourcompany.DoodleJump)
// Static analysis of its ARMv7 executable identifies:
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
