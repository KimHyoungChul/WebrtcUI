//
//  FileUtil.m
//  SipVideoPluginTest
//
//  Created by SCNDev1 on 12/29/16.
//
//

#import "FileUtil.h"
#import "Constant.h"

@implementation FileUtil

+(NSString *) getDirectoryForSavingCertificate {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

+(NSString *) getPathForRecordingMedia: (BOOL)bAudio {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *recordDirectory = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithUTF8String:CALL_RECORD_DIRECTORY_NAME]];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    BOOL isDir;
    NSError *error;
    if (![fileManager fileExistsAtPath:recordDirectory isDirectory:&isDir]) {
        [fileManager createDirectoryAtPath:recordDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        if (error != nil) {
            NSLog(@"Create Directory Error: %@", error);
        }
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%d",(int)[[NSDate date] timeIntervalSince1970]];
    if (bAudio) {
        fileName = [fileName stringByAppendingPathExtension:@"wav"];
    } else {
        fileName = [fileName stringByAppendingPathExtension:@"mkv"];
    }
    
    NSString *recordFilePath = [recordDirectory stringByAppendingPathComponent:fileName];
    return recordFilePath;
}

@end
