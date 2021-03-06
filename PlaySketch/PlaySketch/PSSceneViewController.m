/*
 
 --------------
 Copyright 2012 Singapore Management University
 
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 --------------
 
 */

#import "PSSceneViewController.h"
#import "PSDataModel.h"
#import "PSAnimationRenderingController.h"
#import "PSDrawingEventsView.h"
#import "PSSelectionHelper.h"
#import "PSSRTManipulator.h"
#import "PSHelpers.h"
#import "PSTimelineSlider.h"
#import "PSGroupOverlayButtons.h"
#import "PSVideoExportControllerViewController.h"
#import "PSMotionPathView.h"
#import "PSRecordingSession.h"
#import "PSKeyframeView.h"
#import "PSGraphicConstants.h"
#include "PSContactListener.h"
#include "DCELMesh.h"
#include "Triangle.h"
#import <QuartzCore/QuartzCore.h>

/* Private properties and function */
@interface PSSceneViewController ()
@property(nonatomic)BOOL isSelecting; // If we are selecting instead of drawing
@property(nonatomic)BOOL isErasing;
@property(nonatomic)BOOL isReadyToRecord; // If manipulations should be treated as recording
@property(nonatomic)BOOL isRecording;
@property(nonatomic,retain) UIPopoverController* penPopoverController;
@property(nonatomic,retain) UIPopoverController* physicsGlobalPopoverController;
@property(nonatomic,retain) UIPopoverController* physicsStatePopoverController;
@property(nonatomic,retain) PSPenColorViewController* penController;
@property(nonatomic,retain) PSPhysicsGlobalViewController* physicsGlobalController;
@property(nonatomic,retain) PSPhysicsStateViewController* physicsStateController;
@property(nonatomic) UInt64 currentColor; // the drawing color as an int
@property(nonatomic) int penWeight;
@property(nonatomic) int gravity;
@property(nonatomic) int wind;
@property(nonatomic) int box2dBodyCount;
@property(nonatomic,retain) PSRecordingSession* recordingSession;
@property(nonatomic)BOOL insideEraseGroup;
- (void)refreshInterfaceAfterDataChange:(BOOL)dataMayHaveChanged selectionChange:(BOOL)selectionMayHaveChanged;
- (void)highlightButton:(UIButton*)b on:(BOOL)highlight;
@end



@implementation PSSceneViewController


/*
 ----------------------------------------------------------------------------
 Standard View Controller Lifecycle Methods
 (read the documentation for UIViewController to see when they are triggered)
 ----------------------------------------------------------------------------
 */

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Add the renderingview to our viewcontroller hierarchy
	[self addChildViewController:self.renderingController];
	[self.renderingController viewDidLoad];
	
	// Start off in drawing mode
	self.isReadyToRecord = NO;
	self.isRecording = NO;
	self.insideEraseGroup = NO;
	[self startDrawing:nil];

	
	// Create the manipulator
	self.manipulator = [[PSSRTManipulator alloc] initAtLocation:CGPointZero];
	[self.renderingController.view addSubview:self.manipulator];
	self.manipulator.delegate = self;
	self.manipulator.groupButtons = self.selectionOverlayButtons;
	
	// Initialize to be drawing with an initial color
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SketchInterface" bundle:nil];
	self.penController = [storyboard instantiateViewControllerWithIdentifier:@"PenController"];
	self.penController.delegate = self;
	self.penPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.penController];
	[self.penController setToDefaults];
    
    // Initialize physics globals
	self.physicsGlobalController = [storyboard instantiateViewControllerWithIdentifier:@"PhysicsGlobalController"];
    self.physicsGlobalController.delegate = self;
    self.physicsGlobalPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.physicsGlobalController];
    [self.physicsGlobalController setToDefaults];
    
    // Initialize physics state
    self.physicsStateController = [storyboard instantiateViewControllerWithIdentifier:@"PhysicsStateController"];
    self.physicsStateController.delegate = self;
    self.physicsStatePopoverController = [[UIPopoverController alloc] initWithContentViewController:self.physicsStateController];
    [self.physicsStateController setToDefaults];
	
	// initialize our objects to the right time
	[self.renderingController jumpToTime:self.timelineSlider.value];
    
    // initialize Box2D world
    [self initializeBox2dWorld];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];

	// Zero out the non-IB references we are keeping
	self.currentDocument = nil;
	self.rootGroup = nil;
	self.penPopoverController = nil;
    self.physicsGlobalPopoverController = nil;
    self.physicsStateController = nil;
	self.penController = nil;
	self.recordingSession = nil;
    
    delete self.world;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void) viewWillAppear:(BOOL)animated
{
	// Don't let us undo past this point
	[PSDataModel clearUndoStack];
	
	self.keyframeView.rootGroup = self.rootGroup;
	
	self.timelineSlider.maximumValue = [self.currentDocument.duration floatValue];
	[self.keyframeView refreshAll];
	
	self.motionPathView.rootGroup = self.rootGroup;
	
	[self refreshInterfaceAfterDataChange:YES selectionChange:YES];
}


- (void) viewWillDisappear:(BOOL)animated
{
	// Save a preview image of our drawing before going away!
	// First we snapshot the contents of our rendering view,
	// Then we convert that to a format that will fit in our data store
	// TODO: the last line of this seems to take a while: downsample before snapshot?
	[PSSelectionHelper resetSelection];
	GLKView* view = (GLKView*)self.renderingController.view;
	UIImage* previewImg = [view snapshot];
	UIImage* previewImgSmall = [PSHelpers imageWithImage:previewImg scaledToSize:CGSizeMake(462, 300)];
	self.currentDocument.previewImage = UIImagePNGRepresentation(previewImgSmall);
	[PSDataModel save];

	// Don't let us undo past this point
	[PSDataModel clearUndoStack];
}


/*
 ----------------------------------------------------------------------------
 IBActions for the storyboard
 (methods with a return type of "IBAction" can be triggered by buttons in the 
 storyboard editor
 ----------------------------------------------------------------------------
 */

- (IBAction)dismissSceneView:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}


- (IBAction)playPressed:(id)sender
{
	[self setPlaying:!self.timelineSlider.playing];
}


- (IBAction)timelineScrubbed:(id)sender
{
	self.timelineSlider.playing = NO;
	[self.renderingController jumpToTime:self.timelineSlider.value];
	[self refreshInterfaceAfterDataChange:NO selectionChange:NO];
}


- (IBAction)toggleRecording:(id)sender
{
	self.isReadyToRecord = ! self.isReadyToRecord;
}


