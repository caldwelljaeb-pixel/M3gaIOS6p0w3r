#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import <substrate.h>
#import <dispatch/dispatch.h>

/*
 * M3gaSignalBars 0.1.1
 * iOS 6.0-6.1.3 / ARMv7.
 *
 * IMPORTANT: iOS 6.1 does not implement
 * -setSignalStrengthBars: on UIStatusBarSignalStrengthItemView.
 * The real view stores the count in _signalStrengthBars and updates it in
 * -updateForNewData:actions:. Hook that actual iOS 6 method instead.
 *
 * This is a display-only change. It never alters the modem or telephony data.
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

static BOOL MSBIsEnabled(void) {
    NSDictionary *preferences =
        [NSDictionary dictionaryWithContentsOfFile:MSBPreferencesPath];
    id value = [preferences objectForKey:@"Enabled"];
    return value ? [value boolValue] : NO;
}

static int MSBRealBars(UIStatusBarSignalStrengthItemView *view) {
    NSNumber *saved = (NSNumber *)objc_getAssociatedObject(view, MSBOriginalBarsKey);
    if (saved) return [saved intValue];

    int current = MSHookIvar<int>(view, "_signalStrengthBars");
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

    // iOS 6 stores its signal count in this ivar. There is no public setter
    // and the iOS 6.1 class-dump confirms updateForNewData:actions: as the
    // update entry point.
    MSHookIvar<int>(view, "_signalStrengthBars") = displayBars;

    if (enabled) {
        view.hidden = NO;
        view.alpha = 1.0;
        [view setVisible:YES frame:view.frame duration:0.0];
    }

    // Rebuild the native signal image/width after changing the stored count.
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

    // Save the real count produced by iOS before applying our visual override.
    int actualBars = MSHookIvar<int>(view, "_signalStrengthBars");
    objc_setAssociatedObject(view,
                             MSBOriginalBarsKey,
                             [NSNumber numberWithInt:actualBars],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if (MSBIsEnabled()) {
        MSBApplyToSignalView(view, YES);
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
