//
//  DCELMesh.cpp
//  PlaySketch
//
//  Created by Yang Liu on 15/12/12.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#include "DCELMesh.h"

DCELMesh::DCELMesh()
{
	vertexList = NULL;
	halfEdgeList = NULL;
    
	numHalfEdges = 0;
	numVertices = 0;
	min.x = min.y = min.z = -1.0;
	max.x = max.y = max.z = 1.0;
	vertexTotal.zero();
}

DCELMesh::~DCELMesh()
{
	clear();
}

void DCELMesh::clear()
{
	DCELVertex* walkerV = vertexList;
	DCELVertex* tempV = NULL;
	while (walkerV) {
		tempV = walkerV->globalNext;
		delete walkerV;
		walkerV = tempV;
	}
	vertexList = NULL;
	DCELHalfEdge* walkerE = halfEdgeList;
	DCELHalfEdge* tempE = NULL;
	while (walkerE) {
		tempE = walkerE->globalNext;
		delete walkerE;
		walkerE = tempE;
	}
	halfEdgeList = NULL;
    
	numHalfEdges = 0;
	numVertices = 0;
	min.x = min.y = min.z = -1.0;
	max.x = max.y = max.z = 1.0;
	vertexTotal.zero();
}

bool DCELMesh::isEmpty() const
{
	return ((vertexList == NULL) && (halfEdgeList == NULL));
}

void DCELMesh::insert(DCELVertex* v)
{
	if (v) {
		if (vertexList) {
			v->globalNext = vertexList;
			vertexList->globalPrev = v;
			vertexList = v;
		} else {
			vertexList = v;
		}
		numVertices++;
	}
}

void DCELMesh::updateEdges(DCELHalfEdge* e)
{
	if (e) {
        //printf("\tStart check intersection for edges\n");
        bool isIntersecting = false;
        DCELVertex* head = vertexList;
        
        while (head != NULL) {
            DCELHalfEdge* leave = head->leaving;
            
            while (leave != NULL) {
                DCELVertex* a = e->origin;
                DCELVertex* b = e->tail;
                DCELVertex* c = leave->origin;
                DCELVertex* d = leave->tail;
                
                // if there are same points among a b c d
                if (a==d || b==c || a==c || d==b) {
                    //printf("        Connected edges\n");
                    leave = leave->globalNext;
                    continue;
                }
                
                // if a-b and c-d are parallel
                if (fabsf((b->coords.y - a->coords.y) * (c->coords.x - d->coords.x)
                          - (b->coords.x - a->coords.x) * (c->coords.y - d->coords.y)) < 0.00001) {
                    leave = leave->globalNext;
                    //printf("        Parallel edges\n");
                    continue;
                }
                
                // intersection point
                float x = ((b->coords.x - a->coords.x)
                           * (c->coords.x - d->coords.x)
                           * (c->coords.y - a->coords.y)
                           - c->coords.x
                           * (b->coords.x - a->coords.x)
                           * (c->coords.y - d->coords.y)
                           + a->coords.x
                           * (b->coords.y - a->coords.y)
                           * (c->coords.x - d->coords.x))
                / ((b->coords.y - a->coords.y) * (c->coords.x - d->coords.x)
                   - (b->coords.x - a->coords.x) * (c->coords.y - d->coords.y));
                float y =  ((b->coords.y - a->coords.y)
                            * (c->coords.y - d->coords.y)
                            * (c->coords.x - a->coords.x)
                            - c->coords.y
                            * (b->coords.y - a->coords.y)
                            * (c->coords.x - d->coords.x)
                            + a->coords.y
                            * (b->coords.x - a->coords.x)
                            * (c->coords.y - d->coords.y))
                / ((b->coords.x - a->coords.x) * (c->coords.y - d->coords.y)
                   - (b->coords.y - a->coords.y) * (c->coords.x - d->coords.x));
                
                if ((x - a->coords.x) * (x - b->coords.x) <= 0
                    && (x - c->coords.x) * (x - d->coords.x) <= 0
                    && (y - a->coords.y) * (y - b->coords.y) <= 0
                    && (y - c->coords.y) * (y - d->coords.y) <= 0)
                {
                    isIntersecting = true;
                    //printf("        Intersected edges\n");
                    //printf("            a:%f %f, b:%f %f, c:%f %f, d:%f %f, e:%f %f\n", a->coords.x, a->coords.y, b->coords.x, b->coords.y, c->coords.x, c->coords.y, d->coords.x, d->coords.y, x, y);
                    DCELVertex* intersectionPoint = new DCELVertex();
                    intersectionPoint->coords.x = x;
                    intersectionPoint->coords.y = y;
                    
                    if (!VertexExist(intersectionPoint))
                    {
                        //printf("\t\t\tNew vertex created\n");
                        insert(intersectionPoint);
                        // split c-d into c-iP, iP-d
                        leave->tail = intersectionPoint;
                        intersectionPoint->AddLeavingEdge(d);
                        
                        // find and split d-c into d-iP, iP-c
                        DCELHalfEdge* DLeave = d->leaving;
                        while (DLeave != NULL) {
                            //printf("\t\t\tLooping d->leaving for d-c\n");
                            
                            if (DLeave->tail == c)
                            {
                                //printf("\t\t\t\tFound d-c\n");
                                DLeave->tail = intersectionPoint;
                                intersectionPoint->AddLeavingEdge(c);
                                break;
                            }
                            
                            DLeave = DLeave->globalNext;
                        }
                        
                        // split a-b into a-iP, iP-b
                        e->tail = intersectionPoint;
                        intersectionPoint->AddLeavingEdge(b);
                        
                        // find and split b-a into b-iP, iP-b
                        DCELHalfEdge* BLeave = b->leaving;
                        while (BLeave != NULL) {
                            //printf("\t\t\tLooping b->leaving for b-a\n");
                            
                            if (BLeave->tail == a)
                            {
                                //printf("\t\t\t\tFound b-a\n");
                                BLeave->tail = intersectionPoint;
                                intersectionPoint->AddLeavingEdge(a);
                                break;
                            }
                            
                            BLeave = BLeave->globalNext;
                        }
                        
                        updateEdges(intersectionPoint->leaving);
                    } else {
                        //printf("\t\t\tIntersection point exists\n");
                    }
                    
                   
                }
                
                //if (!isIntersecting)
                   // printf("        Non intersected edges\n");
                
                leave = leave->globalNext;
            }
            
            advance(head);
        } // end of while loop
        
		numHalfEdges++;
	}
}

