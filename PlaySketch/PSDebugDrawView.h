//
//  PSDebugDrawView.h
//  PlaySketch
//
//  Created by Yang Liu on 18/2/13.
//  Copyright (c) 2013 Singapore Management University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PSDebugDrawView : UIView

@property (nonatomic,retain) NSMutableArray* origin;
@property (nonatomic,retain) NSMutableArray* target;

- (void)addToOrigin:(NSMutableArray*)arr;
- (void)addToTarget:(NSMutableArray*)arr;

@end
