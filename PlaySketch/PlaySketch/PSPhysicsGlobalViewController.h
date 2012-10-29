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
@end

@interface PSPhysicsGlobalViewController : UIViewController
@property(nonatomic, retain) IBOutletCollection(UIButton) NSArray* gravityButtons;
@property(nonatomic, retain) IBOutletCollection(UIButton) NSArray* windButtons;
@property(nonatomic, retain) IBOutlet UIButton* defaultGravityButtons;
@property(nonatomic, retain) IBOutlet UIButton* defaultWindButtons;
@property(nonatomic,weak) id<PSPhysicalGlobalChangeDelegate> delegate;

- (IBAction)setGravity:(id)sender;
- (IBAction)setWind:(id)sender;
- (void)setToDefaults;

@end
