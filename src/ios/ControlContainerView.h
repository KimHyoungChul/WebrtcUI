//
//  ControlContainerView.h
//  SipVideoPluginTest
//
//  Created by SCNDev1 on 12/21/16.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, BUTTON_STATE) {
    CAMERA_NOT_ALLOWED,
    CAMERA_MUTE,
    CAMERA_MUTED,
    VOICE_MUTE,
    VOICE_MUTED,
    SWITCH_CAMERA,
    SWITCH_CAMERA_NOT_ALLOWED,
    END_CALL
};

@interface ControlContainerView : UIView

@property (nonatomic, strong) IBOutlet UIButton *backButton;
@property (nonatomic, strong) IBOutlet UIImageView *buttonImage;
@property (nonatomic) BUTTON_STATE buttonState;

- (void)setBackColor:(UIColor *)backgroundColor;
@end
