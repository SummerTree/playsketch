//
//  PSPolygon.m
//  PlaySketch
//
//  Created by Yang Liu on 5/2/13.
//  Copyright (c) 2013 Singapore Management University. All rights reserved.
//

#import "PSPolygon.h"

@implementation PSPolygon

-(id) initWithPoints:(NSMutableArray *)_x Y:(NSMutableArray *)_y
{
    if (self = [super init])
    {
        x = _x;
        y = _y;
        nVertices = x.count;
    }
    
    return self;
}

-(id) initWithTriangle:(PSTriangle *)t
{
    if (self = [super init])
    {
        x = [t getX];
        y = [t getY];
        nVertices = 3;
    }
    
    return self;
}

-(void) Set:(PSPolygon*) p;
{
    x = [p getX];
    y = [p getY];
    nVertices = [p getX].count;
}

/*
 * Tries to add a triangle to the polygon.
 * Returns null if it can't connect properly.
 * Assumes bitwise equality of join vertices.
 */
-(PSPolygon*)Add:(PSTriangle*) t
{
    //First, find vertices that connect
    int firstP = -1;
    int firstT = -1;
    int secondP = -1;
    int secondT = -1;
    
    //    println("nVertices: "+this.nVertices);
    NSMutableArray* xT = [t getX];
    NSMutableArray* yT = [t getY];
    
    for (int i=0; i < x.count; i++){
        if (fabsf([[xT objectAtIndex:0] floatValue] - [[x objectAtIndex:i] floatValue]) < 0.001
            && fabsf([[yT objectAtIndex:0] floatValue] - [[y objectAtIndex:i] floatValue]) < 0.001){
                    printf("found p0\n");
            if (firstP == -1){
                firstP = i; firstT = 0;
            } else{
                secondP = i; secondT = 0;
            }
        } else if (fabsf([[xT objectAtIndex:1] floatValue] - [[x objectAtIndex:i] floatValue]) < 0.001
                   && fabsf([[yT objectAtIndex:1] floatValue] - [[y objectAtIndex:i] floatValue]) < 0.001){
                    printf("found p1\n");
            if (firstP == -1){
                firstP = i; firstT = 1;
            } else{
                secondP = i; secondT = 1;
            }
        } else if (fabsf([[xT objectAtIndex:2] floatValue] - [[x objectAtIndex:i] floatValue]) < 0.001
                   && fabsf([[yT objectAtIndex:2] floatValue] - [[y objectAtIndex:i] floatValue]) < 0.001){
                    printf("found p2\n");
            if (firstP == -1){
                firstP = i; firstT = 2;
            } else{
                secondP = i; secondT = 2;
            }
        } else {
            //        println(t.x[0]+" "+t.y[0]+" "+t.x[1]+" "+t.y[1]+" "+t.x[2]+" "+t.y[2]);
            //        println(x[0]+" "+y[0]+" "+x[1]+" "+y[1]);
        }
    }
    //Fix ordering if first should be last vertex of poly
    if (firstP == 0 && secondP == x.count-1){
        firstP = x.count-1;
        secondP = 0;
    }
    
    //Didn't find it
    if (secondP == -1) {
        //printf("Not found\n");
       return NULL; 
    }
    
    //Find tip index on triangle
    int tipT = 0;
    if (tipT == firstT || tipT == secondT) tipT = 1;
    if (tipT == firstT || tipT == secondT) tipT = 2;
    
    NSMutableArray* newX = [[NSMutableArray alloc] initWithCapacity:0];
    NSMutableArray* newY = [[NSMutableArray alloc] initWithCapacity:0];
    
    for (int i = 0; i<x.count; i++) {
        [newX addObject:[NSNumber numberWithFloat:[[x objectAtIndex:i] floatValue]]];
        [newY addObject:[NSNumber numberWithFloat:[[y objectAtIndex:i] floatValue]]];
        
        if (i == firstP) {
            [newX addObject:[NSNumber numberWithFloat:[[xT objectAtIndex:tipT] floatValue]]];
            [newY addObject:[NSNumber numberWithFloat:[[yT objectAtIndex:tipT] floatValue]]];
        }
    }
    
    //nVertices = newX.count;
    NSLog(@"Number of vertices %d", x.count);
    return [[PSPolygon alloc] initWithPoints:newX Y:newY];
}

/*
 * Assuming the polygon is simple, checks
 * if it is convex.
 */
-(BOOL) IsConvex
{
    BOOL isPositive = false;
    for (int i=0; i<x.count; ++i){
        int lower = (i==0)?(x.count-1):(i-1);
        int middle = i;
        int upper = (i==x.count-1)?(0):(i+1);
        
        float dx0 = [[x objectAtIndex:middle] floatValue]-[[x objectAtIndex:lower] floatValue];
        float dy0 = [[y objectAtIndex:middle] floatValue]-[[y objectAtIndex:lower] floatValue];
        float dx1 = [[x objectAtIndex:upper] floatValue]-[[x objectAtIndex:middle] floatValue];
        float dy1 = [[x objectAtIndex:upper] floatValue]-[[y objectAtIndex:middle] floatValue];
        float cross = dx0*dy1-dx1*dy0;
        //Cross product should have same sign
        //for each vertex if poly is convex.
        BOOL newIsP = (cross>0)?true:false;
        if (i==0){
            isPositive = newIsP;
        } else if (isPositive != newIsP){
            return false;
        }
    }
    return true;
}

-(NSMutableArray*) getX { return x; }

-(NSMutableArray*) getY { return y; }

-(int) getN {return nVertices; }
@end
