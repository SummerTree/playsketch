//
//  PSTriangle.m
//  PlaySketch
//
//  Created by Yang Liu on 5/2/13.
//  Copyright (c) 2013 Singapore Management University. All rights reserved.
//

#import "PSTriangle.h"

@implementation PSTriangle

-(id) initWithPoints:(float)x1 Y1:(float)y1 X2:(float)x2 Y2:(float)y2 X3:(float)x3 Y3:(float)y3
{
    if (self = [super init])
    {
        float dx1 = x2-x1;
        float dx2 = x3-x1;
        float dy1 = y2-y1;
        float dy2 = y3-y1;
        float cross = dx1*dy2-dx2*dy1;
        bool ccw = (cross>0);
        x = [[NSMutableArray alloc] initWithCapacity:0];
        y = [[NSMutableArray alloc] initWithCapacity:0];
        
        if (ccw){
            [x addObject:[NSNumber numberWithFloat:x1]];
            [x addObject:[NSNumber numberWithFloat:x2]];
            [x addObject:[NSNumber numberWithFloat:x3]];
            [y addObject:[NSNumber numberWithFloat:y1]];
            [y addObject:[NSNumber numberWithFloat:y2]];
            [y addObject:[NSNumber numberWithFloat:y3]];
        } else{
            [x addObject:[NSNumber numberWithFloat:x1]];
            [x addObject:[NSNumber numberWithFloat:x3]];
            [x addObject:[NSNumber numberWithFloat:x2]];
            [y addObject:[NSNumber numberWithFloat:y1]];
            [y addObject:[NSNumber numberWithFloat:y3]];
            [y addObject:[NSNumber numberWithFloat:y2]];
        }
    }
    
    return self;
}

-(BOOL) IsInside:(float)_x Y:(float)_y
{
    float x0 = [[x objectAtIndex:0] floatValue];
    float x1 = [[x objectAtIndex:1] floatValue];
    float x2 = [[x objectAtIndex:2] floatValue];
    float y0 = [[y objectAtIndex:0] floatValue];
    float y1 = [[y objectAtIndex:1] floatValue];
    float y2 = [[y objectAtIndex:2] floatValue];
    
    float vx2 = _x-x0; float vy2 = _y-y0;
    float vx1 = x1-x0; float vy1 = y1-y0;
    float vx0 = x2-x0; float vy0 = y2-y0;
    
    float dot00 = vx0*vx0+vy0*vy0;
    float dot01 = vx0*vx1+vy0*vy1;
    float dot02 = vx0*vx2+vy0*vy2;
    float dot11 = vx1*vx1+vy1*vy1;
    float dot12 = vx1*vx2+vy1*vy2;
    float invDenom = 1.0 / (dot00*dot11 - dot01*dot01);
    float u = (dot11*dot02 - dot01*dot12)*invDenom;
    float v = (dot00*dot12 - dot01*dot02)*invDenom;
    
    return ((u>0)&&(v>0)&&(u+v<1));
}

-(NSMutableArray*) getX { return x; }

-(NSMutableArray*) getY { return y; }
@end
