#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <math.h>

@interface SBIconView : UIView
@end

@interface M3GIconMotion : NSObject
@property(nonatomic, assign) CGPoint offset;
@property(nonatomic, assign) CGPoint velocity;
@property(nonatomic, assign) CGAffineTransform baseTransform;
@end

@implementation M3GIconMotion
@end

static const void *M3GMotionKey = &M3GMotionKey;
static CFStringRef const M3GPreferencesChanged = CFSTR("com.m3ga.m3gagravity/preferences.changed");

static BOOL M3GReadEnabled(void) {
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:
        @"/var/mobile/Library/Preferences/com.m3ga.m3gagravity.plist"];
    return [[preferences objectForKey:@"Enabled"] boolValue];
}

@interface M3GGravityController : NSObject <UIAccelerometerDelegate>
@property(nonatomic, strong) NSHashTable *iconViews;
@property(nonatomic, assign) CGPoint gravity;
@property(nonatomic, strong) CADisplayLink *displayLink;
@property(nonatomic, assign, getter=isEnabled) BOOL enabled;
+ (instancetype)sharedController;
- (void)registerIconView:(UIView *)view;
- (void)reloadPreferences;
@end

static void M3GPreferencesChangedCallback(CFNotificationCenterRef center,
                                           void *observer,
                                           CFStringRef name,
                                           const void *object,
                                           CFDictionaryRef userInfo) {
    M3GGravityController *controller = (M3GGravityController *)observer;
    [controller reloadPreferences];
}

@implementation M3GGravityController

+ (instancetype)sharedController {
    static M3GGravityController *controller = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controller = [[self alloc] init];
    });
    return controller;
}

- (id)init {
    self = [super init];
    if (self) {
        _iconViews = [NSHashTable weakObjectsHashTable];
        _enabled = M3GReadEnabled();

        UIAccelerometer *accelerometer = [UIAccelerometer sharedAccelerometer];
        accelerometer.updateInterval = 1.0 / 30.0;
        accelerometer.delegate = self;

        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        (__bridge const void *)(self),
                                        M3GPreferencesChangedCallback,
                                        M3GPreferencesChanged,
                                        NULL,
                                        CFNotificationSuspensionBehaviorCoalesce);

        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(step)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)dealloc {
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                       (__bridge const void *)(self),
                                       M3GPreferencesChanged,
                                       NULL);
}

- (void)reloadPreferences {
    BOOL wasEnabled = self.enabled;
    self.enabled = M3GReadEnabled();

    if (wasEnabled && !self.enabled) {
        [self restoreAllIcons];
    }
}

- (void)registerIconView:(UIView *)view {
    if (!view || !view.superview) return;

    M3GIconMotion *motion = objc_getAssociatedObject(view, M3GMotionKey);
    if (!motion) {
        motion = [[M3GIconMotion alloc] init];
        motion.baseTransform = view.transform;
        objc_setAssociatedObject(view, M3GMotionKey, motion, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self.iconViews addObject:view];
    }
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    if (!self.enabled) {
        self.gravity = CGPointZero;
        return;
    }

    // Ignore small sensor noise, then map tilt into UIKit's screen coordinates.
    CGFloat x = fabs(acceleration.x) < 0.07 ? 0.0 : acceleration.x;
    CGFloat y = fabs(acceleration.y) < 0.07 ? 0.0 : acceleration.y;
    self.gravity = CGPointMake(x * 650.0, -y * 650.0);
}

- (void)applyBoundsToView:(UIView *)view motion:(M3GIconMotion *)motion {
    CGRect bounds = view.superview.bounds;
    CGFloat halfWidth = CGRectGetWidth(view.bounds) * 0.5;
    CGFloat halfHeight = CGRectGetHeight(view.bounds) * 0.5;

    CGFloat minX = CGRectGetMinX(bounds) + halfWidth - view.center.x;
    CGFloat maxX = CGRectGetMaxX(bounds) - halfWidth - view.center.x;
    CGFloat minY = CGRectGetMinY(bounds) + halfHeight - view.center.y;
    CGFloat maxY = CGRectGetMaxY(bounds) - halfHeight - view.center.y;

    if (motion.offset.x < minX) {
        motion.offset = CGPointMake(minX, motion.offset.y);
        motion.velocity = CGPointMake(fabs(motion.velocity.x) * 0.58, motion.velocity.y);
    } else if (motion.offset.x > maxX) {
        motion.offset = CGPointMake(maxX, motion.offset.y);
        motion.velocity = CGPointMake(-fabs(motion.velocity.x) * 0.58, motion.velocity.y);
    }

    if (motion.offset.y < minY) {
        motion.offset = CGPointMake(motion.offset.x, minY);
        motion.velocity = CGPointMake(motion.velocity.x, fabs(motion.velocity.y) * 0.58);
    } else if (motion.offset.y > maxY) {
        motion.offset = CGPointMake(motion.offset.x, maxY);
        motion.velocity = CGPointMake(motion.velocity.x, -fabs(motion.velocity.y) * 0.58);
    }
}

