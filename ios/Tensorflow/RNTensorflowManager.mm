#import <React/RCTConvert.h>
#import <React/RCTLog.h>

#import "RNCamera.h"
#import "RNTensorflowManager.h"
#import "ImageProcessor.h"
#import "ImageHelper.h"

#include "tensorflow/core/public/session.h"
#include <string>
#include <fstream>

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
@property (nonatomic, strong) ImageProcessor * imageProcessor;
@property (nonatomic, strong) NSString * model;
@property (nonatomic, strong) NSString * labels;

@end

@implementation RNTensorflowManager

- (NSDictionary *)constantsToExport
{
    return [[self class] constants];
}

+ (NSDictionary *)constants
{
    return @{@"Model" : @{},
             @"Label" : @{},
             };
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
        _enabled = newEnabled;
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

- (void)setModel:(id)json
{
    _model = [RCTConvert NSString:json];
}
- (void)setLabels:(id)json
{
    _labels = [RCTConvert NSString:json];
}

# pragma mark - Public API

- (void)startSession:(AVCaptureSession *)session withPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer
{
    _session = session;
    _previewLayer = previewLayer;
    _imageProcessor = [[ImageProcessor alloc] initWithData:_model labels:_labels];

    LOG(INFO) << "Attempting to start tensorflow session";

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

            [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceDidRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
            deviceOrientation = [[UIDevice currentDevice] orientation];
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

- (void)deviceDidRotate:(NSNotification *)notification
{
    UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];

    // Ignore changes in device orientation if unknown, face up, or face down.
    if (!UIDeviceOrientationIsValidInterfaceOrientation(currentOrientation)) {
        return;
    }
    deviceOrientation = currentOrientation;
}

# pragma mark - Utilities

- (void)_runBlockIfQueueIsPresent:(void (^)(void))block
{
    if (_sessionQueue) {
        dispatch_async(_sessionQueue, block);
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
        [_imageProcessor reset];
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
        CIContext *temporaryContext = [CIContext contextWithOptions:nil];
        CGImageRef videoImage = [temporaryContext
                                 createCGImage:ciImage
                                 fromRect:CGRectMake(0, 0,
                                                     CVPixelBufferGetWidth(imageBuffer),
                                                     CVPixelBufferGetHeight(imageBuffer))];
        NSArray<NSDictionary *> * result = [_imageProcessor recognizeImage:videoImage orientation:[ImageHelper toOrientation:deviceOrientation]];
        if (_delegate) {
            [_delegate onItemsDetected:result];
        }

        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        self.isProcessingFrame = NO;
    }
}

@end