bool DCELMesh::VertexExist(DCELVertex* v)
{
    DCELVertex* first = firstVertex();
    
    while (first != NULL) {
        if (fabsf(first->coords.x - v->coords.x) < 0.0001
            && fabsf(first->coords.y - v->coords.y) < 0.0001)
        {
            v = first;
            return true;
        }
        
        first = first->globalNext;
    }
    
    return false;
}

void DCELMesh::remove(DCELVertex* v)
{
	if (v) {
		if (vertexList == v) {
			vertexList = vertexList->globalNext;
			if (vertexList) {
				vertexList->globalPrev = NULL;
			}
		} else {
			v->globalPrev->globalNext = v->globalNext;
			if (v->globalNext) {
				v->globalNext->globalPrev = v->globalPrev;
			}
		}
		v->globalNext = NULL;
		v->globalPrev = NULL;
		numVertices--;
	}
}

void DCELMesh::remove(DCELHalfEdge* e)
{
	if (e) {
		if (halfEdgeList == e) {
			halfEdgeList = halfEdgeList->globalNext;
			if (halfEdgeList) {
				halfEdgeList->globalPrev = NULL;
			}
		} else {
			e->globalPrev->globalNext = e->globalNext;
			if (e->globalNext) {
				e->globalNext->globalPrev = e->globalPrev;
			}
		}
		e->globalNext = NULL;
		e->globalPrev = NULL;
		numHalfEdges--;
	}
}

void DCELMesh::updateStatistics()
{
	vertexTotal.zero();
    
	DCELVertex* walkerV = vertexList;
	if (walkerV) {
		min = walkerV->coords;
		max = walkerV->coords;
		vertexTotal.translateBy(walkerV->coords);
		walkerV = walkerV->globalNext;
	}
	while (walkerV) {
		if (walkerV->coords.x < min.x) {
			min.x = walkerV->coords.x;
		} else if (walkerV->coords.x > max.x) {
			max.x = walkerV->coords.x;
		}
		if (walkerV->coords.y < min.y) {
			min.y = walkerV->coords.y;
		} else if (walkerV->coords.y > max.y) {
			max.y = walkerV->coords.y;
		}
		if (walkerV->coords.z < min.z) {
			min.z = walkerV->coords.z;
		} else if (walkerV->coords.z > max.z) {
			max.z = walkerV->coords.z;
		}
		vertexTotal.translateBy(walkerV->coords);
		advance(walkerV);
	}
}

Vector DCELMesh::getCentroid() const
{
	return vertexTotal * (1.0 / (double)numVertices);
}

void DCELMesh::updateAll()
{
	updateStatistics();
}


