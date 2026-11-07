#import <Foundation/Foundation.h>
#import <Preferences/PSListController.h>

@interface M3GRootListController : PSListController {
    NSArray *_m3gSpecifiers;
}
@end

@implementation M3GRootListController

- (NSArray *)specifiers {
    if (!_m3gSpecifiers) {
        _m3gSpecifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _m3gSpecifiers;
}

@end
