#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import <substrate.h>
#import <dispatch/dispatch.h>
#import <stdint.h>
#import <stddef.h>
#import <stdio.h>
#import <unistd.h>

/*
 * M3gaSignalBars 0.1.3
 * iOS 6.0-6.1.3 / ARMv7.
 *
 * iOS 6.1 keeps the live count in UIStatusBarSignalStrengthItemView's
 * _signalStrengthBars ivar. updateForNewData:actions: updates that count;
 * contentsImageForStyle: draws the native bars. Hook both so the displayed
 * image is forced to five bars even if UIKit regenerates it after a data
 * refresh. The underlying modem count is cached and restored while disabled.
 */

@interface UIStatusBarSignalStrengthItemView : UIView
- (BOOL)updateForNewData:(id)data actions:(int)actions;
- (id)contentsImageForStyle:(int)style;
- (CGFloat)updateContentsAndWidth;
- (void)setVisible:(BOOL)visible frame:(CGRect)frame duration:(double)duration;
@end

static NSString * const MSBPreferencesPath =
    @"/var/mobile/Library/Preferences/com.m3ga.m3gasignalbars.plist";
static NSString * const MSBDebugPath =
    @"/var/mobile/Documents/M3gaSignalBars-Debug.txt";
static CFStringRef const MSBPreferencesChanged =
    CFSTR("com.m3ga.m3gasignalbars/preferences.changed");

static const void *MSBOriginalBarsKey = &MSBOriginalBarsKey;
static BOOL (*MSBOriginalUpdateForNewData)(id, SEL, id, int) = NULL;
static id (*MSBOriginalContentsImageForStyle)(id, SEL, int) = NULL;
static Ivar MSBSignalBarsIvar = NULL;
static BOOL MSBLoggedUpdate = NO;
static BOOL MSBLoggedImage = NO;
static BOOL MSBLoggedMissingPrefs = NO;
static BOOL MSBLoggedRefresh = NO;

static void MSBLog(NSString *message) {
    NSString *bundle = [[NSBundle mainBundle] bundleIdentifier];
    if (![bundle length]) bundle = @"(unknown bundle)";
    FILE *file = fopen([MSBDebugPath fileSystemRepresentation], "a");
    if (!file) return;
    fprintf(file, "pid=%d bundle=%s %s\n",
            getpid(), [bundle UTF8String], [message UTF8String]);
    fclose(file);
}

static BOOL MSBIsEnabled(void) {
    NSDictionary *preferences =
        [NSDictionary dictionaryWithContentsOfFile:MSBPreferencesPath];
    id value = [preferences objectForKey:@"Enabled"];
    if (!value && !MSBLoggedMissingPrefs) {
        MSBLoggedMissingPrefs = YES;
        MSBLog(@"Preference key Enabled was not found; fake bars remain OFF.");
    }
    return value ? [value boolValue] : NO;
}

static Ivar MSBGetSignalBarsIvar(id object) {
    if (!object) return NULL;

    if (!MSBSignalBarsIvar) {
        MSBSignalBarsIvar =
            class_getInstanceVariable(object_getClass(object), "_signalStrengthBars");
    }
    return MSBSignalBarsIvar;
}

static BOOL MSBReadRawBars(id object, int *result) {
    Ivar ivar = MSBGetSignalBarsIvar(object);
    if (!ivar || !result) return NO;

    uint8_t *bytes = (uint8_t *)(__bridge void *)object;
    int *storedValue = (int *)(bytes + ivar_getOffset(ivar));
    *result = *storedValue;
    return YES;
}

static BOOL MSBWriteRawBars(id object, int value) {
    Ivar ivar = MSBGetSignalBarsIvar(object);
    if (!ivar) return NO;

    uint8_t *bytes = (uint8_t *)(__bridge void *)object;
    int *storedValue = (int *)(bytes + ivar_getOffset(ivar));
    *storedValue = value;
    return YES;
}