- (IBAction)exportAsVideo:(id)sender
{
	//Push a new View Controller
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SketchInterface" bundle:nil];
	PSVideoExportControllerViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"VideoExportViewController"];
	vc.renderingController = self.renderingController;
	vc.document = self.currentDocument;
	[vc setModalPresentationStyle:UIModalPresentationFormSheet];
	[self presentModalViewController:vc animated:YES];

}


- (IBAction)snapTimeline:(id)sender
{
	// Round it to the nearest frame and update the UI
	float beforeSnapping = self.timelineSlider.value;
	float afterSnapping = roundf(beforeSnapping * POSITION_FPS) / (float)POSITION_FPS;
	if(afterSnapping != beforeSnapping)
	{
		[self.timelineSlider setValue:afterSnapping animated:YES];
		[self timelineScrubbed:nil];
	}
}


- (IBAction)showPenPopover:(id)sender
{
	[self.penPopoverController presentPopoverFromRect:[sender frame]
											   inView:self.view
							 permittedArrowDirections:UIPopoverArrowDirectionUp
											 animated:YES];
	
}


- (IBAction)startSelecting:(id)sender
{
	[self highlightButton:self.startSelectingButton on:YES];
	[self highlightButton:self.startDrawingButton on:NO];
	[self highlightButton:self.startErasingButton on:NO];
	self.isSelecting = YES;
	self.isErasing = NO;
}


- (IBAction)startDrawing:(id)sender
{
	[self highlightButton:self.startSelectingButton on:NO];
	[self highlightButton:self.startDrawingButton on:YES];
	[self highlightButton:self.startErasingButton on:NO];
	self.isSelecting = NO;
	self.isErasing = NO;
}


- (IBAction)startErasing:(id)sender
{
	[self highlightButton:self.startSelectingButton on:NO];
	[self highlightButton:self.startDrawingButton on:NO];
	[self highlightButton:self.startErasingButton on:YES];
	self.isSelecting = NO;
	self.isErasing = YES;
}


- (IBAction)deleteCurrentSelection:(id)sender
{
	[self.rootGroup deleteSelectedChildren];
	[PSSelectionHelper resetSelection];
	[self refreshInterfaceAfterDataChange:YES selectionChange:YES];
}


- (IBAction)createGroupFromCurrentSelection:(id)sender
{
	[PSHelpers assert:([PSSelectionHelper selectedGroupCount] > 1)
		  withMessage:@"Need more than one existing group to create a new one"];
	
	PSDrawingGroup* newGroup = [self.rootGroup mergeSelectedChildrenIntoNewGroup];
	
	// Insert new keyframe
	SRTPosition newPosition = SRTPositionZero();
	newPosition.timeStamp = self.timelineSlider.value;
	[newGroup addPosition:newPosition withInterpolation:NO];
	
	[newGroup centerOnCurrentBoundingBox];
	[newGroup jumpToTime:self.timelineSlider.value];
	
	
	//Manually update our selection
	[PSSelectionHelper manuallySetSelectedGroup:newGroup];
	
	[self refreshInterfaceAfterDataChange:YES selectionChange:YES];
}


- (IBAction)ungroupFromCurrentSelection:(id)sender
{
	PSDrawingGroup* topLevelGroup = [self.rootGroup topLevelSelectedChild];
	[PSHelpers assert:(topLevelGroup!=nil) withMessage:@"Need a non-nil child"];
	[PSHelpers assert:(topLevelGroup!=self.rootGroup) withMessage:@"Selected child can't be the root"];
	[topLevelGroup breakUpGroupAndMergeIntoParent];
	[PSSelectionHelper resetSelection];
	[self refreshInterfaceAfterDataChange:YES selectionChange:YES];
}


- (IBAction)markCurrentSelectionVisible:(id)sender
{
	[self.rootGroup applyToSelectedSubTrees:^(PSDrawingGroup *g) {
		[g setVisibility:YES atTime:self.timelineSlider.value];
	}];
	
	[self refreshInterfaceAfterDataChange:YES selectionChange:YES];
}


- (IBAction)markCurrentSelectionNotVisible:(id)sender
{
	[self.rootGroup applyToSelectedSubTrees:^(PSDrawingGroup *g) {
		[g setVisibility:NO atTime:self.timelineSlider.value];
	}];

	[self refreshInterfaceAfterDataChange:YES selectionChange:YES];
}


- (IBAction)undo:(id)sender
{
	[PSDataModel undo];
	[self.rootGroup jumpToTime:self.timelineSlider.value];
	[PSSelectionHelper resetSelection];
	[self refreshInterfaceAfterDataChange:YES selectionChange:YES];
}


- (IBAction)redo:(id)sender
{
	[PSDataModel redo];
	[self.rootGroup jumpToTime:self.timelineSlider.value];
	[PSSelectionHelper resetSelection];
	[self refreshInterfaceAfterDataChange:YES selectionChange:YES];
}

// physical system
- (IBAction)showPhysicsStatePopover:(id)sender
{
    NSLog(@"Physics: ");
    
    NSLog([self.rootGroup topLevelSelectedChild].isSimulate ? @"SIM" : @"NO SIM");
    NSLog([self.rootGroup topLevelSelectedChild].isSolid ? @"solid" : @"no solid");
    
    // update physics state on buttons
    [self.physicsStateController setIsSimulate:[self.rootGroup topLevelSelectedChild].isSimulate];
    [self.physicsStateController setIsSolid:[self.rootGroup topLevelSelectedChild].isSolid];
    [self.physicsStateController setIsStatic:[self.rootGroup topLevelSelectedChild].isStatic];
    [self.physicsStateController setMat:[self.rootGroup topLevelSelectedChild].material.intValue];
    [self.physicsStateController refreshButtons];
    
    CGRect rect = CGRectMake(10, 10, 10, 10);
    PSDrawingGroup* group = [self.rootGroup topLevelSelectedChild];
    CGPoint pnt = [group currentOriginInWorldCoordinates];
    NSLog(@"%f,  %f", pnt.x, pnt.y);
    rect.origin.x = pnt.x + 480; rect.origin.y = pnt.y + 470;
    
    [self.physicsStatePopoverController presentPopoverFromRect:rect
                                                         inView:self.view
                                       permittedArrowDirections:UIPopoverArrowDirectionUp                                                      animated:YES];
}

- (IBAction)showPhysicsGlobalPopover:(id)sender
{
    NSLog(@"physicsGlobal");
	[self.physicsGlobalPopoverController presentPopoverFromRect:[sender frame]
											   inView:self.view
							 permittedArrowDirections:UIPopoverArrowDirectionUp
											 animated:YES];
	
}



