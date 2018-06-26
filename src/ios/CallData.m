//
//  DataManager.m
//  SipVideoPluginTest
//
//  Created by SCNDev1 on 12/22/16.
//
//

#import "CallData.h"
#import "StringUtil.h"

@implementation CallData

@synthesize onlyAudioCall;
@synthesize download_bandwidth;
@synthesize upload_bandwidth;
@synthesize framerate;

//credentials
@synthesize username;
@synthesize password;
@synthesize domain;
@synthesize address;
@synthesize proxy;
@synthesize turnServer0;
@synthesize turnDomain0;
@synthesize turnUsername0;
@synthesize turnPassword0;
@synthesize turnServer1;
@synthesize turnDomain1;
@synthesize turnUsername1;
@synthesize turnPassword1;

//etras
@synthesize main_color;
@synthesize secondary_color;
@synthesize display_topview_mode;
@synthesize call_recording_notification_visible;
@synthesize display_button_time;
@synthesize language;
@synthesize consultant_name;
@synthesize font_size;
@synthesize font_color;

@synthesize transport_mode;
@synthesize encryption_mode;
@synthesize video_size;
@synthesize chat_mode;
@synthesize zoom_mode;
@synthesize videocall_version;
@synthesize enduser_version;
@synthesize consultation_id;
@synthesize log_enable;
@synthesize to_email;

- (void)setCredentialValues: (NSString *)credentials {
    username = [credentials valueForKey: @"username"];
    password = [credentials valueForKey: @"password"];
    domain = [credentials valueForKey: @"domain"];
    address = [credentials valueForKey: @"address"];
    proxy = [credentials valueForKey: @"proxy"];
    turnServer0 = [credentials valueForKey: @"turnServer0"];
    turnDomain0 = [credentials valueForKey: @"turnDomain0"];
    turnUsername0 = [credentials valueForKey: @"turnUsername0"];
    turnPassword0 = [credentials valueForKey: @"turnPassword0"];
    turnServer1 = [credentials valueForKey: @"turnServer1"];
    turnDomain1 = [credentials valueForKey: @"turnDomain1"];
    turnUsername1 = [credentials valueForKey: @"turnUsername1"];
    turnPassword1 = [credentials valueForKey: @"turnPassword1"];
    
    if (![[address substringToIndex: 3] isEqualToString: @"sip"]) {
        address = [@"sip:" stringByAppendingString: address];
    }
}

- (void)setCallSettingValues: (NSString *)settings {
    onlyAudioCall = [[settings valueForKey:@"only_audio"] intValue];
    download_bandwidth = [[settings valueForKey: @"download_bandwidth"] intValue];
    upload_bandwidth = [[settings valueForKey: @"upload_bandwidth"] intValue];
    framerate = [[settings valueForKey: @"framerate"] intValue];
    transport_mode = [settings valueForKey:@"transport_mode"];
    encryption_mode = [settings valueForKey:@"encryption_mode"];
    video_size = [settings valueForKey:@"video_size"];
}

- (void)setGUISettings: (NSString *)guiSettings {
    language = [guiSettings valueForKey:@"language"];
    main_color = [guiSettings valueForKey:@"main_color"];
    secondary_color = [guiSettings valueForKey:@"secondary_color"];
    font_size = [[guiSettings valueForKey:@"font_size"] intValue];
    font_color = [guiSettings valueForKey:@"font_color"];
    display_topview_mode = [guiSettings valueForKey:@"display_topview_mode"];
    consultant_name = [guiSettings valueForKey:@"consultant_name"];
    call_recording_notification_visible = [guiSettings valueForKey:@"call_recording_notification_visible"];
    chat_mode = [guiSettings valueForKey:@"chat_mode"];
    zoom_mode = [guiSettings valueForKey:@"zoom_mode"];
    log_enable = [[guiSettings valueForKey:@"log_mode"] boolValue];
    [self checkDefaultValues];
}

- (void)setExtraSettings: (NSString *)extraSettings {
    videocall_version = [extraSettings valueForKey:@"videocall_version"];
    enduser_version = [extraSettings valueForKey:@"enduser_version"];
    consultation_id = [extraSettings valueForKey:@"consultation_id"];
    to_email = [extraSettings valueForKey:@"extra_toemail"];
}

- (void)checkDefaultValues {
    if (display_button_time <= 0) {
        display_button_time = 3;
    }
    if ([StringUtil isEmpty:language]) {
        language = @"es";
    }
    if ([StringUtil isEmpty:main_color]) {
        main_color = @"0a79c7";
    }
    if ([StringUtil isEmpty:secondary_color]) {
        secondary_color = @"70c8e1";
    }
    if ([StringUtil isEmpty:display_topview_mode]) {
        display_topview_mode = @"atScreenTouch";
    }
    if ([StringUtil isEmpty:font_color]) {
        font_color = @"ffffff";
    }
    if ([StringUtil isEmpty:consultant_name]) {
        consultant_name = @"John Doe";
    }
    if (font_size <= 0) {
        font_size = 17;
    }
    if ([StringUtil isEmpty:call_recording_notification_visible]) {
        call_recording_notification_visible = @"no";
    }
}

@end
