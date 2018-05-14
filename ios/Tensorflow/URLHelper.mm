#import "URLHelper.h"

#import <React/RCTLog.h>

@implementation URLHelper {}

+ (NSURL *) toURL: (NSString *) uri
{
    RCTLogInfo(@"Attempting to load %@", uri);

    NSURL * url = [NSURL URLWithString:uri];
    if (url && url.scheme && url.host) {
        RCTLogInfo(@"Loading URL %@", [url absoluteString]);
        return url;
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:uri]) {
        url = [NSURL fileURLWithPath:uri];
        if (url && url.scheme) {
            RCTLogInfo(@"Loading file  %@", [url absoluteString]);
            return url;
        }
    }

    NSString * path = [[NSBundle mainBundle]
                       pathForResource:[[uri lastPathComponent] stringByDeletingPathExtension]
                       ofType:[uri pathExtension]];
    if (path) {
        url = [NSURL fileURLWithPath:path];
        if (url && url.scheme) {
            RCTLogInfo(@"Loading resource %@", [url absoluteString]);
            return url;
        }
    }

    throw std::invalid_argument([uri UTF8String]);
}
@end
