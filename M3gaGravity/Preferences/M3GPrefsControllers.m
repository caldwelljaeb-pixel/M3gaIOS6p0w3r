#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/*
 * Preferences is private on iOS 6. Keep the declarations local so the bundle
 * can still be built with the public iOS 9.3 SDK headers.
 */
@interface PSListController : UIViewController
- (NSMutableArray *)loadSpecifiersFromPlistName:(NSString *)name target:(id)target;
- (void)setSpecifiers:(NSMutableArray *)specifiers;
@end

@interface M3GBaseController : PSListController
- (NSString *)plistName;
- (NSString *)paneTitle;
@end

static char M3GLoadedSpecifiersKey;

@implementation M3GBaseController

- (NSBundle *)bundle {
    // Every pane plist is installed inside M3gaGravityPrefs.bundle.
    return [NSBundle bundleForClass:[self class]];
}

- (NSArray *)specifiers {
    NSArray *cached = objc_getAssociatedObject(self, &M3GLoadedSpecifiersKey);

    if (!cached) {
        NSString *name = [self plistName];
        NSMutableArray *loaded = [self loadSpecifiersFromPlistName:name target:self];

        if ([loaded isKindOfClass:[NSArray class]] && [loaded count] > 0) {
            /*
             * PSListController reads its own specifiers storage when preparing
             * section/group metadata. Returning a separate cached array alone
             * is not sufficient on older iOS releases.
             */
            [self setSpecifiers:loaded];
            objc_setAssociatedObject(self, &M3GLoadedSpecifiersKey,
                                     loaded, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            cached = loaded;
        } else {
            NSLog(@"M3gaGravity: failed to load %@.plist from %@",
                  name, [[self bundle] bundlePath]);
            return [NSArray array];
        }
    }

    return cached;
}

- (NSString *)navigationTitle {
    return [self paneTitle];
}

- (NSString *)plistName {
    return nil;
}

- (NSString *)paneTitle {
    return nil;
}

@end

@interface M3GRootController : M3GBaseController
@end

@implementation M3GRootController

- (NSString *)plistName {
    return @"Root";
}

- (NSString *)paneTitle {
    return @"M3gaGravity";
}

/* PSButtonCell sends its configured action selector to this pane controller. */
- (void)openCreatorWebsite:(id)specifier {
    NSURL *websiteURL = [NSURL URLWithString:@"https://github.com/caldwelljaeb-pixel"];
    BOOL opened = websiteURL && [[UIApplication sharedApplication] openURL:websiteURL];

    if (!opened) {
        UIAlertView *alert = [[UIAlertView alloc]
            initWithTitle:@"Website"
                  message:@"Safari could not be opened for the creator website."
                 delegate:nil
        cancelButtonTitle:@"OK"
        otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

@end

@interface M3GInstructionsController : M3GBaseController
@end

@implementation M3GInstructionsController

- (NSString *)plistName {
    return @"Instructions";
}

- (NSString *)paneTitle {
    return @"Instructions";
}

@end

@interface M3GAboutController : M3GBaseController
@end

@implementation M3GAboutController

- (NSString *)plistName {
    return @"About";
}

- (NSString *)paneTitle {
    return @"Info About Me";
}

@end
