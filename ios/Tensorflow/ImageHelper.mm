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

+ (NSString *) base64Image:(CGImageRef)imageRef {
    UIImage* image = [[UIImage alloc] initWithCGImage:imageRef];
    return [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
}

+ (NSString *) toDateTime:(CMTime)cmTime {
    float seconds = CMTimeGetSeconds(cmTime);
    NSDate* d = [[NSDate alloc] initWithTimeIntervalSinceNow:seconds];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    return[dateFormatter stringFromDate:d];
}
@end
