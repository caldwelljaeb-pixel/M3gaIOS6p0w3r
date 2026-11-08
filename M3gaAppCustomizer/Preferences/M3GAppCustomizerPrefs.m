#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface PSListController : UIViewController
- (NSMutableArray *)loadSpecifiersFromPlistName:(NSString *)name target:(id)target;
- (void)setSpecifiers:(NSMutableArray *)specifiers;
@end
@interface PSSpecifier : NSObject
+ (id)preferenceSpecifierNamed:(NSString *)name target:(id)target set:(SEL)set get:(SEL)get detail:(Class)detail cell:(NSInteger)cell edit:(Class)edit;
- (void)setProperty:(id)value forKey:(NSString *)key;
- (id)propertyForKey:(NSString *)key;
@end
@interface PSTableCell : UITableViewCell
+ (NSInteger)cellTypeFromString:(NSString *)name;
@end
@interface M3GBaseController : PSListController
- (NSString *)plistName;
- (NSString *)paneTitle;
@end

static const void *M3GAAppSpecifiersKey = &M3GAAppSpecifiersKey;
static NSString * const M3GAPreferencesPath = @"/var/mobile/Library/Preferences/com.m3ga.appcustomizer.plist";
static NSString * const M3GAIconsPath = @"/var/mobile/Library/M3gaAppCustomizer/Icons";
static CFStringRef const M3GAChangedNotification = CFSTR("com.m3ga.appcustomizer/preferences.changed");

static NSDictionary *M3GAReadPreferences(void) {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:M3GAPreferencesPath];
    return [prefs isKindOfClass:[NSDictionary class]] ? prefs : [NSDictionary dictionary];
}
static void M3GAPostChanged(void) {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), M3GAChangedNotification, NULL, NULL, YES);
}
static void M3GAAddAppsFromDirectory(NSString *directory,
                                     NSMutableDictionary *appsByID) {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *children = [manager contentsOfDirectoryAtPath:directory error:nil];
    for (NSString *child in children) {
        NSString *childPath = [directory stringByAppendingPathComponent:child];
        BOOL isDirectory = NO;
        if (![manager fileExistsAtPath:childPath isDirectory:&isDirectory] || !isDirectory)
            continue;

        if ([[childPath pathExtension] caseInsensitiveCompare:@"app"] == NSOrderedSame) {
            NSString *infoPath = [childPath stringByAppendingPathComponent:@"Info.plist"];
            NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:infoPath];
            NSString *bundleID = [info objectForKey:@"CFBundleIdentifier"];
            NSString *name = [info objectForKey:@"CFBundleDisplayName"];
            if (![name isKindOfClass:[NSString class]] || name.length == 0)
                name = [info objectForKey:@"CFBundleName"];
            if (![name isKindOfClass:[NSString class]] || name.length == 0)
                name = bundleID;
            if ([bundleID isKindOfClass:[NSString class]] && bundleID.length > 0 &&
                [name isKindOfClass:[NSString class]] && name.length > 0) {
                [appsByID setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                    bundleID, @"bundleID", name, @"name", nil] forKey:bundleID];
            }
            continue;
        }

        // iOS 6 stores App Store apps one directory below a UUID folder.
        // Only inspect the next level; do not recurse into app bundles/frameworks.
        if ([directory isEqualToString:@"/var/mobile/Applications"])
            M3GAAddAppsFromDirectory(childPath, appsByID);
    }
}

static NSArray *M3GAInstalledApps(void) {
    NSMutableDictionary *appsByID = [NSMutableDictionary dictionary];
    M3GAAddAppsFromDirectory(@"/Applications", appsByID);
    M3GAAddAppsFromDirectory(@"/var/mobile/Applications", appsByID);

    NSArray *sorted = [[appsByID allValues] sortedArrayUsingComparator:
        ^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            return [[a objectForKey:@"name"] localizedCaseInsensitiveCompare:[b objectForKey:@"name"]];
        }];
    return sorted ? sorted : [NSArray array];
}

static NSMutableDictionary *M3GAMutablePreferences(void) {
    NSDictionary *existing = M3GAReadPreferences();
    return existing ? [existing mutableCopy] : [NSMutableDictionary dictionary];
}

