//
//  PSPhysicsGlobalViewController.h
//  PlaySketch
//
//  Created by Yang Liu on 27/10/12.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PSPhysicalGlobalChangeDelegate 
- (void)gravityChanged:(int)gravity;
- (void)windChanged:(int)wind;
//- (void)gravityStateChanged:(BOOL)gravityOn;
//- (void)windStateChanged:(BOOL)windOn;
@end

@interface PSPhysicsGlobalViewController : UIViewController
@property(nonatomic, retain) IBOutletCollection(UIButton) NSArray* gravityButtons;
@property(nonatomic, retain) IBOutletCollection(UIButton) NSArray* windButtons;
@property(nonatomic, retain) IBOutlet UIButton* defaultGravityButtons;
@property(nonatomic, retain) IBOutlet UIButton* defaultWindButtons;
@property(nonatomic, retain) IBOutlet UIButton* gravityButton;
@property(nonatomic, retain) IBOutlet UIButton* windButton;
@property(nonatomic, retain) IBOutlet UILabel* gravitySliderLabel;
@property(nonatomic, retain) IBOutlet UILabel* windSliderLabel;
@property(nonatomic,weak) id<PSPhysicalGlobalChangeDelegate> delegate;
@property(nonatomic) BOOL gravityOn;
@property(nonatomic) int windOn;

- (IBAction)setGravity:(id)sender;
- (IBAction)setGravityState:(id)sender;
- (IBAction)setWind:(id)sender;
- (IBAction)setWindState:(id)sender;
- (IBAction)gravitySliderChanged:(id)sender;
- (IBAction)windSliderChanged:(id)sender;
- (void)setToDefaults;

@end
