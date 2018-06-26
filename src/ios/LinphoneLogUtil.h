//
//  LinphoneLogUtil.h
//  Phemium Videocall Test App
//
//  Created by arnoldmac on 5/29/17.
//
//

#import <Foundation/Foundation.h>
#import "LinPhoneManager.h"

#define LOGV(level, ...) [Log log:level file:__FILE__ line:__LINE__ format:__VA_ARGS__]
#define LOGD(...) LOGV(ORTP_DEBUG, __VA_ARGS__)
#define LOGI(...) LOGV(ORTP_MESSAGE, __VA_ARGS__)
#define LOGW(...) LOGV(ORTP_WARNING, __VA_ARGS__)
#define LOGE(...) LOGV(ORTP_ERROR, __VA_ARGS__)
#define LOGF(...) LOGV(ORTP_FATAL, __VA_ARGS__)

@interface LinphoneLogUtil : NSObject
+ (void)log:(OrtpLogLevel)severity file:(const char *)file line:(int)line format:(NSString *)format, ...;
+ (void)enableLogs:(OrtpLogLevel)level;

+ (NSString *)cacheDirectory;

void linphone_iphone_log_handler(const char *domain, OrtpLogLevel lev, const char *fmt, va_list args);
@end
