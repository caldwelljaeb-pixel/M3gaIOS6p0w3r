#import <Preferences/PSListController.h>

@interface M3gaSignalBarsController : PSListController
@end

@implementation M3gaSignalBarsController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
    }
    return _specifiers;
}

@end
