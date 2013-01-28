//
//  PSContanctListener.h
//  PlaySketch
//
//  Created by Yang Liu on 16/11/12.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "Box2D.h"

class ContactData;

const int32 maxContactPoints = 2048;

class ContactListener : public b2ContactListener
{
public:
    void Add(const b2ContactPoint* point);
    void Persist(const b2ContactPoint* point);
    void Remove(const b2ContactPoint* point);
    
    ContactData* _contactData;
};

enum ContactState
{
	e_contactAdded,
	e_contactPersisted,
	e_contactRemoved,
};

struct ContactPoint
{
	b2Shape* shape1;
	b2Shape* shape2;
	b2Vec2 normal;
	b2Vec2 position;
	b2Vec2 velocity;
	b2ContactID id;
	ContactState state;
};

class ContactData
{
public:
    ContactData();
    virtual ~ContactData();
    
    friend class ContactListener;
    
    ContactListener cntactListener;
    ContactPoint contactPoints[maxContactPoints];
    int32 contactPointCount;
};







