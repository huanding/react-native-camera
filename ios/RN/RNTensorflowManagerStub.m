#import "RNTensorflowManagerStub.h"
#import <React/RCTLog.h>

@implementation RNTensorflowManagerStub

- (NSDictionary *)constantsToExport {
    return [[self class] constants];
}

+ (NSDictionary *)constants {
    return @{@"Model" : @{},
             @"Label" : @{},
             };
}

- (instancetype)initWithSessionQueue:(dispatch_queue_t)sessionQueue delegate:(id <RNTensorflowDelegate>)delegate {
    self = [super init];
    return self;
}

- (void)setIsEnabled:(id)json { }

- (void)setModel:(id)json { }

- (void)setLabels:(id)json { }

- (void)startSession:(AVCaptureSession *)session withPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer {
    RCTLogWarn(@"Tensorflow not integrated, stub used!");
}
- (void)stopSession { }

@end

