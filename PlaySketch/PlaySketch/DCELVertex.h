//
//  DCELVertex.h
//  PlaySketch
//
//  Created by Yang Liu on 15/12/12.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#include "Vector.h"
#include "DCELHalfEdge.h"

class DCELVertex
{
public:
	DCELVertex();
	~DCELVertex();
    
	Vector coords;
    
	DCELHalfEdge* leaving;
    
	void* auxData;
    
    void AddLeavingEdge(DCELVertex* tail);
    
	DCELHalfEdge* getEdgeTo(const DCELVertex* v) const;
    
	//friend class DCELMesh;

	DCELVertex* globalNext;
	DCELVertex* globalPrev;
};