/*
 ----------------------------------------------------------------------------
 Private functions
 (they are private because they are declared at the top of this file instead of
 in the .h file)
 ----------------------------------------------------------------------------
 */

- (void)refreshInterfaceAfterDataChange:(BOOL)dataMayHaveChanged selectionChange:(BOOL)selectionMayHaveChanged
{
	//Refresh the undo/redo buttons
	self.undoButton.enabled = [PSDataModel canUndo];
	self.redoButton.enabled = [PSDataModel canRedo];

	// Hide/show the manipulator
	BOOL shouldShow =	[PSSelectionHelper selectedGroupCount] > 0 &&
						(!self.timelineSlider.playing || self.isRecording );
	self.manipulator.hidden = !shouldShow;
	

	// Update the manipulator's location
	if(shouldShow && [PSSelectionHelper selectedGroupCount] == 1)
	{
		PSDrawingGroup* group = [self.rootGroup topLevelSelectedChild];
		self.manipulator.center = [group currentOriginInWorldCoordinates];
	}
	else if(shouldShow)
	{
		self.manipulator.center = CGPointZero;
	}
	
	// Update the buttons attached to the manipulator
	BOOL currentlyVisible = ![PSSelectionHelper isSingleLeafOnlySelected] ||
							 [PSSelectionHelper leafGroup].currentCachedPosition.isVisible;
	[self.selectionOverlayButtons configureForSelectionCount:[PSSelectionHelper selectedGroupCount]
												isLeafObject:[PSSelectionHelper isSingleLeafOnlySelected]
												   isVisible:currentlyVisible];
	
	if(dataMayHaveChanged)
		[self.keyframeView refreshAll];
	
	// Motion paths
	self.motionPathView.hidden = self.timelineSlider.playing;
	if(selectionMayHaveChanged)
		[self.motionPathView refreshSelected];
}

- (void)highlightButton:(UIButton*)b on:(BOOL)highlight
{
	if(highlight)
	{
		b.layer.shadowRadius = 10.0;
		b.layer.shadowColor = HIGHLIGHTED_BUTTON_UICOLOR.CGColor;
		b.layer.shadowOffset = CGSizeMake(0,0);
		b.layer.shadowOpacity = 1.0;
	}
	else
	{
		b.layer.shadowRadius = 0.0;
		b.layer.shadowOpacity = 0.0;
	}
}

- (void)initializeBox2dWorld
{
    b2AABB worldAABB;
    worldAABB.lowerBound.Set(-500.0f, -500.0f);
    worldAABB.upperBound.Set(500.0f, 500.0f);
    self.world = new b2World( worldAABB, b2Vec2(0,10*self.gravity), true );
}

/*
 ----------------------------------------------------------------------------
 Property Setters
 @property generates a default pair of get/set methods
 You can override any of them here to customize behavior
 These are also called if you use dot-notaion: foo.currentDocument
 The real instance variable is called _currentDocument, by default.
 ----------------------------------------------------------------------------
 */



- (void)setPlaying:(BOOL)playing
{
	if(!playing && self.timelineSlider.playing)
	{
		// PAUSE
		[self.renderingController stopPlaying];
		self.timelineSlider.playing = NO;
	}
	else if(playing && !self.timelineSlider.playing)
	{
		// PLAY!
		float time = self.timelineSlider.value;
		[self.renderingController playFromTime:time];
		self.timelineSlider.value = time;
		self.timelineSlider.playing = YES;
	}
	
	[self refreshInterfaceAfterDataChange:NO selectionChange:NO];
}


- (void)setCurrentDocument:(PSDrawingDocument *)currentDocument
{
	_currentDocument = currentDocument;
	//Also tell the rendering controller about the document to render it
	self.renderingController.currentDocument = currentDocument;
}


- (void)setRootGroup:(PSDrawingGroup *)rootGroup
{
	_rootGroup = rootGroup;
	[PSSelectionHelper setRootGroup:rootGroup];
}


- (void)setIsReadyToRecord:(BOOL)isReadyToRecord
{
	if(_isReadyToRecord && !isReadyToRecord)
	{
		//Stop Recording
		[self.selectionOverlayButtons stopRecordingMode];
	}
	
	if(!_isReadyToRecord && isReadyToRecord)
	{
		//Start Recording
		[self.selectionOverlayButtons startRecordingMode];
	}
	
	_isReadyToRecord = isReadyToRecord;
}


/*
 ----------------------------------------------------------------------------
 PSDrawingEventsViewDrawingDelegate methods
 (Called by our drawing view when it needs to do something with touch events)
 ----------------------------------------------------------------------------
 */


/*	
 Provide a PSDrawingLine based on whether we are selecting or drawing
 */
- (PSDrawingLine*)newLineToDrawTo:(id)drawingView
{
	// If the manipulator is visible, clear the current selection and don't start a line
	if(!self.manipulator.hidden)
	{
		// Clear any current selection
		[PSSelectionHelper resetSelection];
		[self refreshInterfaceAfterDataChange:NO selectionChange:YES];
		return nil;
	}
	
	// No line necessary if we are erasing
	if (self.isErasing) return nil;
	
	// Create a new TEMPORARY line with the current color and weight
	// Read the comments on newTemporaryLineWithWeight:andColor: for an explanation
	// of why this line has to be "temporary"
	int weight = self.isSelecting ? SELECTION_PEN_WEIGHT : self.penWeight;
	UInt64 color = self.isSelecting ? [PSHelpers colorToInt64:argsToUIColor(SELECTION_COLOR)] : self.currentColor;
	PSDrawingLine* newLine = [PSDataModel newTemporaryLineWithWeight:weight andColor:color];
	
	// Start a new selection set helper to keep track of what's being selected
	if (self.isSelecting) [PSSelectionHelper resetSelection];
		
	// Tell the rendering controller to draw this line specially, since it isn't added to the scene yet
	self.renderingController.currentLine = newLine;

	return newLine;
}


- (void)addedToLine:(PSDrawingLine*)line fromPoint:(CGPoint)from toPoint:(CGPoint)to inDrawingView:(id)drawingView
{
	if (self.isSelecting)
	{
		// Give this new line segment to the selection helper to update the selected set
		
		// We want to add this line to the selectionHelper on a background
		// thread so it won't block the redrawing as much as possible
		// That requires us to bundle up the points as objects instead of structs
		// so they'll fit in a dictionary to pass to the performSelectorInBackground method
		// This is ugly-looking, but the arguments need to be on the heap instead of the stack
		NSDictionary* pointsDict = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSValue valueWithCGPoint:from], @"from",
									[NSValue valueWithCGPoint:to], @"to", nil];
		[PSSelectionHelper performSelectorInBackground:@selector(addSelectionLineFromDict:)
											withObject:pointsDict];
	}
}


