#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import <substrate.h>
#import <dispatch/dispatch.h>
#import <stdint.h>
#import <stddef.h>

/*
 * M3gaSignalBars 0.1.1
 * iOS 6.0-6.1.3 / ARMv7.
 *
 * iOS 6.1 UIStatusBarSignalStrengthItemView has no
 * -setSignalStrengthBars: method. It stores the count in _signalStrengthBars
 * and refreshes it in -updateForNewData:actions:. Hook that actual method.
 *
 * The ivar is accessed with the Objective-C runtime (class_getInstanceVariable
 * and ivar_getOffset), avoiding non-portable helper macros.
 */

@interface UIStatusBarSignalStrengthItemView : UIView
- (BOOL)updateForNewData:(id)data actions:(int)actions;
- (CGFloat)updateContentsAndWidth;
- (void)setVisible:(BOOL)visible frame:(CGRect)frame duration:(double)duration;
@end

static NSString * const MSBPreferencesPath =
    @"/var/mobile/Library/Preferences/com.m3ga.m3gasignalbars.plist";
static CFStringRef const MSBPreferencesChanged =
    CFSTR("com.m3ga.m3gasignalbars/preferences.changed");

static const void *MSBOriginalBarsKey = &MSBOriginalBarsKey;
static BOOL (*MSBOriginalUpdateForNewData)(id, SEL, id, int) = NULL;
static Ivar MSBSignalBarsIvar = NULL;

static BOOL MSBIsEnabled(void) {
    NSDictionary *preferences =
        [NSDictionary dictionaryWithContentsOfFile:MSBPreferencesPath];
    id value = [preferences objectForKey:@"Enabled"];
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
        NSLog(@"M3gaSignalBars: _signalStrengthBars ivar was not found.");
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

    // Rebuild the native signal image and width after changing its bar count.
    [view updateContentsAndWidth];
    [view setNeedsLayout];
    [view setNeedsDisplay];
}

static void MSBVisitViews(UIView *container, BOOL enabled) {
    if (!container) return;

    Class signalClass = objc_getClass("UIStatusBarSignalStrengthItemView");
    if (signalClass && [container isKindOfClass:signalClass]) {
        MSBApplyToSignalView((UIStatusBarSignalStrengthItemView *)container, enabled);
    }

    for (UIView *child in [container subviews]) {
        MSBVisitViews(child, enabled);
    }
}

static void MSBRefreshStatusBar(void) {
    UIApplication *application = [UIApplication sharedApplication];
    id statusBar = nil;

    @try {
        statusBar = [application valueForKey:@"statusBar"];
    } @catch (NSException *exception) {
        NSLog(@"M3gaSignalBars: unable to access the native status bar: %@", exception);
        return;
    }

    if ([statusBar isKindOfClass:[UIView class]]) {
        MSBVisitViews((UIView *)statusBar, MSBIsEnabled());
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

    // Save the real count produced by iOS before applying the visual override.
    int actualBars = 0;
    if (MSBReadRawBars(view, &actualBars)) {
        objc_setAssociatedObject(view,
                                 MSBOriginalBarsKey,
                                 [NSNumber numberWithInt:actualBars],
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (MSBIsEnabled()) {
            MSBApplyToSignalView(view, YES);
        }
    }

    return result;
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
        Method updateMethod = signalClass
            ? class_getInstanceMethod(signalClass, updateSelector)
            : NULL;

        if (signalClass && updateMethod) {
            MSBSignalBarsIvar =
                class_getInstanceVariable(signalClass, "_signalStrengthBars");
            MSHookMessageEx(signalClass,
                            updateSelector,
                            (IMP)MSBUpdateForNewData,
                            (IMP *)&MSBOriginalUpdateForNewData);
        } else {
            NSLog(@"M3gaSignalBars: iOS 6 signal view/update method was not found.");
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
