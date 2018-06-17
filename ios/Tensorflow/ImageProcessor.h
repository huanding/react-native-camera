#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface ImageProcessor: NSObject
- (id) initWithData:(NSString *)modelUri labels:(NSString *)labelUri;
- (void) reset;
- (void) close;
- (NSArray<NSDictionary *> *) recognizeImage:(CGImageRef)imageRef orientation:(CGImagePropertyOrientation)orientation;
@end
