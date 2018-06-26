//
//  LinphoneVideoWindowViewController.h
//  PhemiumApp
//

#import <UIKit/UIKit.h>
#import "LinPhoneManager.h"
#import "UIButton+Badge.h"
#import "EFSignalBarView.h"

@class VideoContainerView;
@class ControlContainerView;
@interface LinphoneVideoWindowViewController : UIViewController

@property (retain, nonatomic) IBOutlet UILabel *lbUserName;
@property (retain, nonatomic) IBOutlet UIView *containerView;
@property (retain, nonatomic) IBOutlet UIView *controlsView;
@property (retain, nonatomic) IBOutlet UILabel *timeLabel;
@property (retain, nonatomic) IBOutlet UIView *portraitView;
@property (retain, nonatomic) IBOutlet VideoContainerView *remoteVideoView;
@property (retain, nonatomic) NSDictionary *messages;
@property (assign, readwrite) LinphoneManager *theLinphoneManager;
@property (nonatomic, strong) IBOutlet UIImageView *imgViewDisabledOutputDevice1;
@property (nonatomic, strong) IBOutlet UIImageView *imgViewDisabledOutputDevice2;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *constraintControlsContainer;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *constraintTopViewTop;

@property (retain, nonatomic) IBOutlet ControlContainerView *muteButtonContainer;
@property (retain, nonatomic) IBOutlet ControlContainerView *muteCameraButtonContainer;
@property (retain, nonatomic) IBOutlet ControlContainerView *switchCameraButtonContainer;
@property (retain, nonatomic) IBOutlet ControlContainerView *closeButtonContainer;
@property (retain, nonatomic) IBOutlet UIView *topView;

//recording
@property (retain, nonatomic) IBOutlet UIView *recordView;
@property (retain, nonatomic) IBOutlet UILabel *lbRecordingNotification;
@property (weak, nonatomic) IBOutlet UIView *bottomCtrl;

// parameters
@property (strong, nonatomic) UIColor *mainColor;
@property (strong, nonatomic) NSString *userName;
@property (atomic) int displayButtonTime;
@property (strong, nonatomic) NSString *displayNameMode;
@property (strong) UIColor *fontColor;
@property (atomic) int fontSize;
@property (atomic) BOOL bCallRecordingNotification;
@property (atomic) BOOL bShowChatBtn;
@property (atomic) BOOL bZoomMode;

// local camera resolution
@property (atomic) MSVideoSize localVideoSize;

@property (strong, nonatomic) IBOutlet EFSignalBarView *signalBarView;
@property (strong, nonatomic) IBOutlet UIView *alertMessage;
@property (weak, nonatomic) IBOutlet UILabel *alertLabel;

// @property (retain, nonatomic) IBOutlet UIView *messageView;
// @property (retain, nonatomic) IBOutlet UILabel *messageTextLabel;
// @property (retain, nonatomic) IBOutlet UIImageView *qualityImage;
// @property (retain, nonatomic) IBOutlet UIButton *openControlsButton;
// @property (retain, nonatomic) IBOutlet UIImageView *modalImage;
// @property (retain, nonatomic) IBOutlet UIButton *dismissModalButton;

- (void) showRemoteHangup;
- (void) showConnected;
//- (void) showNoResponse;
//- (void) showDeclined;
//- (void) showRejected;
//- (void) showFailed;

-(void)increaseTimerCount : (NSDate *) callStartTime;

- (void) setMuteButtonState;

- (void)startMessagetone;

-(void) updateCallStatus : (float) callQuality;

- (void) chatArrived;
- (void) clearBadge;
- (void) updateDownloadBandwidth : (float) downloadBandwidth UploadBandwidth: (float) uploadBandwidth CallQuality: (float) callQuality;

@end
