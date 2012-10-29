//
//  PSPhysicsGlobalViewController.m
//  PlaySketch
//
//  Created by Yang Liu on 27/10/12.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#import "PSPhysicsGlobalViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "PSGraphicConstants.h"

@implementation PSPhysicsGlobalViewController

- (IBAction)setGravity:(id)sender
{
	for (UIButton* b in self.gravityButtons)
		b.layer.shadowRadius = 0.0;
    
    
	UIButton* b = (UIButton*)sender;
	b.layer.shadowRadius = 10.0;
	b.layer.shadowColor = HIGHLIGHTED_BUTTON_UICOLOR.CGColor;
	b.layer.shadowOffset = CGSizeMake(0,0);
	b.layer.shadowOpacity = 1.0;
	
	if(self.delegate)
		[self.delegate gravityChanged:b.tag];
}

- (IBAction)setWind:(id)sender
{
	for (UIButton* b in self.windButtons)
		b.layer.shadowRadius = 0.0;
	
	UIButton* b = (UIButton*)sender;
	b.layer.shadowRadius = 10.0;
	b.layer.shadowColor = HIGHLIGHTED_BUTTON_UICOLOR.CGColor;
	b.layer.shadowOffset = CGSizeMake(0,0);
	b.layer.shadowOpacity = 1.0;
	
	if(self.delegate)
		[self.delegate windChanged:b.tag];
    
}

- (void)setToDefaults
{
	[self setGravity:self.defaultGravityButtons];
	[self setWind:self.defaultWindButtons];
}

@end
