#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <substrate.h>

static NSString * const M3GAPreferencesPath = @"/var/mobile/Library/Preferences/com.m3ga.appcustomizer.plist";
static NSString * const M3GAIconsPath = @"/var/mobile/Library/M3gaAppCustomizer/Icons";
static CFStringRef const M3GAChanged = CFSTR("com.m3ga.appcustomizer/preferences.changed");
static NSDictionary *M3GASettings = nil;

static NSDictionary *M3GALoadSettings(void) {
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:M3GAPreferencesPath];
    return [settings isKindOfClass:[NSDictionary class]] ? settings : [NSDictionary dictionary];
}

static NSString *M3GABundleIdentifier(id icon) {
    SEL selector = @selector(applicationBundleID);
    if (!icon || ![icon respondsToSelector:selector]) return nil;
    id value = ((id (*)(id, SEL))objc_msgSend)(icon, selector);
    return [value isKindOfClass:[NSString class]] ? value : nil;
}

static NSString *M3GASafeIconPath(NSString *bundleIdentifier) {
    if (![bundleIdentifier isKindOfClass:[NSString class]] || bundleIdentifier.length == 0) return nil;
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_"];
    if ([bundleIdentifier rangeOfCharacterFromSet:[allowed invertedSet]].location != NSNotFound) return nil;
    return [M3GAIconsPath stringByAppendingPathComponent:[bundleIdentifier stringByAppendingPathExtension:@"png"]];
}

static void M3GARefreshViewTree(UIView *view) {
    if (!view) return;
    Class iconViewClass = objc_getClass("SBIconView");
    if (iconViewClass && [view isKindOfClass:iconViewClass]) {
        id icon = nil;
        SEL iconSelector = @selector(icon);
        if ([view respondsToSelector:iconSelector])
            icon = ((id (*)(id, SEL))objc_msgSend)(view, iconSelector);
        if (icon) {
            SEL purgeSelector = @selector(reloadIconImagePurgingImageCache:);
            if ([icon respondsToSelector:purgeSelector])
                ((void (*)(id, SEL, BOOL))objc_msgSend)(icon, purgeSelector, YES);
            else {
                SEL reloadSelector = @selector(reloadIconImage);
                if ([icon respondsToSelector:reloadSelector])
                    ((void (*)(id, SEL))objc_msgSend)(icon, reloadSelector);
            }
        }
        SEL updateLabelSelector = @selector(updateLabel);
        if ([view respondsToSelector:updateLabelSelector])
            ((void (*)(id, SEL))objc_msgSend)(view, updateLabelSelector);
    }
    for (UIView *child in [view.subviews copy]) M3GARefreshViewTree(child);
}

static void M3GARefreshHomeScreen(void) {
    M3GASettings = M3GALoadSettings();
    dispatch_async(dispatch_get_main_queue(), ^{
        UIApplication *application = [UIApplication sharedApplication];
        for (UIWindow *window in application.windows) M3GARefreshViewTree(window);
    });
}

static void M3GAPreferencesChanged(CFNotificationCenterRef center, void *observer,
                                   CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    M3GARefreshHomeScreen();
}

%hook SBApplicationIcon
- (id)displayName {
    NSString *bundleIdentifier = M3GABundleIdentifier(self);
    NSDictionary *names = [M3GASettings objectForKey:@"Names"];
    NSString *customName = [names objectForKey:bundleIdentifier];
    if ([customName isKindOfClass:[NSString class]] && customName.length > 0) return customName;
    return %orig;
}
- (id)generateIconImage:(int)format {
    NSString *bundleIdentifier = M3GABundleIdentifier(self);
    NSString *path = M3GASafeIconPath(bundleIdentifier);
    UIImage *customImage = path ? [UIImage imageWithContentsOfFile:path] : nil;
    if (customImage) return customImage;
    return %orig;
}
%end

%ctor {
    M3GASettings = M3GALoadSettings();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
                                    M3GAPreferencesChanged, M3GAChanged, NULL,
                                    CFNotificationSuspensionBehaviorCoalesce);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ M3GARefreshHomeScreen(); });
}
