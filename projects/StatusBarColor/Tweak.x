#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define PREFS_PATH @"/var/mobile/Library/Preferences/com.m3gaios6p0w3r.statusbarcolor.plist"

@interface UIStatusBarItemView : UIView
- (UIColor *)textColorForStyle:(int)style;
@end

%hook UIStatusBarItemView

- (UIColor *)textColorForStyle:(int)style {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREFS_PATH];
    id enabledValue = [prefs objectForKey:@"Enabled"];

    // Missing preference keys use the advertised first-run defaults.
    if (enabledValue && ![enabledValue boolValue]) {
        return %orig;
    }

    id redValue = [prefs objectForKey:@"Red"];
    id greenValue = [prefs objectForKey:@"Green"];
    id blueValue = [prefs objectForKey:@"Blue"];

    CGFloat red = redValue ? [redValue floatValue] : 255.0;
    CGFloat green = greenValue ? [greenValue floatValue] : 250.0;
    CGFloat blue = blueValue ? [blueValue floatValue] : 168.0;

    red = MIN(255.0, MAX(0.0, red)) / 255.0;
    green = MIN(255.0, MAX(0.0, green)) / 255.0;
    blue = MIN(255.0, MAX(0.0, blue)) / 255.0;

    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

%end
