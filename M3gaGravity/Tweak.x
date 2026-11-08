#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <math.h>
#import <dispatch/dispatch.h>
#import <stdint.h>

@interface SBIconView : UIView
@end

@interface M3GIconMotion : NSObject
@property(nonatomic, assign) CGPoint offset;
@property(nonatomic, assign) CGPoint velocity;
@property(nonatomic, assign) CGAffineTransform baseTransform;
@property(nonatomic, assign, getter=isDragging) BOOL dragging;
@property(nonatomic, assign) CGPoint dragOffsetAnchor;
@end

@implementation M3GIconMotion
@end

static const void *M3GMotionKey = &M3GMotionKey;
static const void *M3GPanKey = &M3GPanKey;
static CFStringRef const M3GPreferencesChanged = CFSTR("com.m3ga.m3gagravity/preferences.changed");

static BOOL M3GReadEnabled(void) {
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:
        @"/var/mobile/Library/Preferences/com.m3ga.m3gagravity.plist"];
    return [[preferences objectForKey:@"Enabled"] boolValue];
}

static const CGFloat M3GGravityAcceleration = 720.0;
static const CGFloat M3GMaximumFallSpeed = 1050.0;

@interface M3GGravityController : NSObject <UIGestureRecognizerDelegate>
@property(nonatomic, strong) NSHashTable *iconViews;
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
    M3GGravityController *controller = (__bridge M3GGravityController *)observer;
    dispatch_async(dispatch_get_main_queue(), ^{
        [controller reloadPreferences];
    });
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
    } else if (!wasEnabled && self.enabled) {
        for (UIView *view in self.iconViews.allObjects) {
            M3GIconMotion *motion = objc_getAssociatedObject(view, M3GMotionKey);
            if (motion) motion.velocity = CGPointZero;
        }
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
        motion.velocity = CGPointZero;
    }

    // A non-cancelling pan recognizer preserves ordinary icon taps. A drag
    // moves the icon directly; releasing it gives the icon the pan velocity.
    if (!objc_getAssociatedObject(view, M3GPanKey)) {
        UIPanGestureRecognizer *pan =
            [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleIconPan:)];
        pan.delegate = self;
        pan.maximumNumberOfTouches = 1;
        // Once a real drag starts, take ownership of the touch so SpringBoard's
        // icon/page recognizers cannot steal the drag. Stationary taps still pass.
        pan.cancelsTouchesInView = YES;
        pan.delaysTouchesBegan = NO;
        pan.delaysTouchesEnded = NO;
        [view addGestureRecognizer:pan];
        objc_setAssociatedObject(view, M3GPanKey, pan, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (!self.enabled || !gestureRecognizer.view.superview) return NO;
    CGPoint velocity = [(UIPanGestureRecognizer *)gestureRecognizer
                        velocityInView:gestureRecognizer.view.superview];
    return hypotf(velocity.x, velocity.y) > 8.0;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
 shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // Do not block SpringBoard's own icon and page gestures.
    return YES;
}

- (void)handleIconPan:(UIPanGestureRecognizer *)pan {
    if (!self.enabled) return;

    UIView *view = pan.view;
    if (!view || !view.superview) return;

    M3GIconMotion *motion = objc_getAssociatedObject(view, M3GMotionKey);
    if (!motion) {
        [self registerIconView:view];
        motion = objc_getAssociatedObject(view, M3GMotionKey);
        if (!motion) return;
    }

    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            motion.dragging = YES;
            motion.velocity = CGPointZero;
            motion.dragOffsetAnchor = motion.offset;
            break;

        case UIGestureRecognizerStateChanged: {
            CGPoint translation = [pan translationInView:view.superview];
            motion.offset = CGPointMake(motion.dragOffsetAnchor.x + translation.x,
                                        motion.dragOffsetAnchor.y + translation.y);
            [self applyBoundsToView:view motion:motion];
            [self applyTransformToView:view motion:motion];
            break;
        }

        case UIGestureRecognizerStateEnded: {
            CGPoint velocity = [pan velocityInView:view.superview];
            CGFloat speed = hypotf(velocity.x, velocity.y);
            if (speed > 1050.0) {
                CGFloat scale = 1050.0 / speed;
                velocity = CGPointMake(velocity.x * scale, velocity.y * scale);
            }
            motion.velocity = CGPointMake(velocity.x * 0.88, velocity.y * 0.88);
            motion.dragging = NO;
            break;
        }

        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            motion.dragging = NO;
            // A cancelled drag simply resumes falling from its current position.
            break;

        default:
            break;
    }
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
        if (motion.velocity.x < 0.0)
            motion.velocity = CGPointMake(fabs(motion.velocity.x) * 0.82, motion.velocity.y);
    } else if (motion.offset.x > maxX) {
        motion.offset = CGPointMake(maxX, motion.offset.y);
        if (motion.velocity.x > 0.0)
            motion.velocity = CGPointMake(-fabs(motion.velocity.x) * 0.82, motion.velocity.y);
    }

    if (motion.offset.y < minY) {
        motion.offset = CGPointMake(motion.offset.x, minY);
        if (motion.velocity.y < 0.0)
            motion.velocity = CGPointMake(motion.velocity.x, fabs(motion.velocity.y) * 0.82);
    } else if (motion.offset.y > maxY) {
        motion.offset = CGPointMake(motion.offset.x, maxY);
        if (motion.velocity.y > 0.0)
            // The bottom is the floor: a small bounce, then settle instead of
            // continuously ricocheting around the screen.
            CGFloat impact = fabs(motion.velocity.y);
            CGFloat rebound = impact > 95.0 ? impact * 0.16 : 0.0;
            motion.velocity = CGPointMake(motion.velocity.x, -rebound);
    }
}

