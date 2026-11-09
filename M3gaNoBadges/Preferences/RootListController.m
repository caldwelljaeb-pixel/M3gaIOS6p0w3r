// Theos' modern Preferences headers use API_AVAILABLE, which is absent
// from the legacy iOS 9.3 SDK headers used for this ARMv7/iOS 6 build.
// Availability annotations are compile-time-only, so safely ignore them
// when the legacy SDK does not define the macro.
#ifndef API_AVAILABLE
#define API_AVAILABLE(...)
#endif

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
