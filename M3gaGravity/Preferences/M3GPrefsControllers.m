#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/*
 * Preferences is a private framework. Keep the declarations local so this
 * bundle can build against the public iOS 9.3 SDK while remaining compatible
 * with the iOS 6 PSListController runtime.
 */
@interface PSListController : UIViewController
- (NSArray *)loadSpecifiersFromPlistName:(NSString *)name target:(id)target;
@end

static char M3GInstructionsCacheKey;
static char M3GAboutCacheKey;

@interface M3GInstructionsController : PSListController
@end

@implementation M3GInstructionsController

- (NSBundle *)bundle {
    // Make plist lookup resolve inside M3gaGravityPrefs.bundle itself.
    return [NSBundle bundleForClass:[self class]];
}

- (NSString *)navigationTitle {
    return @"Instructions";
}

- (NSArray *)specifiers {
    NSArray *cached = objc_getAssociatedObject(self, &M3GInstructionsCacheKey);
    if (!cached) {
        cached = [self loadSpecifiersFromPlistName:@"Instructions" target:self];
        if (cached) {
            objc_setAssociatedObject(self, &M3GInstructionsCacheKey,
                                     cached, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    self.title = @"Instructions";
    return cached ?: [NSArray array];
}

@end

@interface M3GAboutController : PSListController
@end

@implementation M3GAboutController

- (NSBundle *)bundle {
    // Use the same resource bundle, but this controller loads About.plist.
    return [NSBundle bundleForClass:[self class]];
}

- (NSString *)navigationTitle {
    return @"Info About Me";
}

- (NSArray *)specifiers {
    NSArray *cached = objc_getAssociatedObject(self, &M3GAboutCacheKey);
    if (!cached) {
        cached = [self loadSpecifiersFromPlistName:@"About" target:self];
        if (cached) {
            objc_setAssociatedObject(self, &M3GAboutCacheKey,
                                     cached, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    self.title = @"Info About Me";
    return cached ?: [NSArray array];
}

@end