@implementation M3GBaseController
- (NSBundle *)bundle { return [NSBundle bundleForClass:[self class]]; }
- (NSArray *)specifiers {
    NSArray *cached = objc_getAssociatedObject(self, &M3GAAppSpecifiersKey);
    if (!cached) {
        NSMutableArray *loaded = [self loadSpecifiersFromPlistName:[self plistName] target:self];
        if ([loaded isKindOfClass:[NSArray class]] && loaded.count > 0) {
            [self setSpecifiers:loaded];
            objc_setAssociatedObject(self, &M3GAAppSpecifiersKey, loaded, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            cached = loaded;
        } else {
            NSLog(@"M3gaAppCustomizer: could not load %@.plist", [self plistName]);
            return [NSArray array];
        }
    }
    return cached;
}
- (NSString *)navigationTitle { return [self paneTitle]; }
- (NSString *)plistName { return nil; }
- (NSString *)paneTitle { return nil; }
@end

@interface M3GRootController : M3GBaseController
- (void)openCreatorWebsite:(id)specifier;
@end
@implementation M3GRootController
- (NSString *)plistName { return @"Root"; }
- (NSString *)paneTitle { return @"M3gaAppCustomizer"; }
- (void)openCreatorWebsite:(id)specifier {
    NSURL *url = [NSURL URLWithString:@"https://github.com/caldwelljaeb-pixel"];
    if (!url || ![[UIApplication sharedApplication] openURL:url]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Website" message:@"Safari could not be opened for the creator website." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}
@end

@interface M3GAppsController : PSListController
@end
@interface M3GNamesController : M3GAppsController
- (id)nameForSpecifier:(PSSpecifier *)specifier;
- (void)setName:(id)value specifier:(PSSpecifier *)specifier;
@end
@implementation M3GAppsController
- (NSBundle *)bundle { return [NSBundle bundleForClass:[self class]]; }
- (NSArray *)specifiers {
    NSArray *cached = objc_getAssociatedObject(self, &M3GAAppSpecifiersKey);
    if (cached) return cached;
    NSMutableArray *items = [NSMutableArray array];
    NSInteger groupCell = [PSTableCell cellTypeFromString:@"PSGroupCell"];
    NSInteger editCell = [PSTableCell cellTypeFromString:@"PSEditTextCell"];
    NSInteger buttonCell = [PSTableCell cellTypeFromString:@"PSButtonCell"];
    BOOL isNames = [self isKindOfClass:[M3GNamesController class]];
    PSSpecifier *group = [PSSpecifier preferenceSpecifierNamed:(isNames ? @"Rename Installed Apps" : @"Choose an App")
        target:self set:NULL get:NULL detail:Nil cell:groupCell edit:Nil];
    [group setProperty:(isNames ? @"Enter a replacement name in the field beside an app. Leave it blank to restore the original name."
        : @"Tap an app to choose a photo from your iPhone's photo library for its Home Screen icon.") forKey:@"footerText"];
    [items addObject:group];
    NSArray *apps = M3GAInstalledApps();
    for (NSDictionary *app in apps) {
        NSString *bundleID = [app objectForKey:@"bundleID"];
        NSString *name = [app objectForKey:@"name"];
        PSSpecifier *specifier = nil;
        if (isNames) {
            specifier = [PSSpecifier preferenceSpecifierNamed:name target:self set:@selector(setName:specifier:)
                get:@selector(nameForSpecifier:) detail:Nil cell:editCell edit:Nil];
            [specifier setProperty:@"New name" forKey:@"placeholder"];
            [specifier setProperty:@"all" forKey:@"autoCaps"];
            [specifier setProperty:@YES forKey:@"noAutoCorrect"];
        } else {
            specifier = [PSSpecifier preferenceSpecifierNamed:name target:self set:NULL get:NULL detail:Nil cell:buttonCell edit:Nil];
            [specifier setProperty:NSStringFromSelector(@selector(speciferPerformedAction:)) forKey:@"action"];
        }
        [specifier setProperty:bundleID forKey:@"M3GBundleID"];
        [specifier setProperty:@YES forKey:@"enabled"];
        [items addObject:specifier];
    }
    if (apps.count == 0) {
        PSSpecifier *empty = [PSSpecifier preferenceSpecifierNamed:@"No installed apps were found" target:self
            set:NULL get:NULL detail:Nil cell:[PSTableCell cellTypeFromString:@"PSStaticTextCell"] edit:Nil];
        [items addObject:empty];
    }
    [self setSpecifiers:items];
    objc_setAssociatedObject(self, &M3GAAppSpecifiersKey, items, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return items;
}
@end

@implementation M3GNamesController
- (id)nameForSpecifier:(PSSpecifier *)specifier {
    NSString *bundleID = [specifier propertyForKey:@"M3GBundleID"];
    NSString *name = [[M3GAReadPreferences() objectForKey:@"Names"] objectForKey:bundleID];
    return [name isKindOfClass:[NSString class]] ? name : @"";
}
- (void)setName:(id)value specifier:(PSSpecifier *)specifier {
    NSString *bundleID = [specifier propertyForKey:@"M3GBundleID"];
    if (bundleID.length == 0) return;
    NSMutableDictionary *prefs = M3GAMutablePreferences();
    NSMutableDictionary *names = [[prefs objectForKey:@"Names"] mutableCopy];
    if (!names) names = [NSMutableDictionary dictionary];
    NSString *name = [value isKindOfClass:[NSString class]] ? [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] : @"";
    if (name.length > 0) [names setObject:name forKey:bundleID]; else [names removeObjectForKey:bundleID];
    [prefs setObject:names forKey:@"Names"];
    [prefs writeToFile:M3GAPreferencesPath atomically:YES];
    M3GAPostChanged();
}
@end

@interface M3GImagesController : M3GAppsController <UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    NSString *_selectedBundleIdentifier;
}
- (void)speciferPerformedAction:(PSSpecifier *)specifier;
@end
@implementation M3GImagesController
- (void)speciferPerformedAction:(PSSpecifier *)specifier {
    _selectedBundleIdentifier = [[specifier propertyForKey:@"M3GBundleID"] copy];
    if (_selectedBundleIdentifier.length == 0) return;
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Photo Library Unavailable" message:@"This iPhone does not currently provide a photo library." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show]; [alert release]; return;
    }
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    picker.allowsEditing = YES;
    [self presentModalViewController:picker animated:YES];
    [picker release];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (![image isKindOfClass:[UIImage class]]) image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (image && _selectedBundleIdentifier.length > 0) {
        CGSize target = CGSizeMake(57.0, 57.0);
        CGFloat aspect = image.size.width / MAX(image.size.height, 1.0);
        CGRect drawRect;
        if (aspect > 1.0) {
            CGFloat width = target.width * aspect;
            drawRect = CGRectMake((target.width - width) * 0.5, 0, width, target.height);
        } else {
            CGFloat height = target.height / MAX(aspect, 0.01);
            drawRect = CGRectMake(0, (target.height - height) * 0.5, target.width, height);
        }
        UIGraphicsBeginImageContextWithOptions(target, NO, 2.0);
        [image drawInRect:drawRect];
        UIImage *square = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [[NSFileManager defaultManager] createDirectoryAtPath:M3GAIconsPath withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *filename = [_selectedBundleIdentifier stringByAppendingPathExtension:@"png"];
        NSString *path = [M3GAIconsPath stringByAppendingPathComponent:filename];
        NSData *png = UIImagePNGRepresentation(square);
        if (png) [png writeToFile:path atomically:YES];
        M3GAPostChanged();
    }
    [_selectedBundleIdentifier release]; _selectedBundleIdentifier = nil;
    [self dismissModalViewControllerAnimated:YES];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [_selectedBundleIdentifier release]; _selectedBundleIdentifier = nil;
    [self dismissModalViewControllerAnimated:YES];
}
- (void)dealloc {
    [_selectedBundleIdentifier release];
    [super dealloc];
}
@end

@interface M3GInstructionsController : M3GBaseController @end
@implementation M3GInstructionsController
- (NSString *)plistName { return @"Instructions"; }
- (NSString *)paneTitle { return @"Instructions"; }
@end
@interface M3GAboutController : M3GBaseController @end
@implementation M3GAboutController
- (NSString *)plistName { return @"About"; }
- (NSString *)paneTitle { return @"Info About Me"; }
@end