- (void)applyTransformToView:(UIView *)view motion:(M3GIconMotion *)motion {
    CGAffineTransform transform = motion.baseTransform;
    transform.tx += motion.offset.x;
    transform.ty += motion.offset.y;
    view.transform = transform;
}

- (void)resolveIconCollisions:(NSArray *)views {
    for (NSUInteger i = 0; i < views.count; i++) {
        UIView *first = [views objectAtIndex:i];
        if (!first.superview) continue;
        M3GIconMotion *a = objc_getAssociatedObject(first, M3GMotionKey);
        if (!a || a.isDragging) continue;

        for (NSUInteger j = i + 1; j < views.count; j++) {
            UIView *second = [views objectAtIndex:j];
            if (!second.superview || second.superview != first.superview) continue;
            M3GIconMotion *b = objc_getAssociatedObject(second, M3GMotionKey);
            if (!b || b.isDragging) continue;

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

            BOOL centersOverlap = distanceSquared < 0.0001;
            CGFloat distance = centersOverlap ? 0.01 : sqrtf(distanceSquared);
            CGFloat nx = centersOverlap ? 1.0 : dx / distance;
            CGFloat ny = centersOverlap ? 0.0 : dy / distance;
            CGFloat overlap = minimumDistance - distance;

            a.offset = CGPointMake(a.offset.x - nx * overlap * 0.5,
                                   a.offset.y - ny * overlap * 0.5);
            b.offset = CGPointMake(b.offset.x + nx * overlap * 0.5,
                                   b.offset.y + ny * overlap * 0.5);

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
    for (UIView *view in self.iconViews.allObjects) {
        if (!view) continue;
        M3GIconMotion *motion = objc_getAssociatedObject(view, M3GMotionKey);
        if (!motion) continue;

        motion.offset = CGPointZero;
        motion.velocity = CGPointZero;
        motion.dragging = NO;
        view.transform = motion.baseTransform;
    }
}

- (void)step {
    if (!self.enabled) return;

    const CGFloat dt = 1.0 / 60.0;
    const CGFloat damping = powf(0.999, dt * 60.0);
    NSArray *views = self.iconViews.allObjects;

    for (UIView *view in views) {
        if (!view || !view.superview) continue;
        M3GIconMotion *motion = objc_getAssociatedObject(view, M3GMotionKey);
        if (!motion || motion.isDragging) continue;

        // Constant downward acceleration creates real falling motion. Icons
        // naturally come to rest on the bottom edge instead of wandering forever.
        motion.velocity = CGPointMake(motion.velocity.x * damping,
            MIN(M3GMaximumFallSpeed, motion.velocity.y + M3GGravityAcceleration * dt));

        CGFloat maxY = CGRectGetMaxY(view.superview.bounds)
            - CGRectGetHeight(view.bounds) * 0.5 - view.center.y;
        BOOL restingOnFloor = motion.offset.y >= maxY - 1.0;
        if (restingOnFloor) {
            motion.velocity = CGPointMake(motion.velocity.x * 0.86, motion.velocity.y);
            if (fabs(motion.velocity.x) < 7.0)
                motion.velocity = CGPointMake(0.0, motion.velocity.y);
        }

        motion.offset = CGPointMake(motion.offset.x + motion.velocity.x * dt,
                                    motion.offset.y + motion.velocity.y * dt);
        [self applyBoundsToView:view motion:motion];
    }

    [self resolveIconCollisions:views];

    for (UIView *view in views) {
        if (!view || !view.superview) continue;
        M3GIconMotion *motion = objc_getAssociatedObject(view, M3GMotionKey);
        if (!motion || motion.isDragging) continue;
        [self applyBoundsToView:view motion:motion];
        [self applyTransformToView:view motion:motion];
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
