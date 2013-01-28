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
@synthesize gravitySliderLabel;
@synthesize windSliderLabel;

- (IBAction)setGravity:(id)sender
{
	for (UIButton* b in self.gravityButtons)
		b.layer.shadowRadius = 0.0;
    
	UIButton* b = (UIButton*)sender;
    if (self.gravityOn) {
        b.layer.shadowRadius = 10.0;
        if(self.delegate)
            [self.delegate gravityChanged:b.tag];
    }else {
        b.layer.shadowRadius = 0.0;
        if(self.delegate)
            [self.delegate gravityChanged:0];
    }
	b.layer.shadowColor = HIGHLIGHTED_BUTTON_UICOLOR.CGColor;
	b.layer.shadowOffset = CGSizeMake(0,0);
	b.layer.shadowOpacity = 1.0;
    
	
}
- (IBAction)setGravityState:(id)sender
{
    UIButton* b = (UIButton*)sender;
    
    if (self.gravityOn) {
        b.selected = false;
        self.gravityOn = false;
    } else {
        b.selected = true;
        self.gravityOn = true;
    }
    
    [self setGravity:self.defaultGravityButtons];
}

- (IBAction)setWindState:(id)sender
{
    UIButton* b = (UIButton*)sender;
    self.windOn = (self.windOn+2) % 3 - 1;
    NSLog(@"%d", self.windOn);
    
    switch (self.windOn) {
        case -1:
            [b setImage:[UIImage imageNamed:@"temp_wind_left"] forState:UIControlStateNormal];
            break;
        case 0:
            [b setImage:[UIImage imageNamed:@"temp_wind_off"] forState:UIControlStateNormal];
            break;
        case 1:
            [b setImage:[UIImage imageNamed:@"temp_wind_right"] forState:UIControlStateNormal];
            break;
    }
    
    [self setWind:self.defaultWindButtons];
}

- (IBAction)gravitySliderChanged:(id)sender
{
    UISlider * slider = (UISlider *)sender;
    int progressAsInt = (int)(slider.value + 0.5f);
    NSString * newText = [[NSString alloc] initWithFormat:@"%d", progressAsInt];
    gravitySliderLabel.text = newText;
    
    if(self.delegate)
		[self.delegate gravityChanged:self.gravityOn ? progressAsInt : 0];
}

- (IBAction)windSliderChanged:(id)sender
{
    UISlider * slider = (UISlider *)sender;
    int progressAsInt = (int)(slider.value + 0.5f);
    NSString * newText = [[NSString alloc] initWithFormat:@"%d", progressAsInt];
    windSliderLabel.text = newText;
    
    if(self.delegate)
		[self.delegate windChanged:progressAsInt*self.windOn];
}

- (IBAction)setWind:(id)sender
{
	for (UIButton* b in self.windButtons)
		b.layer.shadowRadius = 0.0;
	
	UIButton* b = (UIButton*)sender;
	if (self.windOn)
        b.layer.shadowRadius = 10.0;
    else
        b.layer.shadowRadius = 0.0;
	b.layer.shadowColor = HIGHLIGHTED_BUTTON_UICOLOR.CGColor;
	b.layer.shadowOffset = CGSizeMake(0,0);
	b.layer.shadowOpacity = 1.0;
	
	if(self.delegate)
		[self.delegate windChanged:b.tag*self.windOn];
    
}

- (void)setToDefaults
{
    self.gravityOn = false;
    self.windOn = 0;
}

@end
