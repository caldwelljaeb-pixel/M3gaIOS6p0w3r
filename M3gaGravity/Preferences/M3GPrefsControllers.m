#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Preferences/PSListController.h>

@interface M3GInstructionsController : PSListController
@end

@implementation M3GInstructionsController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"Instructions" target:self] retain];
    }
    return _specifiers;
}

@end

@interface M3GAboutController : PSListController
- (void)openCreatorPage;
@end

@implementation M3GAboutController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"About" target:self] retain];
    }
    return _specifiers;
}

- (void)openCreatorPage {
    NSURL *creatorURL = [NSURL URLWithString:@"https://github.com/caldwelljaeb-pixel"];
    if (creatorURL) {
        [[UIApplication sharedApplication] openURL:creatorURL];
    }
}

@end
