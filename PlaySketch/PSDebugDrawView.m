//
//  PSDebugDrawView.m
//  PlaySketch
//
//  Created by Yang Liu on 18/2/13.
//  Copyright (c) 2013 Singapore Management University. All rights reserved.
//

#import "PSDebugDrawView.h"

@implementation PSDebugDrawView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setBackgroundColor:[UIColor clearColor]];
        [self setOrigin:[[NSMutableArray alloc] initWithCapacity:0]];
        [self setTarget:[[NSMutableArray alloc] initWithCapacity:0]];
    }
    return self;
}

- (void)setOrigin:(NSMutableArray *)origin
{
    _origin = origin;
}

- (void)setTarget:(NSMutableArray *)target
{
    _target = target;
}

- (void)addToOrigin:(NSMutableArray*)arr
{
    [_origin addObjectsFromArray:(NSArray*)arr];
}

- (void)addToTarget:(NSMutableArray*)arr
{
    [_target addObjectsFromArray:(NSArray*)arr];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    //CGContextSetAlpha(context,0.5);
    
    CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
    CGContextSetLineWidth(context, 2.0);
    
    for (int i = 0; i<_origin.count; i++) {
        CGPoint a = [[_origin objectAtIndex:i] CGPointValue];
        CGPoint b = [[_target objectAtIndex:i] CGPointValue];
        CGContextMoveToPoint(context, a.x, a.y);
        CGContextAddLineToPoint(context,b.x, b.y);
    }
    
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}


@end
