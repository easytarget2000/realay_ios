#import <Foundation/Foundation.h>

@interface LBClock : NSObject

+ (instancetype)sharedClock;
// since device boot or something. Monotonically increasing, unaffected by date and time settings
- (NSTimeInterval)absoluteTime;

- (NSTimeInterval)machAbsoluteToTimeInterval:(uint64_t)machAbsolute;

@end