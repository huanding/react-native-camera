#include <UIKit/UIKit.h>

#include "tensorflow/core/public/session.h"

@interface TensorFlowInference: NSObject

- (id) initWithModel:(NSString *)modelLocation;
- (void) feed:(NSString *)inputName tensor:(tensorflow::Tensor)tensor;
- (void) run:(NSArray *)outputNames enableStats:(BOOL)enableStats;
- (NSArray *) fetch:(NSString *)outputName;
- (void) close;
- (void) reset;

@end
