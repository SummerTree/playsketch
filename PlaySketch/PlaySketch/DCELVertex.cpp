//
//  DCELVertex.cpp
//  PlaySketch
//
//  Created by Yang Liu on 15/12/12.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#include "DCELVertex.h"
#include <cstdlib>

DCELVertex::DCELVertex(): leaving(NULL), auxData(NULL), globalPrev(NULL), globalNext(NULL)
{
}

DCELVertex::~DCELVertex()
{
    
}

void DCELVertex::AddLeavingEdge(DCELVertex* tail)
{
    DCELHalfEdge* e = new DCELHalfEdge();
    e->origin = this;
    e->tail = tail;
    
	if (e) {
		if (leaving) {
			e->globalNext = leaving;
			leaving->globalPrev = e;
			leaving = e;
		} else {
			leaving = e;
		}
	}
}

DCELHalfEdge* DCELVertex::getEdgeTo(const DCELVertex* v) const
{
	DCELHalfEdge* rval = NULL;
    
	if (leaving) {
		if (leaving->twin->origin == v) {
			rval = leaving;
		} else {
			DCELHalfEdge* test = leaving->twin->next;
			while (rval == NULL && test != leaving) {
				if (test->twin->origin == v) {
					rval = test;
				} else {
					test = test->twin->next;
				}
			}
		}
	}
    
	return rval;
}
