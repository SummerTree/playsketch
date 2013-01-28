//
//  PSPhysicsStateViewController.h
//  PlaySketch
//
//  Created by Yang Liu on 29/10/12.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PSPhysicalStateChangeDelegate
- (void)simulateStateChanged:(BOOL)isSimulate;
- (void)solidStateChanged:(BOOL)isSolid;
- (void)staticStateChanged:(BOOL)isStatic;
- (void)materialChanged:(int)mat;
@end

@interface PSPhysicsStateViewController : UIViewController
@property(nonatomic, retain) IBOutlet UIButton* simulateButton;
@property(nonatomic, retain) IBOutlet UIButton* solidButton;
@property(nonatomic, retain) IBOutlet UIButton* staticButton;
@property(nonatomic, retain) IBOutletCollection(UIButton) NSArray* materialButtons;
@property(nonatomic, retain) IBOutlet UIButton* defaultMatButton;
@property(nonatomic) BOOL isSimulate;
@property(nonatomic) BOOL isSolid;
@property(nonatomic) BOOL isStatic;
@property(nonatomic) int mat;
@property(nonatomic,weak) id<PSPhysicalStateChangeDelegate> delegate;

- (IBAction)setSimulateState:(id)sender;
- (IBAction)setSolidState:(id)sender;
- (IBAction)setStaticState:(id)sender;
- (IBAction)setMaterial:(id)sender;
- (void)setToDefaults;
- (void)refreshButtons;

@end
