#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <substrate.h>

static NSString * const M3GAPreferencesPath = @"/var/mobile/Library/Preferences/com.m3ga.nobadges.plist";
static CFStringRef const M3GAChanged = CFSTR("com.m3ga.nobadges/preferences.changed");
static BOOL M3GAHideBadges = YES;

static void M3GALoadPreferences(void) {
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:M3GAPreferencesPath];
    id value = [settings objectForKey:@"Enabled"];
    M3GAHideBadges = value ? [value boolValue] : YES;
}

static void M3GAPreferencesChanged(CFNotificationCenterRef center, void *observer,
                                   CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    M3GALoadPreferences();
}

%hook SBIcon
- (id)badgeNumberOrString {
    if (M3GAHideBadges) return nil;
    return %orig;
}
%end

%ctor {
    M3GALoadPreferences();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
                                    M3GAPreferencesChanged, M3GAChanged, NULL,
                                    CFNotificationSuspensionBehaviorCoalesce);
}
