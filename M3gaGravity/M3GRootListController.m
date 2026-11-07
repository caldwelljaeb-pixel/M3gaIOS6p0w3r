#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

// Preferences is a private iOS framework; its SDK stub is linked by Theos,
// while these small interfaces keep the project independent of private headers.
@interface PSSpecifier : NSObject
@property(nonatomic, readonly) NSDictionary *properties;
@end

@interface PSListController : UIViewController
- (NSArray *)loadSpecifiersFromPlistName:(NSString *)name target:(id)target;
@end

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

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *domain = [specifier.properties objectForKey:@"defaults"];
    NSString *key = [specifier.properties objectForKey:@"key"];
    NSString *path = [NSString stringWithFormat:
        @"/var/mobile/Library/Preferences/%@.plist", domain];

    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:path];
    id value = [settings objectForKey:key];
    return value ?: [specifier.properties objectForKey:@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *domain = [specifier.properties objectForKey:@"defaults"];
    NSString *key = [specifier.properties objectForKey:@"key"];
    NSString *path = [NSString stringWithFormat:
        @"/var/mobile/Library/Preferences/%@.plist", domain];

    NSMutableDictionary *settings =
        [NSMutableDictionary dictionaryWithContentsOfFile:path];
    if (!settings) settings = [NSMutableDictionary dictionary];

    if (key && value) [settings setObject:value forKey:key];

    [[NSFileManager defaultManager] createDirectoryAtPath:
        @"/var/mobile/Library/Preferences"
        withIntermediateDirectories:YES
        attributes:nil
        error:NULL];
    [settings writeToFile:path atomically:YES];

    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.m3ga.m3gagravity/preferences.changed"),
        NULL,
        NULL,
        YES
    );
}

@end
