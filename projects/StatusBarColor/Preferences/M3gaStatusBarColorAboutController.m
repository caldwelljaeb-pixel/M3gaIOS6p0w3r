#import <Preferences/PSListController.h>
#import <UIKit/UIKit.h>

@interface M3gaStatusBarColorAboutController : PSListController
- (void)openCreatorPage;
@end

@implementation M3gaStatusBarColorAboutController
- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"About" target:self] retain];
    }
    return _specifiers;
}
- (void)openCreatorPage {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/caldwelljaeb-pixel"]];
}
@end