- (void)finishedDrawingLine:(PSDrawingLine*)line inDrawingView:(id)drawingView
{
	if (self.isErasing && self.insideEraseGroup)
	{
		// If we are erasing, finish off the undo group so it will all be undone togther
		[self.rootGroup applyToAllSubTrees:^(PSDrawingGroup* g, BOOL s) {
			for (PSDrawingLine* l in g.drawingLines)
				[l doneMutatingPoints];
		}];
		[PSDataModel save];
		[PSDataModel endUndoGroup];
		self.insideEraseGroup = NO;
	}
	else if ( line && self.isSelecting )
	{
		[PSSelectionHelper finishLassoSelection];
	}
	else if( line && !self.isSelecting)
	{
		// Create a new group for it
		PSDrawingGroup* newLineGroup = [PSDataModel newDrawingGroupWithParent:self.rootGroup];
		
		[PSDataModel makeTemporaryLinePermanent:line];
		line.group = newLineGroup;
		
		// Add a keyframe at time 0 to set the object as invisible:
		SRTPosition newPosition1 = SRTPositionZero();
		newPosition1.timeStamp = 0.0;
		newPosition1.isVisible = NO;
		newPosition1.keyframeType = SRTKeyframeMake(NO, NO, NO, NO);
		[newLineGroup addPosition:newPosition1 withInterpolation:NO];
		
		// Then add the real visible keyframe at the current time
		SRTPosition newPosition2 = SRTPositionZero();
		newPosition2.timeStamp = self.timelineSlider.value;
		newPosition2.isVisible = YES;
		newPosition2.keyframeType = SRTKeyframeMake(YES,YES,YES,YES);
		[newLineGroup addPosition:newPosition2 withInterpolation:NO];

		// Center it
		[line.group centerOnCurrentBoundingBox];
		[line.group jumpToTime:self.timelineSlider.value];

		// Save it
		[PSDataModel save];
	
	}
	
	self.renderingController.currentLine = nil;
    [self refreshInterfaceAfterDataChange:YES selectionChange:NO];
}


- (void)cancelledDrawingLine:(PSDrawingLine*)line inDrawingView:(id)drawingView
{
	self.renderingController.currentLine = nil;
	[PSSelectionHelper resetSelection];
}

- (void)movedAt:(CGPoint)p inDrawingView:(id)drawingView
{
	// We only care about this when we are erasing.
	// For drawing and selecting, we let the drawingView build a line
	if(self.isErasing)
	{
		if(!self.insideEraseGroup)
		{
			[PSDataModel beginUndoGroup];
			self.insideEraseGroup = YES;
		}

		[self.rootGroup eraseAtPoint:p];
	}
}


- (void)whileDrawingLine:(PSDrawingLine *)line tappedAt:(CGPoint)p tapCount:(int)tapCount inDrawingView:(id)drawingView
{
	if (self.isErasing ) return; // No need for any selection while erasing

	// Look to see if we tapped on an object!
	BOOL touchedObject = [PSSelectionHelper findSelectionForTap:p];

	// If we didn't hit anything, just treat it like a normal line that finished
	// Otherwise our selectionHelper will have the info about our selection
	if (!(tapCount == 1 && touchedObject))
	{
		[self finishedDrawingLine:line inDrawingView:drawingView];
	}
	
	self.renderingController.currentLine = nil;
	[self refreshInterfaceAfterDataChange:YES selectionChange:YES];
}

/*
 ----------------------------------------------------------------------------
 PSSRTManipulatoDelegate methods
 Called by our manipulator(s) when they are manipulated
 ----------------------------------------------------------------------------
 */

- (void)manipulatorDidStartInteraction:(id)sender
						willTranslate:(BOOL)isTranslating
						   willRotate:(BOOL)isRotating
							willScale:(BOOL)isScaling
{
	if(self.isReadyToRecord)
	{
		self.isRecording = YES;
	
		self.recordingSession = [self.rootGroup startSelectedGroupsRecordingTranslation:isTranslating
																			   rotation:isRotating
																				scaling:isScaling
																				 atTime:self.timelineSlider.value];
		// Start playing the timeline
		[self setPlaying:YES];
		self.selectionOverlayButtons.recordPulsing = YES;
	}
}

- (void)manipulator:(id)sender
   didTranslateByX:(float)dX
			andY:(float)dY
		  rotation:(float)dRotation
			 scale:(float)dScale
	 isTranslating:(BOOL)isTranslating
		isRotating:(BOOL)isRotating
		 isScaling:(BOOL)isScaling
	  timeDuration:(float)duration
{

	// Check if we need to expand the timeline
	if([self.timelineSlider nearEndOfTimeline:self.timelineSlider.value])
	{
		[self.timelineSlider expandTimeline];
		[self.keyframeView refreshAll];
		
		// TODO: We are just setting the duration to the size of the canvas
		// if we wanted to do this right, we'd probably set it to the time of the last keyframe
		// in any group, but then we would have to do that more often
		self.currentDocument.duration = [NSNumber numberWithFloat:self.timelineSlider.maximumValue];
	}
	
	
	if (self.isRecording)
	{
        NSLog(@"%f,,,%d", self.timelineSlider.value, self.gravity);
		[self.recordingSession transformAllGroupsByX:dX
												andY:dY// + 0.5f * self.timelineSlider.value * self.timelineSlider.value * self.gravity
											rotation:dRotation
											   scale:dScale
											  atTime:self.timelineSlider.value];
	}
	else
	{

		SRTKeyframeType keyframeType =  self.isRecording ?
											SRTKeyframeTypeNone() :
											SRTKeyframeMake(isScaling, isRotating, isTranslating, NO);

		[self.rootGroup transformSelectionByX:dX
										 andY:dY
									 rotation:dRotation
										scale:dScale
								   visibility:YES
									   atTime:self.timelineSlider.value
							   addingKeyframe:keyframeType
						   usingInterpolation:YES];
	}
}

