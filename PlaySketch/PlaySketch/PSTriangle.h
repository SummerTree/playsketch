//
//  PSTriangle.h
//  PlaySketch
//
//  Created by Yang Liu on 5/2/13.
//  Copyright (c) 2013 Singapore Management University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PSTriangle : NSObject
{
    NSMutableArray *x;
    NSMutableArray *y;
}

-(id) initWithPoints:(float)x1 Y1:(float)y1 X2:(float)x2 Y2:(float)y2 X3:(float)x3 Y3:(float)y3;
-(BOOL) IsInside:(float)_x Y:(float)_y;
-(NSMutableArray*) getX;
-(NSMutableArray*) getY;
@end
