#import <Preferences/PSListController.h>
#import <UIKit/UIKit.h>
@interface M3gaStatusBarColorController : PSListController
- (void)openCreatorPage;
@end
@implementation M3gaStatusBarColorController
- (NSArray *)specifiers {
 if (!_specifiers) _specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
 return _specifiers;
}
- (void)setPreferenceValue:(id)value specifier:(id)specifier {
 // Clamp typed RGB values to the same 0–255 range as the sliders.
 NSString *key = [specifier propertyForKey:@"key"];
 BOOL isRGBKey = [key isEqualToString:@"Red"] ||
                 [key isEqualToString:@"Green"] ||
                 [key isEqualToString:@"Blue"];
 if (isRGBKey) {
  NSInteger component = [value respondsToSelector:@selector(integerValue)] ? [value integerValue] : 0;
  component = MAX(0, MIN(255, component));
  value = [NSNumber numberWithInteger:component];
 }

 [super setPreferenceValue:value specifier:specifier];

 // Keep the RGB slider and its numeric text field visually synchronized.
 if (![key length]) return;

 for (id otherSpecifier in [self specifiers]) {
  if (otherSpecifier != specifier &&
      [[otherSpecifier propertyForKey:@"key"] isEqualToString:key]) {
   [self reloadSpecifier:otherSpecifier];
  }
 }
}
- (void)openCreatorPage {
 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/caldwelljaeb-pixel"]];
}
@end
