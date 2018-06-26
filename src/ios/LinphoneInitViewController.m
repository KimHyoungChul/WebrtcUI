//
//  LinphoneConnectViewController.m
//  SipVideoPluginTest
//
//  Created by Tomasson on 12/7/16.
//
#import "LinphoneInitViewController.h"
#import "LinPhoneManager.h"
#import "UIView+Toast.h"
#import "StringUtil.h"
#import "Constant.h"
#import "UIButton+Badge.h"

#define SPEAKER_BUTTON_X_OFFSET_FROM_CENTER -70

@interface LinphoneInitViewController () <AVAudioPlayerDelegate> {
    // variables needed for audio call
    NSTimer *callTimer;
    NSDate *callStartTime;

    AVAudioPlayer *avAudioPlayer;
    BOOL bRingtonePlayStop;
    NSTimer *timerRingtonePlayStart;

    BOOL bAudioCallStarted;
    BOOL bIsConnecting;
    BOOL bIsLinking;
    
    int badgeNum;
}

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *muteButtonXContraint;

@end

@implementation LinphoneInitViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
    if (self) {
        // Custom initialization

        self.mainColor = [UIColor colorWithRed:10/255.0 green:121/255.0 blue:199/255.0 alpha:1];
        self.secondaryColor = [UIColor colorWithRed:112/255.0 green:200/255.0 blue:225/255.0 alpha:1];
        self.userName = @"";
        self.fontColor = [UIColor whiteColor];
        self.fontSize = 17;
        
        _bLinking = YES;
        bAudioCallStarted = NO;
    }
    NSLog(@"LinphoneInitViewController Init");
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeOrientation) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    [self refreshView];
    [self setInitStatus];
    
    badgeNum = 0;
    
    if (badgeNum != 0) {
        self.chatBtn.badgeValue = [NSString stringWithFormat:@"%d" , badgeNum];
        self.chatBtn.badgeBGColor = [UIColor redColor];
    }
    
    self.chatBtn.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopRingtone];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self insertGradientLayer];

    UILongPressGestureRecognizer * singleTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.view addGestureRecognizer:singleTap];
}

-(void) insertGradientLayer{
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.view.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[_mainColor CGColor], (id)[_secondaryColor CGColor], nil];
    [self.view.layer insertSublayer:gradient atIndex:0];
}

-(void) handleSingleTap: (UITapGestureRecognizer *) recognizer{
    LinphoneManager *linphoneManager = [LinphoneManager instance];
    [linphoneManager enableLogCollection : YES];
}


- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
    return YES;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation {
    return YES;
}

- (void)setInitStatus {
    LinphoneManager *linphoneManager = [LinphoneManager instance];

    if ([linphoneManager speakerEnabled]) {
        [self.butMute setSelected:YES];
    } else {
        [self.butSpeaker setSelected:NO];
    }
    
    _imgViewAvatar.layer.cornerRadius = _imgViewAvatar.frame.size.width/2;
    _imgViewAvatar.layer.masksToBounds = YES;
    
    [self.lbLabel1 setTextColor:self.fontColor];
    [self.lbLabel2 setTextColor:self.fontColor];
    [self.lbLabel3 setTextColor:self.fontColor];
    [self.lbLabel4 setTextColor:self.fontColor];
    [self.lbLabel5 setTextColor:self.fontColor];
    [self.lbSpeaker setTextColor:self.fontColor];
    [self.lbMute setTextColor:self.fontColor];
    
    UIFont *font = self.lbLabel1.font;
    UIFontDescriptor * fontNormal = [font.fontDescriptor
                                     fontDescriptorWithSymbolicTraits:(font.fontDescriptor.symbolicTraits & ~UIFontDescriptorTraitBold)];
    UIFontDescriptor * fontBold = [font.fontDescriptor
                                   fontDescriptorWithSymbolicTraits:(font.fontDescriptor.symbolicTraits | UIFontDescriptorTraitBold)];
    
    [self.lbMute setFont:[UIFont fontWithDescriptor:fontNormal size:self.fontSize-FONT_SIZE_OFFSET_BUTTON_LABEL]];
    [self.lbSpeaker setFont:[UIFont fontWithDescriptor:fontNormal size:self.fontSize-FONT_SIZE_OFFSET_BUTTON_LABEL]];
    [self.lbLabel3 setFont:[UIFont fontWithDescriptor:fontBold size:self.fontSize-FONT_SIZE_OFFSET_STATUS_LABEL]];
    [self.lbLabel4 setFont:[UIFont fontWithDescriptor:fontBold size:self.fontSize-FONT_SIZE_OFFSET_STATUS_LABEL]];
    [self.lbLabel5 setFont:[UIFont fontWithDescriptor:fontBold size:self.fontSize-FONT_SIZE_OFFSET_STATUS_LABEL]];
    
    [self.lbMute setText:[StringUtil localizedString:@"mute"]];
    [self.lbSpeaker setText:[StringUtil localizedString:@"speaker"]];
    self.lbRecordingNotification.text = [StringUtil localizedString: @"recording_text"];
}

