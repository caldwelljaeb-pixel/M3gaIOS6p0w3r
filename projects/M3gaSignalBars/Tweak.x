#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dispatch/dispatch.h>

// iOS 6.0/6.1 SpringBoard private API declarations.
// Verified against the iOS 6.1 SBTelephonyManager runtime header.
@interface SBTelephonyManager : NSObject
+ (id)sharedTelephonyManager;
- (long)signalStrength;
- (long)signalStrengthBars;
- (void)_setSignalStrength:(long)strength andBars:(long)bars;
- (void)_updateState;
- (void)updateSpringBoard;
@end

#define M3G_SIGNAL_PREFS @"/var/mobile/Library/Preferences/com.m3ga.m3gasignalbars.plist"
#define M3G_SIGNAL_CHANGED "com.m3ga.m3gasignalbars/preferences.changed"

static BOOL M3GSignalBarsEnabled = NO;
static BOOL M3GHasRealSignalSnapshot = NO;
static long M3GLastRealSignalStrength = 0;
static long M3GLastRealSignalBars = 0;

static BOOL M3GReadEnabledPreference(void) {
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:M3G_SIGNAL_PREFS];
    id value = [preferences objectForKey:@"Enabled"];
    // Missing preferences always mean OFF.
    return value ? [value boolValue] : NO;
}

static void M3GSignalBarsPreferencesChanged(CFNotificationCenterRef center,
                                             void *observer,
                                             CFStringRef name,
                                             const void *object,
                                             CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        M3GSignalBarsEnabled = M3GReadEnabledPreference();

        Class managerClass = objc_getClass("SBTelephonyManager");
        id manager = nil;
        if (managerClass && [managerClass respondsToSelector:@selector(sharedTelephonyManager)]) {
            manager = [managerClass sharedTelephonyManager];
        }
        if (!manager) return;

        if (M3GSignalBarsEnabled) {
            // Ask SpringBoard to refresh. The hooked setter will keep the
            // native indicator at five bars while preserving the real reading.
            [manager _updateState];
        } else if (M3GHasRealSignalSnapshot) {
            // Restore the last real modem reading when the user switches off.
            [manager _setSignalStrength:M3GLastRealSignalStrength
                                  andBars:M3GLastRealSignalBars];
        } else {
            [manager _updateState];
        }

        [manager updateSpringBoard];
    });
}

%group M3GSignalBarsSpringBoard

%hook SBTelephonyManager

- (long)signalStrength {
    long realStrength = %orig;
    M3GLastRealSignalStrength = realStrength;
    M3GHasRealSignalSnapshot = YES;
    return realStrength;
}

- (long)signalStrengthBars {
    long realBars = %orig;

    // Only update the saved real value while disabled. Once enabled, the
    // manager's cached display value may be five, so do not save that as real.
    if (!M3GSignalBarsEnabled) {
        M3GLastRealSignalBars = realBars;
        M3GHasRealSignalSnapshot = YES;
    }

    return M3GSignalBarsEnabled ? 5 : realBars;
}

- (void)_setSignalStrength:(long)strength andBars:(long)bars {
    // Save the untouched modem values before changing only the displayed
    // bar count. The carrier, registration state, and data connection remain
    // controlled by iOS and the modem.
    M3GLastRealSignalStrength = strength;
    M3GLastRealSignalBars = bars;
    M3GHasRealSignalSnapshot = YES;

    if (M3GSignalBarsEnabled) {
        %orig(strength, 5);
    } else {
        %orig;
    }
}

%end

%end

%ctor {
    @autoreleasepool {
        NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
        if ([bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
            M3GSignalBarsEnabled = M3GReadEnabledPreference();

            %init(M3GSignalBarsSpringBoard);

            CFNotificationCenterAddObserver(
                CFNotificationCenterGetDarwinNotifyCenter(),
                NULL,
                M3GSignalBarsPreferencesChanged,
                CFSTR(M3G_SIGNAL_CHANGED),
                NULL,
                CFNotificationSuspensionBehaviorCoalesce
            );
        }
    }
}
