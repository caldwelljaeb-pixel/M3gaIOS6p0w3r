#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/*
 * Preferences is private on iOS 6. Keep the minimal declarations local so
 * current SDK headers do not inject APIs newer than our deployment target.
 */
@interface PSListController : UIViewController
- (NSMutableArray *)loadSpecifiersFromPlistName:(NSString *)name target:(id)target;
- (void)setSpecifiers:(NSMutableArray *)specifiers;
@end

@interface M3gaSignalBarsController : PSListController
@end

static char M3GSignalBarsLoadedSpecifiersKey;

@implementation M3gaSignalBarsController

- (NSBundle *)bundle {
    return [NSBundle bundleForClass:[self class]];
}

- (NSArray *)specifiers {
    NSArray *cached = objc_getAssociatedObject(self, &M3GSignalBarsLoadedSpecifiersKey);
    if (!cached) {
        NSMutableArray *loaded = [self loadSpecifiersFromPlistName:@"Root" target:self];
        if ([loaded isKindOfClass:[NSArray class]] && [loaded count] > 0) {
            // PSListController must own the array, not just receive a return value.
            [self setSpecifiers:loaded];
            objc_setAssociatedObject(self, &M3GSignalBarsLoadedSpecifiersKey,
                                     loaded, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            cached = loaded;
        } else {
            NSLog(@"M3gaSignalBars: failed to load Root.plist from %@",
                  [[self bundle] bundlePath]);
            return [NSArray array];
        }
    }
    return cached;
}

@end
