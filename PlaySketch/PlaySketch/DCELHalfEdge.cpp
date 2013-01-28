//
//  DCELHalfEdge.cpp
//  PlaySketch
//
//  Created by Yang Liu on 15/12/12.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#include "DCELHalfEdge.h"
#include <cstdlib>

DCELHalfEdge::DCELHalfEdge() :
origin(NULL), tail(NULL), twin(NULL), next(NULL),
globalPrev(NULL), globalNext(NULL)
{
}

DCELHalfEdge::~DCELHalfEdge()
{
    
}

DCELHalfEdge* DCELHalfEdge::getPrev()
{
	DCELHalfEdge* rval = twin->next->twin;
	
	while (rval->next != this) {
		rval = rval->next->twin;
	}
    
	return rval;
}
