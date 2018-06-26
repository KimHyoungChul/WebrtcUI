//
//  FileUtil.h
//  SipVideoPluginTest
//
//  Created by SCNDev1 on 12/29/16.
//
//

#import <Foundation/Foundation.h>

@interface FileUtil : NSObject

+(NSString *) getDirectoryForSavingCertificate;
+(NSString *) getPathForRecordingMedia: (BOOL)bAudio;

@end
