//
//  PSContanctListener.m
//  PlaySketch
//
//  Created by Yang Liu on 16/11/12.
//  Copyright (c) 2012 Singapore Management University. All rights reserved.
//

#include "PSContactListener.h"

#include <cstdio>

void ContactListener::Add(const b2ContactPoint *point)
{
    if (_contactData->contactPointCount == maxContactPoints)
	{
		return;
	}
    
    ContactPoint* cp = _contactData->contactPoints + _contactData->contactPointCount;
    cp->shape1 = point->shape1;
    cp->shape2 = point->shape2;
    cp->position = point->position;
	cp->normal = point->normal;
	cp->id = point->id;
	cp->state = e_contactAdded;
    
    printf("Contact point with id %d added, state: e_contactAdded\n", point->id.key);
    int index1 = (int)point->shape1->GetBody()->GetUserData();
    int index2 = (int)point->shape2->GetBody()->GetUserData();
    printf("Contact body indices %d , %d\n", index1, index2);
    
	++_contactData->contactPointCount;
}

void ContactListener::Persist(const b2ContactPoint *point)
{
    if (_contactData->contactPointCount == maxContactPoints)
	{
		return;
	}
    
    ContactPoint* cp = _contactData->contactPoints + _contactData->contactPointCount;
    cp->shape1 = point->shape1;
	cp->shape2 = point->shape2;
	cp->position = point->position;
	cp->normal = point->normal;
	cp->id = point->id;
	cp->state = e_contactPersisted;
    
    printf("Contact point with id %d persisted, state: e_contactPersisted\n", point->id.key);
    
    ++_contactData->contactPointCount;
}

void ContactListener::Remove(const b2ContactPoint *point)
{
    if (_contactData->contactPointCount == maxContactPoints)
	{
		return;
	}
    
    ContactPoint* cp = _contactData->contactPoints + _contactData->contactPointCount;
    cp->shape1 = point->shape1;
	cp->shape2 = point->shape2;
	cp->position = point->position;
	cp->normal = point->normal;
	cp->id = point->id;
	cp->state = e_contactRemoved;
    
    printf("Contact point with id %d removed, state: e_contactRemoved\n", point->id.key);
    
    ++_contactData->contactPointCount;
}

ContactData::ContactData()
{
    contactPointCount = 0;
    cntactListener._contactData = this;
}

ContactData::~ContactData() {}

