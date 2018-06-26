//
//  LinphoneLogUtil.m
//  Phemium Videocall Test App
//
//  Created by arnoldmac on 5/29/17.
//
//

#import "LinphoneLogUtil.h"
#import <asl.h>
#import <os/log.h>

@implementation LinphoneLogUtil
#define FILE_SIZE 17
#define DOMAIN_SIZE 3

+ (NSString *)cacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths objectAtIndex:0];
    BOOL isDir = NO;
    NSError *error;
    // cache directory must be created if not existing
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDir] && isDir == NO) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:cachePath
                                       withIntermediateDirectories:NO
                                                        attributes:nil
                                                             error:&error]) {
            NSLog(@"Could not create cache directory: %@", error);
        }
    }
    return cachePath;
}

+ (void)log:(OrtpLogLevel)severity file:(const char *)file line:(int)line format:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
    const char *utf8str = [str cStringUsingEncoding:NSString.defaultCStringEncoding];
    const char *filename = strchr(file, '/') ? strrchr(file, '/') + 1 : file;
    ortp_log(severity, "(%*s:%-4d) %s", FILE_SIZE, filename + MAX((int)strlen(filename) - FILE_SIZE, 0), line, utf8str);
    va_end(args);
}

+ (void)enableLogs:(OrtpLogLevel)level {
    BOOL enabled = (level >= ORTP_DEBUG && level < ORTP_ERROR);
    NSLog(@"%s", [self cacheDirectory].UTF8String);
}

#pragma mark - Logs Functions callbacks

void linphone_iphone_log_handler(const char *domain, OrtpLogLevel lev, const char *fmt, va_list args) {
    NSString *format = [[NSString alloc] initWithUTF8String:fmt];
    NSString *formatedString = [[NSString alloc] initWithFormat:format arguments:args];
    NSString *lvl;
    
    if (!domain)
        domain = "lib";
    // since \r are interpreted like \n, avoid double new lines when logging network packets (belle-sip)
    // output format is like: I/ios/some logs. We truncate domain to **exactly** DOMAIN_SIZE characters to have
    // fixed-length aligned logs
    switch (lev) {
        case ORTP_FATAL:
            lvl = @"Fatal";
            break;
        case ORTP_ERROR:
            lvl = @"Error";
            break;
        case ORTP_WARNING:
            lvl = @"Warning";
            break;
        case ORTP_MESSAGE:
            lvl = @"Message";
            break;
        case ORTP_DEBUG:
            lvl = @"Debug";
            break;
        case ORTP_TRACE:
            lvl = @"Trace";
            break;
        case ORTP_LOGLEV_END:
            return;
    }
    if ([formatedString containsString:@"\n"]) {
        NSArray *myWords = [[formatedString stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"]
                            componentsSeparatedByString:@"\n"];
        for (int i = 0; i < myWords.count; i++) {
            NSString *tab = i > 0 ? @"\t" : @"";
            if (((NSString *)myWords[i]).length > 0) {
                NSLog(@"[%@] %@%@", lvl, tab, (NSString *)myWords[i]);
            }
        }
    } else {
        NSLog(@"[%@] %@", lvl, [formatedString stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"]);
    }
}
@end
