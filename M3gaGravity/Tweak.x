#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <math.h>

@interface SBIconView : UIView
@end

@interface M3GIconMotion : NSObject
@property(nonatomic, assign) CGPoint offset;
@property(nonatomic, assign) CGPoint velocity;
@property(nonatomic, assign) CGPoint baseCenter;
@end

@implementation M3GIconMotion
@end

static const void *M3GMotionKey = &M3GMotionKey;

@interface M3GGravityController : NSObject <UIAccelerometerDelegate>
@property(nonatomic, strong) NSHashTable *iconViews;
@property(nonatomic, assign) CGPoint gravity;
@property(nonatomic, strong) CADisplayLink *displayLink;
+ (instancetype)sharedController;
- (void)registerIconView:(UIView *)view;
@end

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

        UIAccelerometer *accelerometer = [UIAccelerometer sharedAccelerometer];
        accelerometer.updateInterval = 1.0 / 30.0;
        accelerometer.delegate = self;

        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(step)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)registerIconView:(UIView *)view {
    if (!view || !view.superview) return;

    M3GIconMotion *motion = objc_getAssociatedObject(view, M3GMotionKey);
    if (!motion) {
        motion = [[M3GIconMotion alloc] init];
        motion.baseCenter = view.center;
        objc_setAssociatedObject(view, M3GMotionKey, motion, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self.iconViews addObject:view];
    }
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    // Keep a gentle dead zone so tiny sensor noise does not move the icons.
    CGFloat x = fabs(acceleration.x) < 0.06 ? 0.0 : acceleration.x;
    CGFloat y = fabs(acceleration.y) < 0.06 ? 0.0 : acceleration.y;

    // The sign is chosen for UIKit's screen coordinate system; we'll tune it on-device.
    self.gravity = CGPointMake(x * 1050.0, -y * 1050.0);
}

- (void)step {
    const CGFloat dt = 1.0 / 60.0;
    for (UIView *view in self.iconViews.allObjects) {
        if (!view || !view.superview) continue;

        M3GIconMotion *motion = objc_getAssociatedObject(view, M3GMotionKey);
        if (!motion) continue;

        motion.velocity = CGPointMake(motion.velocity.x + self.gravity.x * dt,
                                       motion.velocity.y + self.gravity.y * dt);
        motion.velocity = CGPointMake(motion.velocity.x * 0.985,
                                       motion.velocity.y * 0.985);
        motion.offset = CGPointMake(motion.offset.x + motion.velocity.x * dt,
                                    motion.offset.y + motion.velocity.y * dt);

        CGRect bounds = view.superview.bounds;
        CGFloat minX = CGRectGetMinX(bounds) + CGRectGetMidX(view.bounds) - motion.baseCenter.x;
        CGFloat maxX = CGRectGetMaxX(bounds) - CGRectGetMidX(view.bounds) - motion.baseCenter.x;
        CGFloat minY = CGRectGetMinY(bounds) + CGRectGetMidY(view.bounds) - motion.baseCenter.y;
        CGFloat maxY = CGRectGetMaxY(bounds) - CGRectGetMidY(view.bounds) - motion.baseCenter.y;

        if (motion.offset.x < minX) {
            motion.offset = CGPointMake(minX, motion.offset.y);
            motion.velocity = CGPointMake(fabs(motion.velocity.x) * 0.62, motion.velocity.y);
        } else if (motion.offset.x > maxX) {
            motion.offset = CGPointMake(maxX, motion.offset.y);
            motion.velocity = CGPointMake(-fabs(motion.velocity.x) * 0.62, motion.velocity.y);
        }

        if (motion.offset.y < minY) {
            motion.offset = CGPointMake(motion.offset.x, minY);
            motion.velocity = CGPointMake(motion.velocity.x, fabs(motion.velocity.y) * 0.62);
        } else if (motion.offset.y > maxY) {
            motion.offset = CGPointMake(motion.offset.x, maxY);
            motion.velocity = CGPointMake(motion.velocity.x, -fabs(motion.velocity.y) * 0.62);
        }

        view.transform = CGAffineTransformMakeTranslation(motion.offset.x, motion.offset.y);
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
