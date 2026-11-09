#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface M3gaNoBadgesListController : PSListController
@end

@implementation M3gaNoBadgesListController
- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
    }
    return _specifiers;
}
@end
