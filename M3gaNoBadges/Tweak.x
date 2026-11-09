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

// On iOS 6, SBIconController is the SBIconView delegate that decides
// whether an icon view should display its badge. Hook this decision
// instead of SBIcon, which does not own this iOS 6 display callback.
%hook SBIconController
- (BOOL)iconViewDisplaysBadges:(id)iconView {
    if (M3GAHideBadges) return NO;
    return %orig;
}
%end

%ctor {
    M3GALoadPreferences();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
                                    M3GAPreferencesChanged, M3GAChanged, NULL,
                                    CFNotificationSuspensionBehaviorCoalesce);
}
