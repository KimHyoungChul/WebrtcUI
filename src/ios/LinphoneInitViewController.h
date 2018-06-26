//
//  LinphoneConnectViewController.h
//  SipVideoPluginTest
//
//  Created by Tomasson on 12/7/16.
//
//

#import <UIKit/UIKit.h>

@interface LinphoneInitViewController : UIViewController

@property (retain, nonatomic) IBOutlet UIImageView *imgViewAvatar;
@property (retain, nonatomic) IBOutlet UILabel *lbLabel1;
@property (retain, nonatomic) IBOutlet UILabel *lbLabel2;
@property (retain, nonatomic) IBOutlet UILabel *lbLabel3;
@property (retain, nonatomic) IBOutlet UILabel *lbLabel4;
@property (retain, nonatomic) IBOutlet UILabel *lbLabel5;
@property (retain, nonatomic) IBOutlet UIButton *butSpeaker;
@property (retain, nonatomic) IBOutlet UILabel *lbSpeaker;
@property (retain, nonatomic) IBOutlet UIButton *butClose;
@property (retain, nonatomic) IBOutlet UILabel *lbMute;
@property (retain, nonatomic) IBOutlet UIButton *butMute;
@property (retain, nonatomic) IBOutlet UIView *viewRecordingContainer;
@property (retain, nonatomic) IBOutlet UILabel *lbRecordingNotification;

@property (strong, nonatomic) UIColor *mainColor;
@property (strong, nonatomic) UIColor *secondaryColor;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) UIColor *fontColor;
@property (atomic) int fontSize;
@property (atomic) BOOL bCallRecordingNotification;
@property (atomic) BOOL bShowChatBtn;

@property (atomic, assign) BOOL bLinking;
@property (atomic) BOOL bIsAudioCall;
@property (weak, nonatomic) IBOutlet UIButton *chatBtn;

- (void)setIsLinking;
- (void)setIsConnecting;
- (void)onVideoCallConnected;
- (void)refreshView;
- (void)showAudioCallConnected;
- (void)setCallStatus : (int) callStatus count: (int) count;

// ringtone play
- (void)startRingtone;
- (void)stopRingtone;

- (void)startMessagetone;

-(void)increaseTimerCount : (NSDate *) callStartTime;

- (void) chatArrived;
- (void) clearBadge;

@end
