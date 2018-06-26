//
//  EFSignalBarView.h
//  TestSignalBarView
//
//  Created by arnoldmac on 11/17/17.
//  Copyright © 2017 phemium. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EFSignalBarView : UIView

@property(strong,nonatomic) UIColor * firstSignalBarColor;
@property(strong,nonatomic) UIColor * secondSignalBarColor;
@property(strong,nonatomic) UIColor * thirdSignalBarColor;
@property(strong,nonatomic) UIColor * fourthSignalBarColor;
@property(strong,nonatomic) UIColor * fifthSignalBarColor;

@property (nonatomic,assign) IBInspectable NSInteger signal;

@property(strong,nonatomic) UIColor * baseColor;
@property(strong,nonatomic) UIColor * lowSignalColor;
@property(strong,nonatomic) UIColor * moderateSignalColor;
@property(strong,nonatomic) UIColor * excellentSignalColor;


-(NSInteger) signal;
-(void) setSignal:(NSInteger) newValue;

@end