- (void)setCallStatus : (int) callStatus count:(int)count{
    NSString * text = @"registering";
    switch (callStatus) {
        case CALL_STATUS_REGISTERING:
            text = @"registering";
            break;
        case CALL_STATUS_INIT:
        case CALL_STATUS_RINGING:
            text = @"connecting";
            break;
        case CALL_STATUS_CONNECTING:
            text = @"establishing";
            break;
        case CALL_STATUS_CONNECTED:
            text = @"...";
            break;
            
        case CALL_STATUS_RETRYING:
            text = @"retrying";
            break;
        case CALL_STATUS_ENDING:
            text = @"ending";
            break;
        default:
            break;
    }

    NSString * messaage = [StringUtil localizedString:text];
    if (count > 0) {
        messaage = [NSString stringWithFormat:@"%@ (%d)", messaage, count];
    }
    [self.lbLabel3 setText:messaage];
    NSLog(@"%@ setCallStatus called. status: %@", self, messaage);
}

- (void)setIsLinking {
    NSLog(@"%@ setIsLinking called.", self);
    self.bLinking = YES;
}

- (void)setIsConnecting {
    self.bLinking = NO;
    NSLog(@"%@ setIsConnecting called. linking: %@", self, (self.bLinking==YES)?@"YES":@"NO");
}

- (void)refreshView {
    NSLog(@"%@ refreshView called. linkding: %@", self, (self.bLinking==YES)?@"YES":@"NO");
    if (self.bLinking == YES) {
        [self showLinkingControls];
    } else {
        [self showConnectingControls];
    }
}

#pragma mark - view kind

- (void)showLinkingControls {
    [self.imgViewAvatar setHidden: NO];
    [self.lbLabel1 setHidden: NO];
    [self.lbLabel2 setHidden: NO];
    [self.lbLabel3 setHidden: YES];
    [self.butClose setHidden: NO];

    [self.butSpeaker setHidden: !self.bIsAudioCall];
    [self.lbSpeaker setHidden: !self.bIsAudioCall];
    [self.lbMute setHidden: NO];
    [self.butMute setHidden: NO];
    [self.viewRecordingContainer setHidden: YES];

    if (self.bIsAudioCall) {
        self.muteButtonXContraint.constant = SPEAKER_BUTTON_X_OFFSET_FROM_CENTER;
    } else {
        self.muteButtonXContraint.constant = 0;
    }

    UIFont *font = self.lbLabel1.font;
    UIFontDescriptor * fontD = [font.fontDescriptor
                                fontDescriptorWithSymbolicTraits:(font.fontDescriptor.symbolicTraits | UIFontDescriptorTraitBold)];
    UIFontDescriptor * fontE = [font.fontDescriptor
                                fontDescriptorWithSymbolicTraits:(font.fontDescriptor.symbolicTraits & ~UIFontDescriptorTraitBold)];
    [self.lbLabel1 setFont:[UIFont fontWithDescriptor:fontE size:self.fontSize-FONT_SIZE_OFFSET_STATUS_LABEL]];
    [self.lbLabel2 setFont:[UIFont fontWithDescriptor:fontD size:self.fontSize]];

    //[self.lbLabel1 setText:NSLocalizedString(@"calling", @"")];//@"Calling..."
    [self.lbLabel1 setText:[StringUtil localizedString:@"calling"]];
    [self.lbLabel2 setText:[NSString stringWithFormat:@"%@", self.userName]];//self.userName
    [self.view layoutIfNeeded];

    bIsLinking = YES;
    [self startLinkingEffect];
    
    [self.chatBtn setHidden:YES];
}

