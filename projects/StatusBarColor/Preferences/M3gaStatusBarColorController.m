#import <Preferences/PSListController.h>

@interface M3gaStatusBarColorController : PSListController
@end

@implementation M3gaStatusBarColorController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
    }
    return _specifiers;
}

@end
