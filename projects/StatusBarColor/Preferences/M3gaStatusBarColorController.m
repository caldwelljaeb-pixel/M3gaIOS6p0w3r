#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>
@interface M3gaStatusBarColorController : PSListController
- (void)openCreatorPage;
@end
@implementation M3gaStatusBarColorController
- (NSArray *)specifiers {
 if (!_specifiers) _specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
 return _specifiers;
}
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
 [super setPreferenceValue:value specifier:specifier];

 // Keep the RGB slider and its numeric text field visually synchronized.
 NSString *key = [specifier propertyForKey:@"key"];
 if (![key length]) return;

 for (PSSpecifier *otherSpecifier in [self specifiers]) {
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
