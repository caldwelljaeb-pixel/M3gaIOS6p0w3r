#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/* Preferences is private on iOS 6; keep the interfaces local. */
@interface PSListController : UIViewController
- (NSMutableArray *)loadSpecifiersFromPlistName:(NSString *)name target:(id)target;
- (void)setSpecifiers:(NSMutableArray *)specifiers;
@end

@interface M3GSignalBarsBaseController : PSListController
- (NSString *)plistName;
- (NSString *)paneTitle;
@end

static char MSBLoadedSpecifiersKey;

@implementation M3GSignalBarsBaseController

- (NSBundle *)bundle {
    return [NSBundle bundleForClass:[self class]];
}

- (NSArray *)specifiers {
    NSArray *cached = objc_getAssociatedObject(self, &MSBLoadedSpecifiersKey);

    if (!cached) {
        NSString *name = [self plistName];
        NSMutableArray *loaded = [self loadSpecifiersFromPlistName:name target:self];

        if ([loaded isKindOfClass:[NSArray class]] && [loaded count] > 0) {
            [self setSpecifiers:loaded];
            objc_setAssociatedObject(self,
                                     &MSBLoadedSpecifiersKey,
                                     loaded,
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            cached = loaded;
        } else {
            NSLog(@"M3gaSignalBars: failed to load %@.plist from %@",
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

@interface M3GSignalBarsRootController : M3GSignalBarsBaseController
@end

@implementation M3GSignalBarsRootController

- (NSString *)plistName {
    return @"Root";
}

- (NSString *)paneTitle {
    return @"M3gaSignalBars";
}

- (void)openCreatorWebsite:(id)specifier {
    NSURL *websiteURL =
        [NSURL URLWithString:@"https://github.com/caldwelljaeb-pixel"];
    BOOL opened = websiteURL &&
        [[UIApplication sharedApplication] openURL:websiteURL];

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

@interface M3GSignalBarsInstructionsController : M3GSignalBarsBaseController
@end

@implementation M3GSignalBarsInstructionsController

- (NSString *)plistName {
    return @"Instructions";
}

- (NSString *)paneTitle {
    return @"Instructions";
}

@end

@interface M3GSignalBarsAboutController : M3GSignalBarsBaseController
@end

@implementation M3GSignalBarsAboutController

- (NSString *)plistName {
    return @"About";
}

- (NSString *)paneTitle {
    return @"Info About Me";
}

@end
