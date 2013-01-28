/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PSDrawingGroup;

@interface PSDrawingLine : NSManagedObject

@property (nonatomic, retain) NSData * pointsAsData;
@property (nonatomic, retain) NSData * pathPointsAsData;
@property (nonatomic, retain) NSNumber* color;
@property (nonatomic, retain) PSDrawingGroup *group;
@property (nonatomic, readonly) CGPoint* points;
@property (nonatomic, readonly) CGPoint* pathPoints;
@property (nonatomic, readonly) int pointCount;
@property (nonatomic, readonly) int pathPointCount;
@property (nonatomic) int penWeight;
@property (atomic) int* selectionHitCounts;

- (void)addPoint:(CGPoint)p;
- (void)addPathPoint:(CGPoint)p;
- (void)addLineTo:(CGPoint)to;
- (void)finishLine;
- (void)applyTransform:(CGAffineTransform)transform;
- (CGRect)boundingRect;
- (BOOL)eraseAtPoint:(CGPoint)p;
- (BOOL)hitsPoint:(CGPoint)p;
- (void)setMutablePoints:(NSMutableData*)newPoints;
- (void)doneMutatingPoints;
@end
