//
//  DataManager.h
//  SipVideoPluginTest
//
//  Created by SCNDev1 on 12/22/16.
//
//

#import <Foundation/Foundation.h>

@interface CallData : NSObject

//to
@property (atomic) NSString* to;

//call setting
@property (atomic) int onlyAudioCall;
@property (atomic) int download_bandwidth;
@property (atomic) int upload_bandwidth;
@property (atomic) int framerate;

//credentials
@property (nonatomic, strong) NSString* username;
@property (nonatomic, strong) NSString* password;
@property (nonatomic, strong) NSString* domain;
@property (nonatomic, strong) NSString* address;
@property (nonatomic, strong) NSString* proxy;
@property (nonatomic, strong) NSString* turnServer0;
@property (nonatomic, strong) NSString* turnDomain0;
@property (nonatomic, strong) NSString* turnUsername0;
@property (nonatomic, strong) NSString* turnPassword0;
@property (nonatomic, strong) NSString* turnServer1;
@property (nonatomic, strong) NSString* turnDomain1;
@property (nonatomic, strong) NSString* turnUsername1;
@property (nonatomic, strong) NSString* turnPassword1;

//etras
@property (nonatomic, strong) NSString* main_color;
@property (nonatomic, strong) NSString* secondary_color;
@property (nonatomic, strong) NSString* display_topview_mode;
@property (nonatomic, strong) NSString* call_recording_notification_visible;
@property (atomic) int display_button_time;
@property (atomic) int font_size;
@property (nonatomic, strong) NSString* font_color;
@property (nonatomic, strong) NSString* language;
@property (nonatomic, strong) NSString* consultant_name;

@property (nonatomic, strong) NSString* transport_mode;
@property (nonatomic, strong) NSString* encryption_mode;
@property (nonatomic, strong) NSString* video_size;

@property (nonatomic, strong) NSString* chat_mode;
@property (nonatomic, strong) NSString* zoom_mode;
@property (nonatomic, strong) NSString* videocall_version;
@property (nonatomic, strong) NSString* enduser_version;
@property (nonatomic, strong) NSString* consultation_id;
@property (atomic) bool log_enable;
@property (nonatomic, strong) NSString * to_email;

- (void)setCredentialValues: (NSString *)credential;
- (void)setCallSettingValues: (NSString *)setting;
- (void)setGUISettings: (NSString *)guiSettings;
- (void)setExtraSettings: (NSString *)extraSettings;
- (void)checkDefaultValues;

@end
