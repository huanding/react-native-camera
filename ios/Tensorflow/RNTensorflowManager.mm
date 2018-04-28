
#import <React/RCTConvert.h>
#import "RNCamera.h"
#import "RNTensorflowManager.h"

#ifdef __cplusplus
#include <types_c.h>
#import <opencv2/highgui/highgui.hpp>
#import <opencv2/videoio/cap_ios.h>
using namespace cv;
#endif

@interface RNTensorflowManager() <AVCaptureVideoDataOutputSampleBufferDelegate> {
    dispatch_queue_t videoDataOutputQueue;
    UIDeviceOrientation deviceOrientation;
}

@property (nonatomic, strong) AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic, weak) AVCaptureSession *session;
@property (nonatomic, weak) dispatch_queue_t sessionQueue;
@property (nonatomic, assign, getter=isConnected) BOOL connected;
@property (nonatomic, weak) id <RNTensorflowDelegate> delegate;
@property (nonatomic, weak) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, assign, getter=isEnabled) BOOL enabled;
@property (atomic) BOOL isProcessingFrame;
@end

@implementation RNTensorflowManager

- (NSDictionary *)constantsToExport
{
    return [[self class] constants];
}

+ (NSDictionary *)constants
{
    return @{@"Mode" : @{},
             @"Landmarks" : @{},
             @"Classifications" : @{}};
}

- (instancetype)initWithSessionQueue:(dispatch_queue_t)sessionQueue delegate:(id <RNTensorflowDelegate>)delegate
{
    if (self = [super init]) {
        _delegate = delegate;
        _sessionQueue = sessionQueue;
    }
    return self;
}

# pragma mark Properties setters

- (void)setSession:(AVCaptureSession *)session
{
    _session = session;
}

# pragma mark - JS properties setters

- (void)setIsEnabled:(id)json
{
    BOOL newEnabled = [RCTConvert BOOL:json];

    if ([self isEnabled] != newEnabled) {
        [self _runBlockIfQueueIsPresent:^{
            if ([self isEnabled]) {
                if (_dataOutput) {
                    [self _setConnectionsEnabled:true];
                } else {
                    [self tryEnabling];
                }
            } else {
                [self _setConnectionsEnabled:false];
            }
        }];
    }
}

# pragma mark - Public API

- (void)startSession:(AVCaptureSession *)session withPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer
{
    _session = session;
    _previewLayer = previewLayer;
    [self tryEnabling];
}

- (void)tryEnabling
{
    if (!_session) {
        return;
    }

    [_session beginConfiguration];

    if ([self isEnabled]) {
        @try {

            AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
            NSDictionary *videoOutputSettings = @{
                (NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_24RGB)
            };
            [videoDataOutput setVideoSettings:videoOutputSettings];
            videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
            videoDataOutputQueue = dispatch_queue_create("tensorflow-video-queue", NULL);
            [videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];

            if ([_session canAddOutput:videoDataOutput]) {
                [_session addOutput:videoDataOutput];
                _dataOutput = videoDataOutput;
                _connected = true;
            }

            [self _notifyOfFaces:nil];
        } @catch (NSException *exception) {
            RCTLogWarn(@"%@", [exception description]);
        }
    }

    [_session commitConfiguration];
}

- (void)stopSession
{
    if (!_session) {
        return;
    }

    [_session beginConfiguration];

    if ([_session.outputs containsObject:_dataOutput]) {
        [_session removeOutput:_dataOutput];
        [_dataOutput setSampleBufferDelegate:nil queue:NULL];
        _dataOutput = nil;
        _connected = false;
    }

    [_session commitConfiguration];

    if ([self isEnabled]) {
        [self _notifyOfFaces:nil];
    }
}

# pragma mark Private API

- (void)_setConnectionsEnabled:(BOOL)enabled
{
    if (!_dataOutput) {
        return;
    }
    for (AVCaptureConnection *connection in _dataOutput.connections) {
        connection.enabled = enabled;
    }
}

- (void)_notifyOfFaces:(NSArray<NSDictionary *> *)faces
{
    NSArray<NSDictionary *> *reportableFaces = faces == nil ? @[] : faces;
    if ([reportableFaces count] > 0) {
        if (_delegate) {
            [_delegate onItemsDetected:reportableFaces];
        }
    }
}

# pragma mark - Utilities

- (void)_runBlockIfQueueIsPresent:(void (^)(void))block
{
    if (_sessionQueue) {
        dispatch_async(_sessionQueue, block);
    }
}

#pragma mark - OpenCV

void rot90(cv::Mat &matImage, int rotflag) {
    // 1=CW, 2=CCW, 3=180
    if (rotflag == 1) {
        // transpose+flip(1)=CW
        transpose(matImage, matImage);
        flip(matImage, matImage, 1);
    } else if (rotflag == 2) {
        // transpose+flip(0)=CCW
        transpose(matImage, matImage);
        flip(matImage, matImage, 0);
    } else if (rotflag == 3){
        // flip(-1)=180
        flip(matImage, matImage, -1);
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    @autoreleasepool {
        if (self.isProcessingFrame) {
            return;
        }
        self.isProcessingFrame = YES;

        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer, 0);

        // Y_PLANE
        int plane = 0;
        char *planeBaseAddress = (char *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, plane);

        size_t width = CVPixelBufferGetWidthOfPlane(imageBuffer, plane);
        size_t height = CVPixelBufferGetHeightOfPlane(imageBuffer, plane);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, plane);

        int numChannels = 3;

        cv::Mat src = cv::Mat(cvSize((int)width, (int)height), CV_8UC(numChannels), planeBaseAddress, (int)bytesPerRow);
        int rotate = 0;
        if (deviceOrientation == UIDeviceOrientationPortrait) {
            rotate = 1;
        } else if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
            rotate = 3;
        } else if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown) {
            rotate = 2;
        }
        rot90(src, rotate);

//        [[PlateScanner sharedInstance] scanImage:src onSuccess:^(PlateResult *result) {
//            if (result && self.camera.onPlateRecognized) {
//                self.camera.onPlateRecognized(@{
//                    @"confidence": @(result.confidence),
//                    @"plate": result.plate
//                });
//            }
//
//            CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
//            self.isProcessingFrame = NO;
//
//            [self _notifyOfFaces:encodedFaces];
//
//        } onFailure:^(NSError *err) {
//            CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
//            self.isProcessingFrame = NO;
//        }];
    }
}

@end
