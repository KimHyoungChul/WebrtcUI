//
//  StringUtil.m
//  SipVideoPluginTest
//
//  Created by SCNDev1 on 12/26/16.
//
//

#import "StringUtil.h"

@implementation StringUtil

static NSBundle *bundle = nil;

+(BOOL) isEmpty:(NSString *)str {
    if (str == nil || [str isKindOfClass:[NSNull class]] || [str isEqualToString:@""]) {
        return YES;
    } else {
        return NO;
    }
}

+(NSString *)localizedString: (NSString *)key {
//    NSBundle *bundle = [NSBundle bundleWithPath: [[NSBundle mainBundle] pathForResource: @"LocalizableStrings" ofType: @"bundle"]];
//    return [bundle localizedStringForKey:key value:@"Cannot find Value." table:nil];
    return [bundle localizedStringForKey:key value:@"Unknown" table:nil];
}

+ (void)initialize
{
    NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
    NSArray* languages = [defs objectForKey:@"AppleLanguages"];
    NSString *current = [languages objectAtIndex:0];
    [self setLanguage:current];
}

+(void)setLanguage:(NSString *)l
{
    NSLog(@"preferredLang: %@", l);
    NSString *localizedStringBundlePath = [[ NSBundle mainBundle ] pathForResource:@"LocalizableStrings" ofType:@"bundle" ];
    NSBundle *localizedStringBundle = [NSBundle bundleWithPath:localizedStringBundlePath];
    NSString *path = [localizedStringBundle pathForResource:[l substringToIndex:2] ofType:@"lproj"];
    if (path == nil) {
        path = [localizedStringBundle pathForResource:@"en" ofType:@"lproj"];
    }
    bundle = [NSBundle bundleWithPath:path];
}

+(NSString *)get:(NSString *)key alter:(NSString *)alternate
{
    return [bundle localizedStringForKey:key value:alternate table:nil];
}

@end
