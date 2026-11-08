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
@property(nonatomic, assign) CGPoint lastDragLocation;
@property(nonatomic, assign) CFTimeInterval lastDragTimestamp;
@end

@implementation M3GIconMotion
@end

static const void *M3GMotionKey = &M3GMotionKey;
static const void *M3GPanKey = &M3GPanKey;
static CFStringRef const M3GPreferencesChanged = CFSTR("com.m3ga.m3gagravity/preferences.changed");

static BOOL M3GReadEnabled(void) {
    NSDictionary *saved = [NSDictionary dictionaryWithContentsOfFile:
        @"/var/mobile/Library/Preferences/com.m3ga.m3gagravity.plist"];

    // Migration from 0.2.6: switch the automatic-start prototype OFF once.
    // The user can then enable it manually from the existing Settings pane.
    if (![[saved objectForKey:@"M3GDefaultOffConfigured"] boolValue]) {
        NSMutableDictionary *updated = saved ? [saved mutableCopy] : [NSMutableDictionary dictionary];
        [updated setObject:[NSNumber numberWithBool:NO] forKey:@"Enabled"];
        [updated setObject:[NSNumber numberWithBool:YES] forKey:@"M3GDefaultOffConfigured"];
        [updated writeToFile:@"/var/mobile/Library/Preferences/com.m3ga.m3gagravity.plist" atomically:YES];
        return NO;
    }

    id enabled = [saved objectForKey:@"Enabled"];
    return enabled ? [enabled boolValue] : NO;
}

static const CGFloat M3GGravityAcceleration = 760.0;
static const CGFloat M3GMaximumFallSpeed = 980.0;
static const CGFloat M3GIconRestitution = 0.10;
static const CGFloat M3GFloorRestitution = 0.12;
static const CGFloat M3GCollisionSlop = 0.35;
static const NSUInteger M3GCollisionIterations = 8;

static CGFloat M3GInitialHorizontalSpeed(void) {
    // A small sideways impulse makes icons tumble into a heap rather than
    // all landing in a perfectly straight row.
    return (CGFloat)((int)arc4random_uniform(111) - 55);
}

static CGFloat M3GCollisionRadius(UIView *view) {
    return MIN(CGRectGetWidth(view.bounds), CGRectGetHeight(view.bounds)) * 0.46;
}

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
            if (motion) motion.velocity = CGPointMake(M3GInitialHorizontalSpeed(), 0.0);
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
        motion.velocity = self.enabled
            ? CGPointMake(M3GInitialHorizontalSpeed(), 0.0)
            : CGPointZero;
    }

    // A short long-press differentiates picking up an icon from a normal
    // horizontal Home Screen swipe. Quick swipes therefore remain SpringBoard's.
    if (!objc_getAssociatedObject(view, M3GPanKey)) {
        UILongPressGestureRecognizer *drag =
            [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleIconPan:)];
        drag.delegate = self;
        drag.minimumPressDuration = 0.18;
        drag.allowableMovement = 10.0;
        drag.cancelsTouchesInView = YES;
        drag.delaysTouchesBegan = NO;
        drag.delaysTouchesEnded = NO;
        [view addGestureRecognizer:drag];

        // Do not force SpringBoard's built-in recognizers to wait for ours.
        // A normal page swipe moves before the long-press can begin.
        objc_setAssociatedObject(view, M3GPanKey, drag, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return self.enabled && gestureRecognizer.view.superview != nil;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
 shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // A moving icon belongs to the user's drag rather than a competing
    // SpringBoard icon-rearrange gesture. Stationary taps still pass.
    return NO;
}

