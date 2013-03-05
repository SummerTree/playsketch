//
//  b2Separator.h
//  PlaySketch
//
//  Created by Yang Liu on 26/2/13.
//  Copyright (c) 2013 Singapore Management University. All rights reserved.
//

#ifndef __PlaySketch__b2Separator__
#define __PlaySketch__b2Separator__

#include <Box2D.h>
#include <vector>
#include <queue>
#include <algorithm>

class b2Separator {
    
public:
    
    b2Separator() {}
    
    void Separate(b2Body* pBody, std::vector<b2Vec2>* pVerticesVec, int scale, int mat, bool isStatic);
    
    int Validate(const std::vector<b2Vec2>& verticesVec);
    
    
private:
    
    void calcShapes(std::vector<b2Vec2> &pVerticesVec, std::vector<std::vector<b2Vec2> > &result);
	b2Vec2* hitRay(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4);
	b2Vec2* hitSegment(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4);
	bool isOnSegment(float px, float py, float x1, float y1, float x2, float y2);
    bool pointsMatch(float x1, float y1, float x2,float y2);
    bool isOnLine(float px, float py, float x1, float y1, float x2, float y2);
    float det( float x1, float y1, float x2, float y2, float x3, float y3);
};

#endif /* defined(__PlaySketch__b2Separator__) */
