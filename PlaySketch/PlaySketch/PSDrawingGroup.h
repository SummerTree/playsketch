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
#import "PSPrimitiveDataStructs.h"

#define POSITION_FPS 4.0

@class PSDrawingGroup, PSDrawingLine, PSRecordingSession;

@interface PSDrawingGroup : NSManagedObject
{
	// These are transient properties which are not stored in the model
	// and are used for maintaining the animation state as we playback:
	SRTPosition currentSRTPosition;
	SRTRate currentSRTRate;
	int currentPositionIndex;
	GLKMatrix4 currentModelViewMatrix;
	BOOL _pausedTranslation;
	BOOL _pausedScale;
	BOOL _pausedRotation;
}
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSArray *children;
@property (nonatomic, retain) NSArray *drawingLines;
@property (nonatomic, retain) NSData *positionsAsData;
@property (nonatomic, retain) PSDrawingGroup *parent;
@property (atomic) BOOL isSelected;
@property () SRTPosition currentCachedPosition;

// new attributes for physical system
@property (atomic) BOOL simulationOn;
@property (atomic) BOOL collisionOn;
@property (nonatomic, retain) NSNumber *material;

@end


@interface PSDrawingGroup (CoreDataGeneratedAccessors)

- (SRTPosition*)positions;
- (int)positionCount;
- (void)setPosition:(SRTPosition)p atIndex:(int)i;
- (void)doneMutatingPositions;
- (void)pauseUpdatesOfTranslation:(BOOL)translation rotation:(BOOL)rotation scale:(BOOL)scale;
- (void)unpauseAll;
- (CGPoint)currentOriginInWorldCoordinates;
- (CGRect)currentBoundingRect;
- (GLKMatrix4)currentModelViewMatrix;
- (BOOL)hitsPoint:(CGPoint)p;
- (CGPoint)translatePointFromParentCoordinates:(CGPoint)p;
- (void)getStateAtTime:(float)time
			  position:(SRTPosition*)pPosition
				  rate:(SRTRate*)pRate
		   helperIndex:(int*)pIndex;
- (void)applyToAllSubTrees:( void ( ^ )( PSDrawingGroup *, BOOL) )functionToApply;
- (void)applyToSelectedSubTrees:( void ( ^ )( PSDrawingGroup* g ) )functionToApply;
- (void)applyTransformToLines:(CGAffineTransform)transform;
- (void)applyTransformToPath:(CGAffineTransform)transform;
- (void)centerOnCurrentBoundingBox;
- (int)addPosition:(SRTPosition)position withInterpolation:(BOOL)shouldInterpolate;
- (void)setVisibility:(BOOL)visible atTime:(float)time;
- (BOOL)eraseAtPoint:(CGPoint)p;
- (void)deleteSelectedChildren;
- (PSDrawingGroup*)mergeSelectedChildrenIntoNewGroup;
- (PSDrawingGroup*)topLevelSelectedChild;
- (void)breakUpGroupAndMergeIntoParent;
- (void)transformSelectionByX:(float)dX
						 andY:(float)dY
					 rotation:(float)dRotation
						scale:(float)dScale
				   visibility:(BOOL)makeVisible
					   atTime:(float)time
			   addingKeyframe:(SRTKeyframeType)keyframeType
		   usingInterpolation:(BOOL)interpolate;
- (PSRecordingSession*)startSelectedGroupsRecordingTranslation:(BOOL)isTranslating
													  rotation:(BOOL)isRotating
													   scaling:(BOOL)isScaling
														atTime:(float)time;

@end
