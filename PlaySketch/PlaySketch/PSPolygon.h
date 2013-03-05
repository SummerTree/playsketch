//
//  PSPolygon.h
//  PlaySketch
//
//  Created by Yang Liu on 5/2/13.
//  Copyright (c) 2013 Singapore Management University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSTriangle.h"

@interface PSPolygon : NSObject
{
    NSMutableArray *x;
    NSMutableArray *y;
    int nVertices;
}

-(id) initWithPoints:(NSMutableArray*)_x Y:(NSMutableArray*)_y;
-(id) initWithTriangle:(PSTriangle*) t;
-(void) Set:(PSPolygon*) p;
-(PSPolygon*) Add:(PSTriangle*) t;
-(BOOL) IsConvex;
-(NSMutableArray*) getX;
-(NSMutableArray*) getY;
-(int) getN;
@end