- (void)showConnectingControls {
    [self.imgViewAvatar setHidden: YES];
    [self.lbLabel1 setHidden: YES];
    [self.lbLabel2 setHidden: YES];
    [self.lbLabel3 setAlpha: 0.0];
    [self.lbLabel3 setHidden: NO];
    [self.butSpeaker setHidden: YES];
    [self.lbSpeaker setHidden: YES];
    [self.butClose setHidden: YES];
    [self.lbMute setHidden: YES];
    [self.butMute setHidden: YES];
    [self.viewRecordingContainer setHidden: YES];

    bIsConnecting = YES;
    bIsLinking = NO;
    NSLog(@"showConnectingControls called.");
    [self.lbLabel3 setText:[StringUtil localizedString:@"connecting"]];
    [self showConnectingEffect];
    
    [self.chatBtn setHidden:YES];
}

- (void)showAudioCallConnected {
    bAudioCallStarted = YES;
    bIsConnecting = NO;
    bIsLinking = NO;

    [self.imgViewAvatar setHidden: NO];
    [self.lbLabel1 setHidden: NO];
    self.lbLabel1.alpha = 1.0f;
    [self.lbLabel2 setHidden: NO];
    [self.lbLabel3 setHidden: YES];
    [self.butSpeaker setHidden: NO];
    [self.lbSpeaker setHidden: NO];
    [self.butClose setHidden: NO];
    [self.lbMute setHidden: NO];
    [self.butMute setHidden: NO];
    if (self.bShowChatBtn == YES) {
        [self.chatBtn setHidden: NO];
    } else {
        [self.chatBtn setHidden: YES];
    }
    if (self.bCallRecordingNotification == YES) {
        [self.viewRecordingContainer setHidden: NO];
    } else {
        [self.viewRecordingContainer setHidden: YES];
    }

    self.muteButtonXContraint.constant = SPEAKER_BUTTON_X_OFFSET_FROM_CENTER;
    [self.view layoutIfNeeded];

    UILabel *name = self.lbLabel1;
    [name setText:[NSString stringWithFormat:@"%@ %@ - %@", self.userName, [StringUtil localizedString:@"company_name"], [StringUtil localizedString: @"service_name"]]];

    UIFont *font = self.lbLabel1.font;
    UIFontDescriptor * fontD = [font.fontDescriptor
                                fontDescriptorWithSymbolicTraits:(font.fontDescriptor.symbolicTraits | UIFontDescriptorTraitBold)];
    UIFontDescriptor * fontE = [font.fontDescriptor
                                fontDescriptorWithSymbolicTraits:(font.fontDescriptor.symbolicTraits & ~UIFontDescriptorTraitBold)];
    [self.lbLabel1 setFont:[UIFont fontWithDescriptor:fontD size:self.fontSize]];
    [self.lbLabel2 setFont:[UIFont fontWithDescriptor:fontE size:self.fontSize-FONT_SIZE_OFFSET_STATUS_LABEL]];
}

- (void)onVideoCallConnected {
    bIsConnecting = NO;
}

- (IBAction)onHangup:(id)sender {
    [[LinphoneManager instance] hangupWithCause:CALL_HANGUP_BY_CALLER];
}

- (IBAction)onSpeaker:(id)sender {
    LinphoneManager *linphoneManager = [LinphoneManager instance];

    if (linphoneManager.speakerEnabled) {
        if (!bAudioCallStarted) {
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error: nil];
        }
        [self.butSpeaker setSelected:NO];
    } else {
        if (!bAudioCallStarted) {
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error: nil];
        }
        [self.butSpeaker setSelected:YES];
    }

    [linphoneManager setSpeakerEnabled:!linphoneManager.speakerEnabled];
}

- (IBAction)onMute:(id)sender {
    [[LinphoneManager instance] mute];
    if ([[LinphoneManager instance] isMuted]) {
        [self.butMute setSelected:YES];
    } else {
        [self.butMute setSelected:NO];
    }
}

- (IBAction)onCloseRecordingLayout:(id)sender {
    [self.viewRecordingContainer setHidden:YES];
}

- (IBAction)goTextChat:(id)sender {
    [self.navigationController dismissViewControllerAnimated:true completion:^{
        [[LinphoneManager instance] minimizeVideo];
    }];
}


#pragma mark - Timer for audio call duration count

- (void)increaseTimerCount:(NSDate *) startTime {
    NSTimeInterval difference = [[NSDate date] timeIntervalSinceDate:startTime];
    long seconds = lroundf( difference );
    UILabel *timeLabel = self.lbLabel2;

    if (seconds == 11) {
        [self.viewRecordingContainer setHidden:YES];
    }

    if( difference > 3600 ) {
        timeLabel.text = [NSString stringWithFormat: @"%02ld:%02ld:%02ld", seconds / 3600, seconds / 60, seconds % 60];
    } else {
        timeLabel.text = [NSString stringWithFormat: @"%02ld:%02ld", seconds / 60, seconds % 60];
    }
}

