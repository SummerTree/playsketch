//
//  DCELHalfEdge.h
//  PlaySketch
//
//  Created by Yang Liu on 15/12/12.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#ifndef DCELHALFEDGE_H
#define DCELHALFEDGE_H

class DCELVertex;

class DCELHalfEdge
{
public:
	DCELHalfEdge();
	~DCELHalfEdge();
    
	DCELHalfEdge* twin;
	DCELHalfEdge* next;
	DCELVertex* origin;
    DCELVertex* tail;
	void* auxData;
    
	DCELHalfEdge* getPrev();
    
	friend class DCELMesh;

	DCELHalfEdge* globalNext;
	DCELHalfEdge* globalPrev;
};

#endif
