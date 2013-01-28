//
//  Triangle.h
//  PlaySketch
//
//  Created by Yang Liu on 22/1/13.
//  Copyright (c) 2013 Singapore Management University. All rights reserved.
//

#ifndef __PlaySketch__Triangle__
#define __PlaySketch__Triangle__

#include <iostream>

class Triangle
{
    public :
    Triangle();
    Triangle(float x1, float y1, float x2, float y2, float x3, float y3);
    ~Triangle();
    
    float x[3];
    float y[3];
    
    bool isInside(float _x, float _y);
};

#endif /* defined(__PlaySketch__Triangle__) */
