//
//  PSOpenGLESHelper.h
//  PlaySketch
//
//  Created by Yang Liu on 18/2/13.
//  Copyright (c) 2013 Singapore Management University. All rights reserved.
//

#ifndef PlaySketch_PSOpenGLESHelper_h
#define PlaySketch_PSOpenGLESHelper_h

typedef struct {
    GLfloat x;
    GLfloat y;
    GLfloat z;
} Vertex3D;

static inline Vertex3D Vertex3DMake(CGFloat inX, CGFloat inY, CGFloat inZ)
{
    Vertex3D ret;
    ret.x = inX;
    ret.y = inY;
    ret.z = inZ;
    return ret;
}

static inline GLfloat Vertex3DCalculateDistanceBetweenVertices (Vertex3D first, Vertex3D second)
{
    GLfloat deltaX = second.x - first.x;
    GLfloat deltaY = second.y - first.y;
    GLfloat deltaZ = second.z - first.z;
    return sqrtf(deltaX*deltaX + deltaY*deltaY + deltaZ*deltaZ );
};

typedef struct {
    Vertex3D v1;
    Vertex3D v2;
    Vertex3D v3;
} Triangle3D;

static inline Triangle3D Triangle3DMake(Vertex3D vertex1, Vertex3D  vertex2, Vertex3D  vertex3)
{
    Triangle3D tri;
    tri.v1 = vertex1;
    tri.v2 = vertex2;
    tri.v3 = vertex3;
    return tri;
};
#endif
