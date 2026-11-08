#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import <substrate.h>
#import <dispatch/dispatch.h>

/*
 * M3gaSignalBars 0.1.0
 * iOS 6 / ARMv7 SpringBoard-only cosmetic signal indicator override.
 *
 * The real modem signal is never changed. We remember the value supplied by
 * SpringBoard and only replace the value sent to the native status-bar view.
 */

static NSString * const MSBPreferencesPath =
    @"/var/mobile/Library/Preferences/com.m3ga.m3gasignalbars.plist";
static CFStringRef const MSBPreferencesChanged =
    CFSTR("com.m3ga.m3gasignalbars/preferences.changed");

static const void *MSBOriginalBarsKey = &MSBOriginalBarsKey;
static void (*MSBOriginalSetSignalStrengthBars)(id, SEL, int) = NULL;

static BOOL MSBIsEnabled(void) {
    NSDictionary *preferences =
        [NSDictionary dictionaryWithContentsOfFile:MSBPreferencesPath];
    id value = [preferences objectForKey:@"Enabled"];
    return value ? [value boolValue] : NO;
}

static void MSBSetSignalStrengthBars(id self, SEL command, int bars) {
    @autoreleasepool {
        // Keep the latest real value so disabling the tweak can restore it
        // immediately, without waiting for another modem update.
        objc_setAssociatedObject(self,
                                 MSBOriginalBarsKey,
                                 [NSNumber numberWithInt:bars],
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        int displayedBars = MSBIsEnabled() ? 5 : bars;
        if (MSBOriginalSetSignalStrengthBars) {
            MSBOriginalSetSignalStrengthBars(self, command, displayedBars);
        }
    }
}

static NSNumber *MSBReadCurrentBars(id item) {
    NSNumber *saved = (NSNumber *)objc_getAssociatedObject(item, MSBOriginalBarsKey);
    if (saved) return saved;

    id value = nil;
    @try {
        value = [item valueForKey:@"signalStrengthBars"];
    } @catch (NSException *exception) {
        value = nil;
    }

    if (![value respondsToSelector:@selector(intValue)]) {
        @try {
            value = [item valueForKey:@"_signalStrengthBars"];
        } @catch (NSException *exception) {
            value = nil;
        }
    }

    return [value respondsToSelector:@selector(intValue)] ? value : nil;
}

static void MSBRefreshViewsInContainer(UIView *container, BOOL enabled) {
    if (!container) return;

    Class signalClass = objc_getClass("UIStatusBarSignalStrengthItemView");
    SEL setter = sel_registerName("setSignalStrengthBars:");

    if (signalClass && [container isKindOfClass:signalClass]) {
        NSNumber *realBars = MSBReadCurrentBars(container);
        if (realBars) {
            objc_setAssociatedObject(container,
                                     MSBOriginalBarsKey,
                                     realBars,
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);

            // Call the saved original IMP directly. This avoids recording our
            // own cosmetic value (5) as the real modem value.
            if (MSBOriginalSetSignalStrengthBars) {
                int value = enabled ? 5 : [realBars intValue];
                MSBOriginalSetSignalStrengthBars(container, setter, value);
            }
        }
    }

    for (UIView *child in [container subviews]) {
        MSBRefreshViewsInContainer(child, enabled);
    }
}

static void MSBRefreshStatusBar(void) {
    BOOL enabled = MSBIsEnabled();

    UIApplication *application = [UIApplication sharedApplication];
    id statusBar = nil;
    id foregroundView = nil;

    @try {
        statusBar = [application valueForKey:@"statusBar"];
        foregroundView = [statusBar valueForKey:@"foregroundView"];
    } @catch (NSException *exception) {
        // If this iOS build exposes a different private status-bar structure,
        // the normal setter hook will still apply the preference on updates.
        return;
    }

    if ([foregroundView isKindOfClass:[UIView class]]) {
        MSBRefreshViewsInContainer((UIView *)foregroundView, enabled);
    }
}

static void MSBPreferencesChangedCallback(CFNotificationCenterRef center,
                                          void *observer,
                                          CFStringRef name,
                                          const void *object,
                                          CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        MSBRefreshStatusBar();
    });
}

__attribute__((constructor))
static void MSBInitialize(void) {
    @autoreleasepool {
        Class signalClass = objc_getClass("UIStatusBarSignalStrengthItemView");
        SEL setter = sel_registerName("setSignalStrengthBars:");

        if (signalClass && class_getInstanceMethod(signalClass, setter)) {
            MSHookMessageEx(signalClass,
                            setter,
                            (IMP)MSBSetSignalStrengthBars,
                            (IMP *)&MSBOriginalSetSignalStrengthBars);
        } else {
            NSLog(@"M3gaSignalBars: native signal-bars setter was not found.");
        }

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,
            MSBPreferencesChangedCallback,
            MSBPreferencesChanged,
            NULL,
            CFNotificationSuspensionBehaviorCoalesce
        );

        // Apply an existing preference as soon as SpringBoard has its status
        // bar views. The switch is OFF unless the user explicitly enables it.
        dispatch_async(dispatch_get_main_queue(), ^{
            MSBRefreshStatusBar();
        });
    }
}