- (void)manipulatorDidStopInteraction:(id)sender
					  wasTranslating:(BOOL)isTranslating
						 wasRotating:(BOOL)isRotating
						  wasScaling:(BOOL)isScaling
						withDuration:(float)duration
{
	
	if(self.isRecording)
	{
		self.isRecording = NO;

		// Before we add our last keyframe, snap the timeline so our keyframe
		// will be easy to scrub to later
		[self snapTimeline:nil];


		[self.recordingSession finishAtTime:self.timelineSlider.value];
		
		// Stop playing
		[self setPlaying:NO];
		self.selectionOverlayButtons.recordPulsing = NO;
	}
	
	[self.rootGroup applyToSelectedSubTrees:^(PSDrawingGroup *g) {[g doneMutatingPositions];}];
	[PSDataModel save];
	
	[self refreshInterfaceAfterDataChange:YES selectionChange:YES];
}


/*
 ----------------------------------------------------------------------------
 PSPenColorChangeDelegate methods
 Called by when our pen colours change
 ----------------------------------------------------------------------------
 */
- (void)penColorChanged:(UIColor*)newColor
{
	self.currentColor = [PSHelpers colorToInt64:newColor];
	self.startDrawingButton.backgroundColor = newColor;
	[self startDrawing:nil];
	if(self.penPopoverController && self.penPopoverController.popoverVisible)
		[self.penPopoverController dismissPopoverAnimated:YES];
}

- (void)penWeightChanged:(int)newWeight
{
    //NSLog(@"%d", newWeight);
	self.penWeight = newWeight;
	[self startDrawing:nil];
	if(self.penPopoverController && self.penPopoverController.popoverVisible)
		[self.penPopoverController dismissPopoverAnimated:YES];
}

/*
 ----------------------------------------------------------------------------
 PSPhysicsGlobalViewController methods
 Called by when our pen colours change
 ----------------------------------------------------------------------------
 */
- (void)gravityChanged:(int)gravity
{
    NSLog(@"Gravity: %d", gravity);
    self.gravity = gravity;
    
    [self refreshSimulation];
    [PSDataModel save];
	[self refreshInterfaceAfterDataChange:YES selectionChange:YES];
}

- (void)windChanged:(int)wind
{
    NSLog(@"Wind: %d", wind);
	self.wind = wind;
    
    [self refreshSimulation];
    [PSDataModel save];
	[self refreshInterfaceAfterDataChange:YES selectionChange:YES];
}

/*
 ----------------------------------------------------------------------------
 PSPhysicsStateViewController methods
 Called by when our pen colours change
 ----------------------------------------------------------------------------
 */
- (void)simulateStateChanged:(BOOL)isSimulate
{
    NSLog(isSimulate ? @"Sim" : @"No Sim");
    
    [self.rootGroup applyToAllSubTrees:^(PSDrawingGroup *g, BOOL s) {
		[g setIsSimulate:isSimulate];

	}];
    
    [self refreshSimulation];
    [PSDataModel save];
	[self refreshInterfaceAfterDataChange:YES selectionChange:YES];
}

- (NSMutableArray*)generateOutline:(DCELVertex*)startingPoint
{
    NSMutableArray* boundaryVertices = [[NSMutableArray alloc] initWithCapacity:0];
    DCELVertex* c = startingPoint;
    DCELVertex* p = new DCELVertex();
    DCELVertex* n = new DCELVertex();
    
    p->coords.x = c->coords.x;
    p->coords.y = c->coords.y - 10;
    
    int ix = 0;
    while (true) {
        ix++;
        DCELHalfEdge* leaving = c->leaving;
        n = leaving->tail;
        float angle = 0.0f;
        [boundaryVertices addObject:[NSValue valueWithCGPoint:CGPointMake(c->coords.x, c->coords.y)]];
        //printf("New boundary vertex P: X %f, Y %f \n", p->coords.x, p->coords.y);
        //printf("New boundary vertex C: X %f, Y %f \n", c->coords.x, c->coords.y);
        //printf("New boundary vertex N: X %f, Y %f \n", n->coords.x, n->coords.y);
        
        while (leaving->globalNext != NULL) {
            if (n == p) {
                //printf("\tP is N\n");
                n = leaving->globalNext->tail;
                leaving = leaving->globalNext;
                //printf("    Leaving Coords N: X %f, Y %f \n", n->coords.x, n->coords.y);
                continue;
            }
            
            angle = [self GetRotateAngle:(p->coords.x - c->coords.x)
                                      y1:(p->coords.y - c->coords.y)
                                      x2:(n->coords.x - c->coords.x)
                                      y2:(n->coords.y - c->coords.y)];
            
            if (angle < 0.00001) {
                //printf("\ttoo small angle between c-p and c-n\n");
                n = leaving->globalNext->tail;
                leaving = leaving->globalNext;
                //printf("    Leaving Coords N: X %f, Y %f \n", n->coords.x, n->coords.y);
                continue;
            }
            
            //printf("    Leaving Coords N: X %f, Y %f \n", n->coords.x, n->coords.y);
            leaving = leaving->globalNext;
            DCELVertex* tempNext = leaving->tail;
            //printf("    Temp(next) Leaving Coords: X %f, Y %f \n", tempNext->coords.x, tempNext->coords.y);
            
            if (tempNext == p) {
                //printf("    back to P (tempNext == p)\n");
                continue;
            }
            
            if (tempNext == n) {
                //printf("\ttempNext == n");
                continue;
            }
            
            float tempAngle = [self GetRotateAngle:(p->coords.x - c->coords.x)
                                                y1:(p->coords.y - c->coords.y)
                                                x2:(tempNext->coords.x - c->coords.x)
                                                y2:(tempNext->coords.y - c->coords.y)];
            
            //printf("    Angles: origin %f, temp %f \n", angle, tempAngle);
            if (tempAngle < 0.000001)
                continue;
            
            if (tempAngle < angle) {
                angle = tempAngle;
                n = tempNext;
                //printf("    Update N\n");
            }
        }
        
        p = c;
        c = n;
        
        if (n == startingPoint)
            break;
    }
    
    //NSArray* cCWVertexList = [[boundaryVertices reverseObjectEnumerator] allObjects];
    //boundaryVertices = [NSMutableArray arrayWithArray:cCWVertexList];
    
    return boundaryVertices;
}