- (void)handleIconPan:(UILongPressGestureRecognizer *)pan {
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
            motion.lastDragLocation = [pan locationInView:view.superview];
            motion.lastDragTimestamp = CACurrentMediaTime();
            break;

        case UIGestureRecognizerStateChanged: {
            CGPoint location = [pan locationInView:view.superview];
            CFTimeInterval now = CACurrentMediaTime();
            CFTimeInterval elapsed = now - motion.lastDragTimestamp;
            CGFloat dx = location.x - motion.lastDragLocation.x;
            CGFloat dy = location.y - motion.lastDragLocation.y;

            motion.offset = CGPointMake(motion.offset.x + dx,
                                        motion.offset.y + dy);

            if (elapsed > 0.001) {
                CGPoint instantVelocity = CGPointMake(dx / elapsed, dy / elapsed);
                CGFloat speed = hypotf(instantVelocity.x, instantVelocity.y);
                if (speed > 1050.0) {
                    CGFloat scale = 1050.0 / speed;
                    instantVelocity = CGPointMake(instantVelocity.x * scale,
                                                  instantVelocity.y * scale);
                }
                motion.velocity = CGPointMake(motion.velocity.x * 0.35 + instantVelocity.x * 0.65,
                                              motion.velocity.y * 0.35 + instantVelocity.y * 0.65);
            }

            motion.lastDragLocation = location;
            motion.lastDragTimestamp = now;
            [self applyBoundsToView:view motion:motion];
            [self applyTransformToView:view motion:motion];
            break;
        }

        case UIGestureRecognizerStateEnded: {
            motion.velocity = CGPointMake(motion.velocity.x * 0.90,
                                          motion.velocity.y * 0.90);
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
            motion.velocity = CGPointMake(fabs(motion.velocity.x) * 0.24, motion.velocity.y);
    } else if (motion.offset.x > maxX) {
        motion.offset = CGPointMake(maxX, motion.offset.y);
        if (motion.velocity.x > 0.0)
            motion.velocity = CGPointMake(-fabs(motion.velocity.x) * 0.24, motion.velocity.y);
    }

    if (motion.offset.y < minY) {
        motion.offset = CGPointMake(motion.offset.x, minY);
        if (motion.velocity.y < 0.0)
            motion.velocity = CGPointMake(motion.velocity.x,
                fabs(motion.velocity.y) * M3GFloorRestitution);
    } else if (motion.offset.y > maxY) {
        motion.offset = CGPointMake(motion.offset.x, maxY);
        if (motion.velocity.y > 0.0) {
            CGFloat impact = fabs(motion.velocity.y);
            CGFloat rebound = impact > 85.0 ? impact * M3GFloorRestitution : 0.0;
            motion.velocity = CGPointMake(motion.velocity.x * 0.90, -rebound);
        }
    }
}

- (void)applyTransformToView:(UIView *)view motion:(M3GIconMotion *)motion {
    CGAffineTransform transform = motion.baseTransform;
    transform.tx += motion.offset.x;
    transform.ty += motion.offset.y;
    view.transform = transform;
}

- (BOOL)isVisibleForPhysics:(UIView *)view {
    if (!view || !view.superview || !view.window || view.hidden || view.alpha < 0.02)
        return NO;

    // A hidden page or a page fully outside the viewport is left untouched.
    // convertRect includes the page-scroll container's current animation transform.
    for (UIView *ancestor = view.superview; ancestor && ancestor != view.window;
         ancestor = ancestor.superview) {
        if (ancestor.hidden || ancestor.alpha < 0.02) return NO;
    }

    CGRect frameInWindow = [view convertRect:view.bounds toView:view.window];
    return CGRectIntersectsRect(frameInWindow, view.window.bounds);
}

- (NSArray *)visibleIconViews {
    NSMutableArray *visible = [NSMutableArray array];
    for (UIView *view in self.iconViews.allObjects) {
        if ([self isVisibleForPhysics:view]) [visible addObject:view];
    }
    return visible;
}

