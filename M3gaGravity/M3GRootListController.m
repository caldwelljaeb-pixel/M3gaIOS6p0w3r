#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>

@interface PSSpecifier : NSObject
@property(nonatomic, readonly) NSDictionary *properties;
@end

@interface PSListController : UIViewController
- (NSArray *)loadSpecifiersFromPlistName:(NSString *)name target:(id)target;
@end

@interface M3GRootListController : PSListController
@end

@implementation M3GRootListController {
    NSArray *_m3gSpecifiers;
}

- (NSArray *)specifiers {
    if (!_m3gSpecifiers) {
        _m3gSpecifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _m3gSpecifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:
        @"/var/mobile/Library/Preferences/com.m3ga.m3gagravity.plist"];
    NSString *key = [specifier.properties objectForKey:@"key"];
    id value = [settings objectForKey:key];
    return value ?: [specifier.properties objectForKey:@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *path = @"/var/mobile/Library/Preferences/com.m3ga.m3gagravity.plist";
    NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    if (!settings) settings = [NSMutableDictionary dictionary];

    NSString *key = [specifier.properties objectForKey:@"key"];
    if (key && value) [settings setObject:value forKey:key];

    [[NSFileManager defaultManager] createDirectoryAtPath:
        @"/var/mobile/Library/Preferences"
        withIntermediateDirectories:YES
        attributes:nil
        error:NULL];
    [settings writeToFile:path atomically:YES];

    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.m3ga.m3gagravity/preferences.changed"), NULL, NULL, YES);
}

@end