#pragma mark - Ringtone play

- (void)startRingtone {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];

    NSString* path = [[NSBundle mainBundle] pathForResource:@"ringback" ofType:@"wav"];
    NSURL* url = [NSURL fileURLWithPath:path];

    avAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    avAudioPlayer.delegate = self;
    if (error != nil) {
        NSLog(@"ringtone music load error");
    } else {
        if ([avAudioPlayer prepareToPlay]) {
            [avAudioPlayer play];
            NSLog(@"ringtone music playing");
        } else {
            NSLog(@"ringtone music play not ready");
        }
    }

    bRingtonePlayStop = NO;
}

- (void)stopRingtone {
    bRingtonePlayStop = YES;
    [avAudioPlayer stop];
}

- (void)replayRingtone {
    if (bRingtonePlayStop == NO) {
        [avAudioPlayer play];
    }
}

#pragma mark - Messagetone play

- (void)startMessagetone {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    
    NSString* path = [[NSBundle mainBundle] pathForResource:@"incoming_chat" ofType:@"wav"];
    NSURL* url = [NSURL fileURLWithPath:path];
    
    avAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
//    avAudioPlayer.delegate = self;
    if (error != nil) {
        NSLog(@"messagetone music load error");
    } else {
        if ([avAudioPlayer prepareToPlay]) {
            [avAudioPlayer play];
            NSLog(@"messagetone music playing");
        } else {
            NSLog(@"messagetone music play not ready");
        }
    }
}

#pragma mark - linking blur in and out

- (void)startLinkingEffect {
    NSLog(@"linking effect start.");

    [UIView animateWithDuration:1.5f animations:^{
        [self.lbLabel1 setAlpha: 1.0f];
    } completion:^(BOOL finished) {
        if (finished) {
            if (!bIsLinking) {
                self.lbLabel1.alpha = 1.0f;
                return;
            }
            [UIView animateWithDuration:1.5f animations:^{
                [self.lbLabel1 setAlpha: 0.0f];
            } completion:^(BOOL finished) {
                if (finished) {
                    if (bIsLinking) {
                        [self startLinkingEffect];
                    } else {
                        self.lbLabel1.alpha = 1.0f;
                    }
                }
            }];
        }
    }];
}

#pragma mark - connecting blur in and out

- (void)showConnectingEffect {
    NSLog(@"connection effect start.");

    [UIView animateWithDuration:1.5f animations:^{
        [self.lbLabel3 setAlpha: 1.0f];
    } completion:^(BOOL finished) {
        if (finished) {
            [UIView animateWithDuration:1.5f animations:^{
                [self.lbLabel3 setAlpha: 0.0f];
            } completion:^(BOOL finished) {
                if (finished) {
                    if (bIsConnecting) {
                        NSLog(@"bIsConnecting is still true.");
                        [self showConnectingEffect];
                    }
                }
            }];
        }
    }];
}

- (void) chatArrived{
    LinphoneManager * linphoneManager = [LinphoneManager instance];
    badgeNum = (int)linphoneManager.badgeNum;
    if (badgeNum != 0) {
        self.chatBtn.badgeValue = [NSString stringWithFormat:@"%d" , badgeNum];
        self.chatBtn.badgeBGColor = [UIColor redColor];
    }else{
        [self clearBadge];
    }
}

- (void) clearBadge{
    badgeNum = 0;
    self.chatBtn.badgeValue = 0;
    self.chatBtn.badgeBGColor = [UIColor redColor];
}

-(void) changeOrientation{
    BOOL isLandscape = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    if (isLandscape) {
        [[NSBundle mainBundle] loadNibNamed:@"LinphoneInitViewControllerLandscape" owner:self options:nil];
    }else{
        [[NSBundle mainBundle] loadNibNamed:@"LinphoneInitViewControllerPortrait" owner:self options:nil];
    }
    if (bAudioCallStarted) {
        [self showAudioCallConnected];
    }else{
        [self refreshView];
    }
    [self setInitStatus];
    [self insertGradientLayer];
}

#pragma mark - avaudioplayer delegate methods

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (bRingtonePlayStop == NO) {
        timerRingtonePlayStart = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(replayRingtone) userInfo:nil repeats:NO];
    }
}

/* if an error occurs while decoding it will be reported to the delegate. */
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error {

}


@end
