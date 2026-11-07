#import <Preferences/PSListController.h>
#import <UIKit/UIKit.h>
@interface M3gaStatusBarColorController : PSListController
- (void)openCreatorPage;
@end
@implementation M3gaStatusBarColorController
- (NSArray *)specifiers {
 if (!_specifiers) _specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
 return _specifiers;
}
- (void)openCreatorPage {
 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/caldwelljaeb-pixel"]];
}
@end
