#import "ImageHelper.h"

@implementation ImageHelper {}

+ (CGImagePropertyOrientation) toOrientation:(UIDeviceOrientation)orientation
{
    switch(orientation) {
        case UIDeviceOrientationPortrait:
            return kCGImagePropertyOrientationUp;
        case UIDeviceOrientationPortraitUpsideDown:
            return kCGImagePropertyOrientationDown;
        case UIDeviceOrientationLandscapeLeft:
            return kCGImagePropertyOrientationLeft;
        case UIDeviceOrientationLandscapeRight:
            return kCGImagePropertyOrientationRight;
        default:
            return kCGImagePropertyOrientationUp;
    }
}

+ (NSString *) toOrientationString:(CGImagePropertyOrientation)orientation {
    switch(orientation) {
        case kCGImagePropertyOrientationUp:
            return @"kCGImagePropertyOrientationUp";
        case kCGImagePropertyOrientationUpMirrored:
            return @"kCGImagePropertyOrientationUpMirrored";
        case kCGImagePropertyOrientationDown:
            return @"kCGImagePropertyOrientationDown";
        case kCGImagePropertyOrientationDownMirrored:
            return @"kCGImagePropertyOrientationDownMirrored";
        case kCGImagePropertyOrientationLeftMirrored:
            return @"kCGImagePropertyOrientationLeftMirrored";
        case kCGImagePropertyOrientationRight:
            return @"kCGImagePropertyOrientationRight";
        case kCGImagePropertyOrientationRightMirrored:
            return @"kCGImagePropertyOrientationRightMirrored";
        case kCGImagePropertyOrientationLeft:
            return @"kCGImagePropertyOrientationLeft";
        default:
            return @"UnknownOrientation";
    }
}

+ (NSString *) base64Image:(CGImageRef)imageRef {
    UIImage* image = [[UIImage alloc] initWithCGImage:imageRef];
    NSString * base64 = [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    return [NSString stringWithFormat:@"data:image/png;base64,%@", base64];
}

+ (NSString *) toDateTime:(CMTime)cmTime {
    float seconds = CMTimeGetSeconds(cmTime);
    NSDate* d = [[NSDate alloc] initWithTimeIntervalSinceNow:seconds];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    return[dateFormatter stringFromDate:d];
}
@end
