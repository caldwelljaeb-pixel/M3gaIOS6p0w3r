#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define PREFS_PATH @"/var/mobile/Library/Preferences/com.m3gaios6p0w3r.statusbarcolor.plist"

@interface UIStatusBarItemView : UIView
- (UIColor *)textColorForStyle:(int)style;
@end

%hook UIStatusBarItemView

- (UIColor *)textColorForStyle:(int)style {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREFS_PATH];
    if (![ [prefs objectForKey:@"Enabled"] boolValue ]) {
        return %orig;
    }

    CGFloat red = [[prefs objectForKey:@"Red"] floatValue];
    CGFloat green = [[prefs objectForKey:@"Green"] floatValue];
    CGFloat blue = [[prefs objectForKey:@"Blue"] floatValue];

    red = MIN(255.0, MAX(0.0, red)) / 255.0;
    green = MIN(255.0, MAX(0.0, green)) / 255.0;
    blue = MIN(255.0, MAX(0.0, blue)) / 255.0;

    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

%end
