//
//  DCELMesh.h
//  PlaySketch
//
//  Created by Yang Liu on 15/12/12.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#include "DCELVertex.h"
#include "DCELHalfEdge.h"
#include <cstdlib>
#include <cmath>
#include <cstdio>

class DCELMesh
{
public:
	DCELMesh();
	~DCELMesh();
    
	// Simple iteration interface. Supports forward traversal only
	DCELVertex* firstVertex() { return vertexList; };
	DCELVertex* next(DCELVertex* v) { return (v != NULL) ? v->globalNext : NULL; };
	void advance(DCELVertex* &v) { v = (v != NULL) ? v->globalNext : NULL; };
    
	DCELHalfEdge* firstHalfEdge() { return halfEdgeList; };
	DCELHalfEdge* next(DCELHalfEdge* e) { return (e != NULL) ? e->globalNext : NULL; };
	void advance(DCELHalfEdge* &e) { e = (e != NULL) ? e->globalNext : NULL; };
    
	void clear();
	
	bool isEmpty() const;
    
    bool VertexExist(DCELVertex* v);
    
	// Inserts the object at the head of the appropriate list. This means that insertion
	// is a safe operation during processing of all objects of a particular type, because
	// they will be inserted before the current iterator position.
	void insert(DCELVertex* v);
	void updateEdges(DCELHalfEdge* e);
    
	// Removes from the mesh holder, but does not delete or disconnect. Caller is responsible
	// for correct usage. Removing an object that is not in the mesh is an unsafe operation.
	void remove(DCELVertex* v);
	void remove(DCELHalfEdge* e);
    
	// Calculates bounding box and internal statistics
	void updateStatistics();
	// Shorthand for calling the above four update functions
	void updateAll();
    
	// Return current counts of member objects
	int getNumVertices() const { return numVertices; };
	int getNumHalfEdges() const { return numHalfEdges; };
    
	// Helper function to set or clear a particular mask on all HalfEdges
	void setHalfEdgeMasks(unsigned int mask, bool value);
    
	// Only valid after an updateStatistics or updateAll call.
	// Returns center of mass of object, assuming all vertices have equal mass
	Vector getCentroid() const;
	void loadBoundingBox(Vector &minPoint, Vector &maxPoint) const { minPoint = min; maxPoint = max; };
    
	DCELVertex* vertexList;
	DCELHalfEdge* halfEdgeList;
    
	int numVertices;
	int numHalfEdges;
    
	Vector min;
	Vector max;
	Vector vertexTotal;
};
