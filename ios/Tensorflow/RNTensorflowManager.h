#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol RNTensorflowDelegate
- (void)onItemsDetected:(NSArray<NSDictionary *> *)items;
@end

@interface RNTensorflowManager : NSObject

- (NSDictionary *)constantsToExport;
+ (NSDictionary *)constants;

- (instancetype)initWithSessionQueue:(dispatch_queue_t)sessionQueue delegate:(id <RNTensorflowDelegate>)delegate;

- (void)setIsEnabled:(id)json;

- (void)startSession:(AVCaptureSession *)session withPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer;
- (void)stopSession;

@end
