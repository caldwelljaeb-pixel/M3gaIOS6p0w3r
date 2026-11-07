#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Preferences/PSListController.h>

@interface M3GRootListController : PSListController {
    NSArray *_m3gSpecifiers;
}
@end

@implementation M3GRootListController

- (NSArray *)specifiers {
    if (!_m3gSpecifiers) {
        _m3gSpecifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _m3gSpecifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    [super setPreferenceValue:value specifier:specifier];

    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.m3ga.m3gagravity/preferences.changed"),
        NULL,
        NULL,
        YES
    );
}

@end
