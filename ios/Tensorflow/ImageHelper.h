#include <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ImageHelper: NSObject {}

+ (CGImagePropertyOrientation) toOrientation:(UIDeviceOrientation)orientation;
+ (NSString *) base64Image:(CGImageRef)imageRef;
+ (NSString *) toDateTime:(CMTime)cmTime;
@end