- (void)addBox2dBody:(PSDrawingGroup*) g
{
    [g resetSimulationPositions];
    
    if (g.isSolid) {
        // update body index for later reference
        self.box2dBodyCount++;
        [g setBox2dBodyIndex:self.box2dBodyCount];
        
        // create body in Box2D
        b2BodyDef bodyDef;
        bodyDef.position.Set(g.positions[0].location.x, g.positions[0].location.y);
        b2Body *body = self.world->CreateBody(&bodyDef);
        
        b2PolygonDef shapeDef;
        
        //shapeDef.SetAsBox([g currentBoundingRect].size.width*0.5f, [g currentBoundingRect].size.height*0.5f);
        
        // apply the algorithm with DCEL to get poly outline
        NSMutableArray* bp = [g currentBoundingPoly];
        DCELMesh* mesh = new DCELMesh();
        int width = [g penWeight];
        
        printf("\nPATH points count==: %d, penWeight: %d\n", bp.count, width);
        
        // test on self-defined shape with vertices number > 8
        NSMutableArray* testVertices = [[NSMutableArray alloc] initWithCapacity:0];
        {
            [testVertices addObject:[NSValue valueWithCGPoint: CGPointMake(-30, -20)]];
            [testVertices addObject:[NSValue valueWithCGPoint: CGPointMake(0, -30)]];
            [testVertices addObject:[NSValue valueWithCGPoint: CGPointMake(30, -20)]];
            [testVertices addObject:[NSValue valueWithCGPoint: CGPointMake(30, 20)]];
            [testVertices addObject:[NSValue valueWithCGPoint: CGPointMake(10, 30)]];
            [testVertices addObject:[NSValue valueWithCGPoint: CGPointMake(-10, 30)]];
            [testVertices addObject:[NSValue valueWithCGPoint: CGPointMake(-20, 28)]];
            [testVertices addObject:[NSValue valueWithCGPoint: CGPointMake(-25, 20)]];
            [testVertices addObject:[NSValue valueWithCGPoint: CGPointMake(-30, 5)]];
        }
        
        testVertices = [self IterativeSimplify:testVertices targetLowNumOfV:5 targetHighNumOfV:8 ErrThresholdL:1 ErrThresholdH:15 increment:2];
        
        shapeDef.vertexCount = testVertices.count;
        for (int i = 0; i < testVertices.count; i++) {
            NSValue* val = [testVertices objectAtIndex:i];
            CGPoint p = [val CGPointValue];
            shapeDef.vertices[i].Set(p.x, p.y);
            printf("Vertex id: %d, Coordinates: X: %f, Y: %f \n", i, p.x, p.y);
        }
        
        // construct DCEL data
        for (int i = 0; i < bp.count ; i++) {
            NSValue* val = [bp objectAtIndex:i];
            CGPoint p1 = [val CGPointValue];
            
            // draw the path points
            UIView * dot = [[UIView alloc] initWithFrame:CGRectMake(p1.x+509, p1.y+371, 5, 5)];
            dot.backgroundColor = [UIColor redColor];
            dot.alpha = 0.4;
            [self.view addSubview:dot];
            
            if (i == 0) // when it is the starting point
            {
                CGPoint p2 = [[bp objectAtIndex:i+1] CGPointValue];
                DCELVertex* vLeft = new DCELVertex();
                DCELVertex* vRight = new DCELVertex();
                
                // calculate vRight and vLeft
                CGSize normal = CGSizeMake(p2.y - p1.y, - (p2.x - p1.x));
                double lengthNor = hypot(normal.width, normal.height);
                CGSize normalNext = CGSizeMake(normal.width / lengthNor * width,
                                               normal.height / lengthNor * width);
                
                vLeft->coords = *new Vector(p1.x + normalNext.width, p1.y + normalNext.height);
                vRight->coords = *new Vector(p1.x - normalNext.width, p1.y - normalNext.height);
                
                // calculate v
                float length = sqrtf((p2.x-p1.x)*(p2.x-p1.x) + (p2.y-p1.y)*(p2.y-p1.y));
                DCELVertex* v = new DCELVertex();
                v->coords = *new Vector(p1.x+width/length*(p1.x-p2.x), p1.y+width/length*(p1.y-p2.y));
                
                mesh->insert(v);
                mesh->insert(vLeft);
                mesh->insert(vRight);
                
                // add edges to vertices
                v->AddLeavingEdge(vLeft);
                v->AddLeavingEdge(vRight);
                vLeft->AddLeavingEdge(v);
                vRight->AddLeavingEdge(v);
            }
            else if (i == (bp.count - 1))  // when it is the ending point
            {
                CGPoint pPre = [[bp objectAtIndex:i-1] CGPointValue];
                DCELVertex* v = new DCELVertex();
                DCELVertex* vLeft = new DCELVertex();
                DCELVertex* vRight = new DCELVertex();
                DCELVertex* preVLeft = mesh->vertexList->globalNext;
                DCELVertex* preVRight = mesh->vertexList;
                
                // calculate v
                float length = sqrtf((pPre.x-p1.x)*(pPre.x-p1.x) + (pPre.y-p1.y)*(pPre.y-p1.y));
                v->coords = *new Vector(p1.x+width/length*(p1.x-pPre.x), p1.y+width/length*(p1.y-pPre.y));
                
                // calculate vRight and vLeft
                CGSize normal = CGSizeMake(p1.y - pPre.y, - (p1.x - pPre.x));
                double lengthNor = hypot(normal.width, normal.height);
                CGSize normalNext = CGSizeMake(normal.width / lengthNor * width,
                                               normal.height / lengthNor * width);
                
                vLeft->coords = *new Vector(p1.x + normalNext.width, p1.y + normalNext.height);
                vRight->coords = *new Vector(p1.x - normalNext.width, p1.y - normalNext.height);
                
                // add vertices
                mesh->insert(vLeft);
                mesh->insert(v);
                mesh->insert(vRight);
                
                // add edges to vertices
                vLeft->AddLeavingEdge(v);
                vRight->AddLeavingEdge(v);
                preVLeft->AddLeavingEdge(vLeft);
                preVRight->AddLeavingEdge(vRight);
                v->AddLeavingEdge(vLeft);
                v->AddLeavingEdge(vRight);
                vLeft->AddLeavingEdge(preVLeft);
                vRight->AddLeavingEdge(preVRight);
            }
            else
            {
                CGPoint pPre = [[bp objectAtIndex:i-1] CGPointValue];
                DCELVertex* vLeft = new DCELVertex();
                DCELVertex* vRight = new DCELVertex();
                DCELVertex* preVLeft = mesh->vertexList->globalNext;
                DCELVertex* preVRight = mesh->vertexList;
                
                //Calculate the normal
                CGSize normal = CGSizeMake(p1.y - pPre.y, - (p1.x - pPre.x));
                double length = hypot(normal.width, normal.height);
                //if (length < 1) return;
                CGSize normalNext = CGSizeMake(normal.width / length * width,
                                               normal.height / length * width);
                
                vLeft->coords = *new Vector(p1.x + normalNext.width, p1.y + normalNext.height);
                vRight->coords = *new Vector(p1.x - normalNext.width, p1.y - normalNext.height);
                
                // add vertices
                mesh->insert(vLeft);
                mesh->insert(vRight);
                
                // add edges to vertices
                preVLeft->AddLeavingEdge(vLeft);
                preVRight->AddLeavingEdge(vRight);
                vLeft->AddLeavingEdge(preVLeft);
                vRight->AddLeavingEdge(preVRight);
            }
        }
        
        // loop through all the points for lexicographical point
        // & update edges for intersection
        DCELVertex* head = mesh->vertexList;
        DCELVertex* startingPoint = head;
        int iT = 1;
        while (head != NULL) {
            printf("iT:  %d   COORD: X %f, Y %f\n", iT,head->coords.x,head->coords.y);
            
            // go through all the edges and check for intersection
            DCELHalfEdge* leaving = head->leaving;
            while (leaving != NULL) {
                DCELVertex* origin = leaving->origin;
                DCELVertex* tail = leaving->tail;
                printf("    Leaving from X: %f, Y: %f to X: %f, Y: %f\n",
                       origin->coords.x, origin->coords.y, tail->coords.x, tail->coords.y);
                
                mesh->updateEdges(leaving);
                
                leaving = leaving->globalNext;
            }
            
            if (head->coords.x < startingPoint->coords.x
                || ((head->coords.x - startingPoint->coords.x)<0.00000001
                    && head->coords.y < startingPoint->coords.y))
                startingPoint = head;
            
            // draw all the vertices we get
            //                UIView * vDotT = [[UIView alloc] initWithFrame:CGRectMake(head->coords.x+509, head->coords.y+371, 5, 5)];
            //                vDotT.backgroundColor = [UIColor greenColor];
            //                vDotT.alpha = 0.4;
            //                [self.view addSubview:vDotT];
            
            iT++;
            mesh->advance(head);
        }
        
        printf("position of lexicograpically point: x %f, y %f\n", startingPoint->coords.x, startingPoint->coords.y);
        
        // generate outline
        NSMutableArray* boundaryVertices = [self generateOutline:startingPoint];
        
        // draw outline points with green color
        for (int i = 0; i<boundaryVertices.count; i++) {
            CGPoint p = [[boundaryVertices objectAtIndex:i] CGPointValue];
            
            UIView * vDotT = [[UIView alloc] initWithFrame:CGRectMake(p.x+509, p.y+371, 5, 5)];
            vDotT.backgroundColor = [UIColor greenColor];
            vDotT.alpha = 0.3+0.7*i/boundaryVertices.count;
            [self.view addSubview:vDotT];
        }
        
        switch ([g.material integerValue]) {
            case 1:
                // metal
                shapeDef.density = 4.0;
                shapeDef.friction = 0.3;
                shapeDef.restitution = 0.0;
                break;
            case 2:
                // wood
                shapeDef.density = 1.0;
                shapeDef.friction = 0.7;
                shapeDef.restitution = 0.3;
                break;
            case 3:
                // rubber
                shapeDef.density = 1.0;
                shapeDef.friction = 0.4;
                shapeDef.restitution = 1.0;
                break;
                
            default:
                break;
        }
        
        if (!g.isStatic)
            shapeDef.density = 0;
        
        body->CreateShape(&shapeDef);
        body->SetMassFromShapes();
        
        shapeDef.vertexCount = testVertices.count;
        for (int i = 0; i < testVertices.count; i++) {
            NSValue* val = [testVertices objectAtIndex:i];
            CGPoint p = [val CGPointValue];
            
            // drawing for debug
            //                if (debugging) {
            //                    UIView * vDot = [[UIView alloc] initWithFrame:CGRectMake(p.x+body->GetWorldCenter().x+509, p.y+body->GetWorldCenter().y+371, 5, 5)];
            //                    vDot.backgroundColor = [UIColor blackColor];
            //                    vDot.alpha = 0.4;
            //                    [self.view addSubview:vDot];
            //                }
        }
        
        // index will be used to refer simulation results back
        body->SetUserData((void*)g.box2dBodyIndex);
        
    } else {
        [g setBox2dBodyIndex:-1];
    }
    
    printf("index: %d\n", g.box2dBodyIndex);
}

