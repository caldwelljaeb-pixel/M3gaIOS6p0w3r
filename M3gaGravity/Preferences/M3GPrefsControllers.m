#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

/*
 * Preferences is a private iOS framework. Declare only the small surface
 * used here so the project does not depend on newer private SDK headers
 * that contain API availability macros missing from the iOS 9.3 SDK.
 */
@interface PSListController : UIViewController
- (NSArray *)loadSpecifiersFromPlistName:(NSString *)name target:(id)target;
@end

@interface M3GInstructionsController : PSListController {
    NSArray *_m3gInstructionSpecifiers;
}
@end

@implementation M3GInstructionsController

- (NSArray *)specifiers {
    if (!_m3gInstructionSpecifiers) {
        _m3gInstructionSpecifiers =
            [[self loadSpecifiersFromPlistName:@"Instructions" target:self] retain];
    }
    return _m3gInstructionSpecifiers;
}

@end

@interface M3GAboutController : PSListController {
    NSArray *_m3gAboutSpecifiers;
}
- (void)openCreatorPage;
@end

@implementation M3GAboutController

- (NSArray *)specifiers {
    if (!_m3gAboutSpecifiers) {
        _m3gAboutSpecifiers =
            [[self loadSpecifiersFromPlistName:@"About" target:self] retain];
    }
    return _m3gAboutSpecifiers;
}

- (void)openCreatorPage {
    NSURL *creatorURL = [NSURL URLWithString:@"https://github.com/caldwelljaeb-pixel"];
    if (creatorURL) {
        [[UIApplication sharedApplication] openURL:creatorURL];
    }
}

@end