- (void)resolveIconCollisions:(NSArray *)views {
    for (NSUInteger pass = 0; pass < M3GCollisionIterations; pass++) {
        for (NSUInteger i = 0; i < views.count; i++) {
            UIView *first = [views objectAtIndex:i];
            if (!first.superview) continue;
            M3GIconMotion *a = objc_getAssociatedObject(first, M3GMotionKey);
            if (!a) continue;

            for (NSUInteger j = i + 1; j < views.count; j++) {
                UIView *second = [views objectAtIndex:j];
                if (!second.superview || second.superview != first.superview) continue;
                M3GIconMotion *b = objc_getAssociatedObject(second, M3GMotionKey);
                if (!b) continue;

                // A finger-held icon is an immovable obstacle; other icons
                // can collide with it instead of passing through it.
                CGFloat inverseMassA = a.isDragging ? 0.0 : 1.0;
                CGFloat inverseMassB = b.isDragging ? 0.0 : 1.0;
                CGFloat inverseMassSum = inverseMassA + inverseMassB;
                if (inverseMassSum <= 0.0) continue;

                CGFloat dx = (second.center.x + b.offset.x) - (first.center.x + a.offset.x);
                CGFloat dy = (second.center.y + b.offset.y) - (first.center.y + a.offset.y);
                CGFloat distanceSquared = dx * dx + dy * dy;
                CGFloat minimumDistance = M3GCollisionRadius(first) + M3GCollisionRadius(second);
                if (distanceSquared >= minimumDistance * minimumDistance) continue;

                BOOL centersOverlap = distanceSquared < 0.0001;
                CGFloat distance = centersOverlap ? 0.01 : sqrtf(distanceSquared);
                CGFloat nx = centersOverlap ? 1.0 : dx / distance;
                CGFloat ny = centersOverlap ? 0.0 : dy / distance;
                CGFloat overlap = minimumDistance - distance;

                // Iterative positional correction keeps icon circles from
                // interpenetrating and creates stable piles on the floor.
                CGFloat correction = MAX(overlap - M3GCollisionSlop, 0.0)
                    * 0.78 / inverseMassSum;
                a.offset = CGPointMake(a.offset.x - nx * correction * inverseMassA,
                                       a.offset.y - ny * correction * inverseMassA);
                b.offset = CGPointMake(b.offset.x + nx * correction * inverseMassB,
                                       b.offset.y + ny * correction * inverseMassB);

                CGFloat relativeX = b.velocity.x - a.velocity.x;
                CGFloat relativeY = b.velocity.y - a.velocity.y;
                CGFloat normalVelocity = relativeX * nx + relativeY * ny;
                if (normalVelocity < 0.0) {
                    CGFloat impulse = -(1.0 + M3GIconRestitution)
                        * normalVelocity / inverseMassSum;
                    a.velocity = CGPointMake(a.velocity.x - impulse * nx * inverseMassA,
                                             a.velocity.y - impulse * ny * inverseMassA);
                    b.velocity = CGPointMake(b.velocity.x + impulse * nx * inverseMassB,
                                             b.velocity.y + impulse * ny * inverseMassB);

                    // Friction at contact removes endless sideways sliding.
                    relativeX = b.velocity.x - a.velocity.x;
                    relativeY = b.velocity.y - a.velocity.y;
                    CGFloat normalAfter = relativeX * nx + relativeY * ny;
                    CGFloat tangentX = relativeX - normalAfter * nx;
                    CGFloat tangentY = relativeY - normalAfter * ny;
                    CGFloat tangentLength = hypotf(tangentX, tangentY);
                    if (tangentLength > 0.001) {
                        tangentX /= tangentLength;
                        tangentY /= tangentLength;
                        CGFloat tangentImpulse = -(relativeX * tangentX + relativeY * tangentY)
                            / inverseMassSum;
                        CGFloat maxFriction = impulse * 0.62;
                        tangentImpulse = MAX(-maxFriction, MIN(maxFriction, tangentImpulse));
                        a.velocity = CGPointMake(a.velocity.x - tangentImpulse * tangentX * inverseMassA,
                                                 a.velocity.y - tangentImpulse * tangentY * inverseMassA);
                        b.velocity = CGPointMake(b.velocity.x + tangentImpulse * tangentX * inverseMassB,
                                                 b.velocity.y + tangentImpulse * tangentY * inverseMassB);
                    }
                }
            }
        }

        // Reapply walls and floor after every solver pass so the bottom
        // support remains solid while the heap is being resolved.
        for (UIView *view in views) {
            if (!view || !view.superview) continue;
            M3GIconMotion *motion = objc_getAssociatedObject(view, M3GMotionKey);
            if (motion && !motion.isDragging) [self applyBoundsToView:view motion:motion];
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
    const CGFloat airDamping = 0.998;

    // Only simulate icons currently inside the visible SpringBoard viewport.
    // Off-screen pages keep their last positions and are simulated when shown.
    NSArray *views = [self visibleIconViews];

    for (UIView *view in views) {
        if (!view || !view.superview) continue;
        M3GIconMotion *motion = objc_getAssociatedObject(view, M3GMotionKey);
        if (!motion || motion.isDragging) continue;

        CGFloat maxY = CGRectGetMaxY(view.superview.bounds)
            - CGRectGetHeight(view.bounds) * 0.5 - view.center.y;
        BOOL onFloor = motion.offset.y >= maxY - 0.75;

        motion.velocity = CGPointMake(motion.velocity.x * airDamping,
            MIN(M3GMaximumFallSpeed, motion.velocity.y + M3GGravityAcceleration * dt));

        if (onFloor && motion.velocity.y >= 0.0) {
            // A landed icon stops accelerating downward and loses horizontal
            // speed through ground friction until it rests.
            motion.velocity = CGPointMake(motion.velocity.x * 0.84, 0.0);
            if (fabs(motion.velocity.x) < 4.0)
                motion.velocity = CGPointMake(0.0, 0.0);
        }

        motion.offset = CGPointMake(motion.offset.x + motion.velocity.x * dt,
                                    motion.offset.y + motion.velocity.y * dt);
        [self applyBoundsToView:view motion:motion];
    }

    [self resolveIconCollisions:views];

    for (UIView *view in views) {
        if (!view || !view.superview) continue;
        M3GIconMotion *motion = objc_getAssociatedObject(view, M3GMotionKey);
        if (!motion) continue;
        if (!motion.isDragging) [self applyBoundsToView:view motion:motion];
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