- (void)resolveIconCollisions:(NSArray *)views {
    for (NSUInteger i = 0; i < views.count; i++) {
        UIView *first = [views objectAtIndex:i];
        if (!first.superview) continue;
        M3GIconMotion *a = objc_getAssociatedObject(first, M3GMotionKey);
        if (!a) continue;

        for (NSUInteger j = i + 1; j < views.count; j++) {
            UIView *second = [views objectAtIndex:j];
            // Each SpringBoard page/dock is a separate coordinate space.
            if (!second.superview || second.superview != first.superview) continue;
            M3GIconMotion *b = objc_getAssociatedObject(second, M3GMotionKey);
            if (!b) continue;

            CGFloat ax = first.center.x + a.offset.x;
            CGFloat ay = first.center.y + a.offset.y;
            CGFloat bx = second.center.x + b.offset.x;
            CGFloat by = second.center.y + b.offset.y;
            CGFloat dx = bx - ax;
            CGFloat dy = by - ay;
            CGFloat distanceSquared = dx * dx + dy * dy;

            CGFloat firstSize = MIN(CGRectGetWidth(first.bounds), CGRectGetHeight(first.bounds));
            CGFloat secondSize = MIN(CGRectGetWidth(second.bounds), CGRectGetHeight(second.bounds));
            CGFloat minimumDistance = (firstSize + secondSize) * 0.38;
            if (distanceSquared >= minimumDistance * minimumDistance) continue;

            CGFloat distance = sqrt(MAX(distanceSquared, 0.0001));
            CGFloat nx = distance < 0.01 ? 1.0 : dx / distance;
            CGFloat ny = distance < 0.01 ? 0.0 : dy / distance;
            CGFloat overlap = minimumDistance - distance;

            // Separate the icons evenly so they cannot remain interpenetrating.
            a.offset = CGPointMake(a.offset.x - nx * overlap * 0.5,
                                   a.offset.y - ny * overlap * 0.5);
            b.offset = CGPointMake(b.offset.x + nx * overlap * 0.5,
                                   b.offset.y + ny * overlap * 0.5);

            // Apply a modest elastic impulse only when the icons are moving together.
            CGFloat relativeVelocity = (b.velocity.x - a.velocity.x) * nx +
                                       (b.velocity.y - a.velocity.y) * ny;
            if (relativeVelocity < 0.0) {
                CGFloat impulse = -(1.0 + 0.48) * relativeVelocity * 0.5;
                a.velocity = CGPointMake(a.velocity.x - impulse * nx,
                                         a.velocity.y - impulse * ny);
                b.velocity = CGPointMake(b.velocity.x + impulse * nx,
                                         b.velocity.y + impulse * ny);
            }
        }
    }
}

- (void)restoreAllIcons {
    self.gravity = CGPointZero;
    for (UIView *view in self.iconViews.allObjects) {
        if (!view) continue;
        M3GIconMotion *motion = objc_getAssociatedObject(view, M3GMotionKey);
        if (!motion) continue;

        motion.offset = CGPointZero;
        motion.velocity = CGPointZero;
        view.transform = motion.baseTransform;
    }
}

- (void)step {
    if (!self.enabled) return;

    const CGFloat dt = 1.0 / 60.0;
    CGFloat damping = powf(0.94, dt * 60.0);
    NSArray *views = self.iconViews.allObjects;

    for (UIView *view in views) {
        if (!view || !view.superview) continue;
        M3GIconMotion *motion = objc_getAssociatedObject(view, M3GMotionKey);
        if (!motion) continue;

        motion.velocity = CGPointMake((motion.velocity.x + self.gravity.x * dt) * damping,
                                       (motion.velocity.y + self.gravity.y * dt) * damping);
        motion.offset = CGPointMake(motion.offset.x + motion.velocity.x * dt,
                                    motion.offset.y + motion.velocity.y * dt);
        [self applyBoundsToView:view motion:motion];
    }

    [self resolveIconCollisions:views];

    for (UIView *view in views) {
        if (!view || !view.superview) continue;
        M3GIconMotion *motion = objc_getAssociatedObject(view, M3GMotionKey);
        if (!motion) continue;

        [self applyBoundsToView:view motion:motion];
        CGAffineTransform transform = motion.baseTransform;
        transform.tx += motion.offset.x;
        transform.ty += motion.offset.y;
        view.transform = transform;
    }
}

@end

%hook SBIconView

- (void)layoutSubviews {
    %orig;
    [[M3GGravityController sharedController] registerIconView:self];
}

%end

%ctor {
    @autoreleasepool {
        %init;
    }
}
