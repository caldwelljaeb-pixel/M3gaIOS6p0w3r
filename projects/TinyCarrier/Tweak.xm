#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// iOS 5/6 SpringBoard status-bar data manager.
// This selector is used by classic carrier/logo tweaks such as Zeppelin.
@interface SBStatusBarDataManager : NSObject
- (BOOL)_getServiceImageNames:(NSString ***)names
                    directory:(NSString **)directory
                  forOperator:(NSString *)operatorName
           statusBarCarrierName:(NSString **)carrierName;
@end

static NSString * const kTinyCarrierText = @"M3ga";

%hook SBStatusBarDataManager

- (BOOL)_getServiceImageNames:(NSString ***)names
                    directory:(NSString **)directory
                  forOperator:(NSString *)operatorName
           statusBarCarrierName:(NSString **)carrierName
{
    // Supply our own carrier label while allowing SpringBoard to obtain
    // its normal carrier artwork and directory from the original method.
    if (carrierName != NULL) {
        *carrierName = kTinyCarrierText;
        return %orig(names, directory, operatorName, NULL);
    }

    return %orig(names, directory, operatorName, NULL);
}

%end

%ctor {
    Class manager = objc_getClass("SBStatusBarDataManager");
    SEL selector = @selector(_getServiceImageNames:directory:forOperator:statusBarCarrierName:);

    // Only install on systems that expose the classic iOS 5/6 selector.
    if (manager && [manager instancesRespondToSelector:selector]) {
        %init;
    }
}