- (void)simulateBox2dWorld:(float)timeStep vIter:(int)vIter pIter:(int)pIter
{
    for (int32 i = 0; i < 300; i++)
    {
        self.world->Step(timeStep, vIter, pIter);
        
        b2Body* b = self.world->GetBodyList();
        
        while (b != NULL) {
            int index = (int)b->GetUserData();
            
            if (self.wind != 0)
                b->ApplyForce(b2Vec2(100000*self.wind, 0), b->GetPosition());
            
            [self.rootGroup applyToAllSubTrees:^(PSDrawingGroup* g, BOOL s) {
                if (index == g.box2dBodyIndex)
                {
                    b2Vec2 pos = b->GetPosition();
                    float32 angle = b->GetAngle();
                    
                    SRTPosition position;
                    position.location.x = pos.x;
                    position.location.y = pos.y;
                    position.scale = 1;
                    position.rotation = angle;
                    position.timeStamp = i*timeStep;
                    position.isVisible = YES;
                    
                    if (i != 299)
                        position.keyframeType = SRTKeyframeTypeNone();
                    else
                        position.keyframeType = SRTKeyframeAdd(YES, YES, YES, YES, YES);
                    
                    [g addPosition:position withInterpolation:NO];
                }
            }];
            
            b = b->GetNext();
        }
    }
}

- (void)refreshSimulation
{
    [self initializeBox2dWorld];
    
    ContactData* _contactData = new ContactData();
    self.world->SetContactListener(&_contactData->cntactListener);
    _contactData->contactPointCount = 0;
    
    self.box2dBodyCount = 0;
    
    // add bodies in Box2D for drawing groups
    [self.rootGroup applyToAllSubTrees:^(PSDrawingGroup* g, BOOL s) {
        [self addBox2dBody:g];
    }];
    
    if (self.box2dBodyCount == 0)
        return;
    
    self.world->SetGravity(b2Vec2(0,10*self.gravity));
    
    // simulate and send back the result: position, angle and etc.
    float timeStep = 1.0f/30.0f;
    int vIter = 6;
    int pIter = 2;
    [self simulateBox2dWorld:timeStep vIter:vIter pIter:pIter];
    
    // release the Box2D world
    delete self.world;
}