static int MSBRealBars(UIStatusBarSignalStrengthItemView *view) {
    NSNumber *saved =
        (NSNumber *)objc_getAssociatedObject(view, MSBOriginalBarsKey);
    if (saved) return [saved intValue];

    int current = 0;
    if (!MSBReadRawBars(view, &current)) {
        MSBLog(@"Could not read _signalStrengthBars from signal view.");
        return 0;
    }

    objc_setAssociatedObject(view,
                             MSBOriginalBarsKey,
                             [NSNumber numberWithInt:current],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return current;
}

static void MSBApplyToSignalView(UIStatusBarSignalStrengthItemView *view,
                                 BOOL enabled) {
    if (!view) return;

    int actualBars = MSBRealBars(view);
    int displayBars = enabled ? 5 : actualBars;

    if (!MSBWriteRawBars(view, displayBars)) return;

    if (enabled) {
        view.hidden = NO;
        view.alpha = 1.0;
        [view setVisible:YES frame:view.frame duration:0.0];
    }

    [view updateContentsAndWidth];
    [view setNeedsLayout];
    [view setNeedsDisplay];
}

static void MSBVisitViews(UIView *container, BOOL enabled, int *foundViews) {
    if (!container) return;

    Class signalClass = objc_getClass("UIStatusBarSignalStrengthItemView");
    if (signalClass && [container isKindOfClass:signalClass]) {
        if (foundViews) (*foundViews)++;
        MSBApplyToSignalView((UIStatusBarSignalStrengthItemView *)container, enabled);
    }

    for (UIView *child in [container subviews]) {
        MSBVisitViews(child, enabled, foundViews);
    }
}

static void MSBRefreshStatusBar(void) {
    UIApplication *application = [UIApplication sharedApplication];
    id statusBar = nil;

    @try {
        statusBar = [application valueForKey:@"statusBar"];
    } @catch (NSException *exception) {
        if (!MSBLoggedRefresh) {
            MSBLoggedRefresh = YES;
            MSBLog([NSString stringWithFormat:@"Reading UIApplication.statusBar failed: %@",
                    exception]);
        }
        return;
    }

    int found = 0;
    if ([statusBar isKindOfClass:[UIView class]]) {
        MSBVisitViews((UIView *)statusBar, MSBIsEnabled(), &found);
    }

    if (!MSBLoggedRefresh) {
        MSBLoggedRefresh = YES;
        MSBLog([NSString stringWithFormat:@"Initial status-bar scan found %d signal view(s); Enabled=%d.",
                found, MSBIsEnabled()]);
    }
}

static BOOL MSBUpdateForNewData(id self,
                                SEL command,
                                id data,
                                int actions) {
    BOOL result = NO;

    if (MSBOriginalUpdateForNewData) {
        result = MSBOriginalUpdateForNewData(self, command, data, actions);
    }

    UIStatusBarSignalStrengthItemView *view =
        (UIStatusBarSignalStrengthItemView *)self;

    int actualBars = 0;
    if (MSBReadRawBars(view, &actualBars)) {
        objc_setAssociatedObject(view,
                                 MSBOriginalBarsKey,
                                 [NSNumber numberWithInt:actualBars],
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        BOOL enabled = MSBIsEnabled();
        if (enabled) MSBApplyToSignalView(view, YES);

        if (!MSBLoggedUpdate) {
            MSBLoggedUpdate = YES;
            MSBLog([NSString stringWithFormat:@"updateForNewData hook ran; modem bars=%d, Enabled=%d.",
                    actualBars, enabled]);
        }
    } else if (!MSBLoggedUpdate) {
        MSBLoggedUpdate = YES;
        MSBLog(@"updateForNewData hook ran, but _signalStrengthBars could not be read.");
    }

    return result;
}

static id MSBContentsImageForStyle(id self, SEL command, int style) {
    BOOL enabled = MSBIsEnabled();
    int before = 0;
    BOOL haveBars = MSBReadRawBars(self, &before);

    if (enabled && haveBars) MSBWriteRawBars(self, 5);

    if (!MSBLoggedImage) {
        MSBLoggedImage = YES;
        MSBLog([NSString stringWithFormat:@"contentsImageForStyle hook ran; Enabled=%d, ivar=%d.",
                enabled, haveBars]);
    }

    id image = MSBOriginalContentsImageForStyle
        ? MSBOriginalContentsImageForStyle(self, command, style)
        : nil;

    // Keep the model's real value intact; only the returned native image is forced.
    if (enabled && haveBars) MSBWriteRawBars(self, before);
    return image;
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
        SEL updateSelector = sel_registerName("updateForNewData:actions:");
        SEL imageSelector = sel_registerName("contentsImageForStyle:");

        Method updateMethod = signalClass
            ? class_getInstanceMethod(signalClass, updateSelector)
            : NULL;
        Method imageMethod = signalClass
            ? class_getInstanceMethod(signalClass, imageSelector)
            : NULL;

        if (signalClass) {
            MSBSignalBarsIvar =
                class_getInstanceVariable(signalClass, "_signalStrengthBars");

            if (updateMethod) {
                MSHookMessageEx(signalClass,
                                updateSelector,
                                (IMP)MSBUpdateForNewData,
                                (IMP *)&MSBOriginalUpdateForNewData);
            }
            if (imageMethod) {
                MSHookMessageEx(signalClass,
                                imageSelector,
                                (IMP)MSBContentsImageForStyle,
                                (IMP *)&MSBOriginalContentsImageForStyle);
            }

            MSBLog([NSString stringWithFormat:
                    @"Loaded. update hook=%d image hook=%d signal ivar=%d Enabled=%d.",
                    updateMethod != NULL, imageMethod != NULL,
                    MSBSignalBarsIvar != NULL, MSBIsEnabled()]);
        } else {
            MSBLog(@"Loaded, but UIStatusBarSignalStrengthItemView class was not found.");
        }

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,
            MSBPreferencesChangedCallback,
            MSBPreferencesChanged,
            NULL,
            CFNotificationSuspensionBehaviorCoalesce
        );

        dispatch_async(dispatch_get_main_queue(), ^{
            MSBRefreshStatusBar();
        });
    }
}
