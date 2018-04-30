#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface ImageProcessor: NSObject
- (id) initWithData:(NSString *)modelUri labels:(NSString *)labelUri;
- (void) reset;
- (NSArray<NSDictionary *> *) recognizeImage:(CGImageRef)imageRef orientation:(CGImagePropertyOrientation)orientation;
- (NSArray<NSDictionary *> *) recognizeFrame:(CVImageBufferRef)imageRef orientation:(UIDeviceOrientation)orientation;
@end
