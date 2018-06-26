//
//  VideoContainerView.h
//  SipVideoPluginTest
//
//  Created by Tomasson on 12/19/16.
//
//

#import <UIKit/UIKit.h>

@interface VideoContainerView : UIView

@property (nonatomic, strong) CAGradientLayer *gradient1;
@property (nonatomic, strong) CAGradientLayer *gradient2;

- (void) setupGradientLayer;

@end
