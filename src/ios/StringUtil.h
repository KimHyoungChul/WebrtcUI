//
//  StringUtil.h
//  SipVideoPluginTest
//
//  Created by SCNDev1 on 12/26/16.
//
//

#import <Foundation/Foundation.h>

@interface StringUtil : NSObject

+(BOOL)isEmpty:(NSString *)str;
+(void)setLanguage:(NSString*)lang;
+(NSString *)get:(NSString *)key alter:(NSString *)alternate;
+(NSString *)localizedString: (NSString *)key;

@end