- (BOOL)IsEar:(int)i vertices:(NSMutableArray*)v
{
    float dx0,dy0,dx1,dy1;
    dx0=dy0=dx1=dy1=0;
    if (i >= v.count || i < 0 || v.count < 3){
        return false;
    }
    int upper = i+1;
    int lower = i-1;
    if (i == 0){
        CGPoint v0 = [[v objectAtIndex:0] CGPointValue];
        CGPoint vLast = [[v objectAtIndex:v.count - 1] CGPointValue];
        CGPoint v1 = [[v objectAtIndex:1] CGPointValue];
        dx0 = v0.x - vLast.x; dy0 = v0.y - vLast.y;
        dx1 = v1.x - v0.x; dy1 = v1.y - v0.y;
        lower = v.count-1;
    } else if (i == v.count-1){
        CGPoint vi = [[v objectAtIndex:i] CGPointValue];
        CGPoint vi_1 = [[v objectAtIndex:i - 1] CGPointValue];
        CGPoint v0 = [[v objectAtIndex:0] CGPointValue];
        dx0 = vi.x - vi_1.x; dy0 = vi.y - vi_1.y;
        dx1 = v0.x - vi.x; dy1 = v0.y - vi.y;
        upper = 0;
    } else{
        CGPoint vPre = [[v objectAtIndex:i-1] CGPointValue];
        CGPoint vNext = [[v objectAtIndex:i+1] CGPointValue];
        CGPoint vI = [[v objectAtIndex:i] CGPointValue];
        dx0 = vI.x - vPre.x; dy0 = vI.y - vPre.y;
        dx1 = vNext.x - vI.x; dy1 = vNext.y - vI.y;
    }
    
    float cross = dx0*dy1-dx1*dy0;
    if (cross > 0) return false;
    
    CGPoint vI = [[v objectAtIndex:i] CGPointValue];
    CGPoint vUpper = [[v objectAtIndex:upper] CGPointValue];
    CGPoint vLower = [[v objectAtIndex:lower] CGPointValue];
    
    Triangle* myTri = new Triangle(vI.x,vI.y,vUpper.x,vUpper.y,vLower.x,vLower.y);
    for (int j=0; j<v.count; ++j){
        if (j==i || j == lower || j == upper) continue;
        CGPoint vJ = [[v objectAtIndex:j] CGPointValue];
        if (myTri->isInside(vJ.x,vJ.y)) return false;
    }
    return true;
}

- (float)GetRotateAngle:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2
{
    const float epsilon = 1.0e-6;
    const float nyPI = acos(-1.0);
    float dist, dot, degree, angle;
    
    // normalize
    dist = sqrt( x1 * x1 + y1 * y1 );
    x1 /= dist;
    y1 /= dist;
    dist = sqrt( x2 * x2 + y2 * y2 );
    x2 /= dist;
    y2 /= dist;
    // dot product
    dot = x1 * x2 + y1 * y2;
    if ( fabs(dot-1.0) <= epsilon )
        angle = 0.0;
    else if ( fabs(dot+1.0) <= epsilon )
        angle = nyPI;
    else {
        float cross;
        
        angle = acos(dot);
        //cross product
        cross = x1 * y2 - x2 * y1;
        // vector p2 is clockwise from vector p1
        // with respect to the origin (0.0)
        if (cross < 0 ) {
            angle = 2 * nyPI - angle;
        }    
    }
    degree = angle *  180.0 / nyPI;
    return degree;
}

- (NSMutableArray*)IterativeSimplify:(NSMutableArray *)vertices targetLowNumOfV:(int)tl targetHighNumOfV:(int)th ErrThresholdL:(float)etl ErrThresholdH:(float)eth increment:(int)i
{
    NSMutableArray* newVertices = vertices;
    float et = etl;
    
    while (newVertices.count > th || (newVertices.count > tl && et < eth)) {
        newVertices = [self Simplify:newVertices ErrThreshold:et];
        
        if (newVertices.count > tl)
            et += i;
        
        printf("IterativeSimplify=== NUM: %d, et: %f\n", newVertices.count, et);
    }
    
    if (newVertices.count > th) {
        printf("IterativeSimplify exception: need more points for this polygon");
        exit(0);
    }
    
    return newVertices;
}

- (float)DistanceOfTwoPoints:(CGPoint)a Second:(CGPoint)b
{
    return sqrtf((a.x-b.x)*(a.x-b.x) + (a.y-b.y)*(a.y-b.y));
}

- (float)ErrorIfRemoved:(CGPoint)v1 Second:(CGPoint)v2 Third:(CGPoint)v3
{
    float a = [self DistanceOfTwoPoints:v1 Second:v2];
    float b = [self DistanceOfTwoPoints:v2 Second:v3];
    float c = [self DistanceOfTwoPoints:v1 Second:v3];
    
    float l = (a + b + c) / 2;
    float s = sqrtf(l * (l-a) * (l-b) * (l-c));
    
    // this is the distance from v2 to the line v1-v3
    return 2*s/c;
}

- (NSMutableArray*)Simplify:(NSMutableArray *)vertices ErrThreshold:(float)et
{
    NSMutableArray* newVertices = vertices;
    
    for (int i = 1; i < newVertices.count - 1 ; )
    {
        CGPoint p = [[newVertices objectAtIndex:i-1] CGPointValue];
        CGPoint c = [[newVertices objectAtIndex:i] CGPointValue];
        CGPoint n = [[newVertices objectAtIndex:i+1] CGPointValue];
        
        float e = [self ErrorIfRemoved:p Second:c Third:n];
        
        if (e < et) 
            [newVertices removeObjectAtIndex:i];
        else
            i++;
    }
    
    return newVertices;
}

- (void)solidStateChanged:(BOOL)isSolid
{
	NSLog(isSolid ? @"Solid" : @"Not Solid:");
    [self.rootGroup applyToSelectedSubTrees:^(PSDrawingGroup *g) {
		[g setIsSolid:isSolid];
	}];
    
    [self refreshSimulation];
    [PSDataModel save];
	[self refreshInterfaceAfterDataChange:YES selectionChange:YES];
}

- (void)staticStateChanged:(BOOL)isStatic
{
    [self.rootGroup applyToSelectedSubTrees:^(PSDrawingGroup *g) {
		[g setIsStatic:isStatic];
	}];
    
    [self refreshSimulation];
    [PSDataModel save];
	[self refreshInterfaceAfterDataChange:YES selectionChange:YES];
}

- (void)materialChanged:(int)mat
{
    NSLog(@"Material: %d", mat);
    [self.rootGroup applyToSelectedSubTrees:^(PSDrawingGroup *g) {
        [g setMaterial:[NSNumber numberWithInt:mat]];
	}];
    
    [self refreshSimulation];
    [PSDataModel save];
	[self refreshInterfaceAfterDataChange:YES selectionChange:YES];
}


@end

