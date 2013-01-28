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
    
    ++_contactData->contactPointCount;
}

ContactData::ContactData()
{
    contactPointCount = 0;
    cntactListener._contactData = this;
}

ContactData::~ContactData() {}

