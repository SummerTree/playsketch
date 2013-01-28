//
//  PSPhysicsStateViewController.m
//  PlaySketch
//
//  Created by Yang Liu on 29/10/12.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#import "PSPhysicsStateViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "PSGraphicConstants.h"

@implementation PSPhysicsStateViewController

- (IBAction)setSimulateState:(id)sender
{
    self.isSimulate = !self.isSimulate;
    
	UIButton* b = (UIButton*)sender;
    if (self.isSimulate)
        b.layer.shadowRadius = 10.0;
    else
        b.layer.shadowRadius = 0.0;
	b.layer.shadowColor = HIGHLIGHTED_BUTTON_UICOLOR.CGColor;
	b.layer.shadowOffset = CGSizeMake(0,0);
	b.layer.shadowOpacity = 1.0;
	
	if(self.delegate)
		[self.delegate simulateStateChanged:self.isSimulate];
}

- (IBAction)setSolidState:(id)sender
{
    self.isSolid = !self.isSolid;
    
    UIButton* b = (UIButton*)sender;
    if (self.isSolid) {
        b.layer.shadowRadius = 10.0;
    } else
        b.layer.shadowRadius = 0.0;
	b.layer.shadowColor = HIGHLIGHTED_BUTTON_UICOLOR.CGColor;
	b.layer.shadowOffset = CGSizeMake(0,0);
	b.layer.shadowOpacity = 1.0;
	
    [self setMaterial:self.defaultMatButton];
    
	if(self.delegate)
		[self.delegate solidStateChanged:self.isSolid];
}

- (IBAction)setStaticState:(id)sender
{
    self.isStatic = !self.isStatic;
    
    UIButton* b = (UIButton*)sender;
    if (self.isStatic) {
        b.layer.shadowRadius = 10.0;
    } else
        b.layer.shadowRadius = 0.0;
	b.layer.shadowColor = HIGHLIGHTED_BUTTON_UICOLOR.CGColor;
	b.layer.shadowOffset = CGSizeMake(0,0);
	b.layer.shadowOpacity = 1.0;
    
	if(self.delegate)
		[self.delegate staticStateChanged:self.isStatic];
}

- (IBAction)setMaterial:(id)sender
{
    for (UIButton* b in self.materialButtons)
		b.layer.shadowRadius = 0.0;
    
	UIButton* b = (UIButton*)sender;
    if (self.isSolid) {
        b.layer.shadowRadius = 10.0;
    } else {
        b.layer.shadowRadius = 0.0;
    }
	b.layer.shadowColor = HIGHLIGHTED_BUTTON_UICOLOR.CGColor;
	b.layer.shadowOffset = CGSizeMake(0,0);
	b.layer.shadowOpacity = 1.0;
	
    self.mat = b.tag;
    
	if(self.delegate)
		[self.delegate materialChanged:b.tag];
}

- (void)setToDefaults
{
    self.isSimulate = false;
    self.isSolid = false;
    self.isStatic = false;
    self.mat = 1;
}

- (void)refreshButtons
{
    UIButton* b = self.simulateButton;
    b.layer.shadowRadius = self.isSimulate ? 10.0 : 0.0;
    b.layer.shadowColor = HIGHLIGHTED_BUTTON_UICOLOR.CGColor;
	b.layer.shadowOffset = CGSizeMake(0,0);
	b.layer.shadowOpacity = 1.0;
    NSLog(@"SIM shadowRadius: %f", b.layer.shadowRadius);
    
    b = self.solidButton;
    b.layer.shadowRadius = self.isSolid ? 10.0 : 0.0;
    b.layer.shadowColor = HIGHLIGHTED_BUTTON_UICOLOR.CGColor;
	b.layer.shadowOffset = CGSizeMake(0,0);
	b.layer.shadowOpacity = 1.0;
    NSLog(@"SOLID shadowRadius: %f", b.layer.shadowRadius);
    
    b = self.staticButton;
    b.layer.shadowRadius = self.isStatic ? 10.0 : 0.0;
    b.layer.shadowColor = HIGHLIGHTED_BUTTON_UICOLOR.CGColor;
	b.layer.shadowOffset = CGSizeMake(0,0);
	b.layer.shadowOpacity = 1.0;
    
    for (UIButton* m in self.materialButtons)
        if (m.tag == self.mat)
            b = m;
        else
            m.layer.shadowRadius = 0.0;
    b.layer.shadowRadius = self.isSolid ? 10.0 : 0.0;
    b.layer.shadowColor = HIGHLIGHTED_BUTTON_UICOLOR.CGColor;
	b.layer.shadowOffset = CGSizeMake(0,0);
	b.layer.shadowOpacity = 1.0;
}

@end
