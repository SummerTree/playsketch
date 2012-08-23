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
#import <QuartzCore/QuartzCore.h>


@interface PSSceneViewController ()
@property(nonatomic)BOOL isSelecting; // If we are selecting instead of drawing
@property(nonatomic)BOOL isReadyToRecord; // If manipulations should be treated as recording
@property(nonatomic)BOOL isRecording;
@property(nonatomic,retain) PSSelectionHelper* selectionHelper;
@property(nonatomic,retain) PSDrawingGroup* selectedGroup;
@property(nonatomic) UInt64 currentColor; // the drawing color as an int
@property(nonatomic,retain) NSMutableSet* manipulators;
@property(nonatomic,retain) UIButton* highlightedButton;
- (PSSRTManipulator*)createManipulatorForGroup:(PSDrawingGroup*)group;
- (void)removeManipulatorForGroup:(PSDrawingGroup*)group;
- (PSSRTManipulator*)manipulatorForGroup:(PSDrawingGroup*)group;
- (void)refreshManipulatorLocations;
- (void)highlightButton:(UIButton*)b;
@end



@implementation PSSceneViewController
@synthesize renderingController = _renderingController;
@synthesize drawingTouchView = _drawingTouchView;
@synthesize createCharacterButton = _createCharacterButton;
@synthesize playButton = _playButton;
@synthesize initialColorButton = _initialColorButton;
@synthesize timelineSlider = _timelineSlider;
@synthesize selectionOverlayButtons = _selectionOverlayButtons;
@synthesize motionPathView = _motionPathView;
@synthesize currentDocument = _currentDocument;
@synthesize rootGroup = _rootGroup;
@synthesize isSelecting = _isSelecting;
@synthesize isReadyToRecord = _isReadyToRecord;
@synthesize isRecording = _isRecording;
@synthesize selectionHelper = _selectionHelper;
@synthesize selectedGroup = _selectedGroup;
@synthesize currentColor = _currentColor;
@synthesize manipulators = _manipulators;
@synthesize highlightedButton = _highlightedButton;




/*
 ----------------------------------------------------------------------------
 UIViewController subclass methods
 These are part of the lifecycle of a viewcontroller and give us the 
 opportunity to do some logic each time we are loaded or unloaded for example
 ----------------------------------------------------------------------------
 */


- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Add the renderingview to our viewcontroller hierarchy
	[self addChildViewController:self.renderingController];
	[self.renderingController viewDidLoad];
	
	// Start off in drawing mode
	self.isSelecting = NO;
	self.isReadyToRecord = NO;
	self.isRecording = NO;
	
	// Initialize to be drawing with an initial color
	[self setColor:self.initialColorButton];

	self.createCharacterButton.enabled = NO;
	[self.selectionOverlayButtons hide:NO];
	
	// initialize our objects to the right time
	[self.renderingController jumpToTime:self.timelineSlider.value];
	
	// Create manipulator views for our root group's children
	self.manipulators = [NSMutableSet set];
	for (PSDrawingGroup* child in self.rootGroup.children)
		[self createManipulatorForGroup:child];
	
	// Create motion paths to illustrate our objects
	for (PSDrawingGroup* child in self.rootGroup.children)
		[self.motionPathView addLineForGroup:child];

}


- (void)viewDidUnload
{
    [super viewDidUnload];
	
	//TODO: zero out our references
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


-(void) viewWillDisappear:(BOOL)animated
{
	// Save a preview image of our drawing before going away!
	// First we snapshot the contents of our rendering view,
	// Then we convert that to a format that will fit in our data store
	// TODO: the last line of this seems to take a while....
	// TODO: downsample?
	// Only do this is if we are the root group for the document
	if (self.currentDocument.rootGroup == self.rootGroup)
	{
		GLKView* view = (GLKView*)self.renderingController.view;
		UIImage* previewImg = [view snapshot];
		UIImage* previewImgSmall = [PSHelpers imageWithImage:previewImg scaledToSize:CGSizeMake(462, 300)];
		self.currentDocument.previewImage = UIImagePNGRepresentation(previewImgSmall);
		[PSDataModel save];
	}
}




/*
 ----------------------------------------------------------------------------
 IBActions for the storyboard
 (methods with a return type of "IBAction" can be triggered by buttons in the 
 storyboard editor
 ----------------------------------------------------------------------------
 */


-(IBAction)dismissSceneView:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)setColor:(id)sender
{
	// Grab the background color of the button that called us and remember it
	UIColor* c = [sender backgroundColor];
	self.currentColor = [PSHelpers colorToInt64:c];
	
	//Stop any selection that is happening
	self.isSelecting = NO;
	self.selectionHelper = nil;
	self.selectedGroup = nil;
	
	[self highlightButton:sender];
}

- (IBAction)startSelecting:(id)sender
{
	self.isSelecting = YES;
	[self highlightButton:sender];
}


- (IBAction)createCharacterWithCurrentSelection:(id)sender
{
	[PSHelpers assert:(self.selectedGroup != nil) withMessage:@"need a selection to make character"];
	
	// Keep the selection group by not flattening it when it is unselected
	self.selectedGroup.explicitCharacter = [NSNumber numberWithBool:YES];
	[PSDataModel save];
	
	[self.selectionOverlayButtons configureForGroup:self.selectedGroup];
	[[self manipulatorForGroup:self.selectedGroup] setApperanceIsSelected:YES
															  isCharacter:YES
															  isRecording:NO];
}


- (IBAction)playPressed:(id)sender
{
	[self setPlaying:!self.timelineSlider.playing];
}


- (IBAction)timelineScrubbed:(id)sender
{
	self.timelineSlider.playing = NO;
	[self.renderingController jumpToTime:self.timelineSlider.value];
	[self refreshManipulatorLocations];
	for (PSSRTManipulator* m in self.manipulators)
		m.hidden = NO;
	self.motionPathView.hidden = NO;
}


- (IBAction)toggleRecording:(id)sender
{
	self.isReadyToRecord = ! self.isReadyToRecord;
}


- (IBAction)showDetailsForSelection:(id)sender
{
	// Create and push a new view
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SketchInterface" bundle:nil];
	PSSceneViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"SceneViewController"];
	vc.currentDocument = self.currentDocument;
	vc.rootGroup = self.selectedGroup;
	[vc setModalPresentationStyle:UIModalPresentationFullScreen];
	[self presentModalViewController:vc animated:YES];
	
	// TODO: Prepare some way to get out of it?

}


- (IBAction)exportAsVideo:(id)sender
{
	//Push a new View Controller
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SketchInterface" bundle:nil];
	PSVideoExportControllerViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"VideoExportViewController"];
	vc.renderingController = self.renderingController;
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

- (void)setPlaying:(BOOL)playing
{
	if(!playing && self.timelineSlider.playing)
	{
		// PAUSE
		[self.renderingController stopPlaying];
		self.timelineSlider.playing = NO;
		[self refreshManipulatorLocations];
		for (PSSRTManipulator* m in self.manipulators)
			m.hidden = NO;
		self.motionPathView.hidden = NO;
	}
	else if(playing && !self.timelineSlider.playing)
	{
		// PLAY!
		if (! self.isRecording) self.selectedGroup = nil;
		float time = self.timelineSlider.value;
		[self.renderingController playFromTime:time];
		self.timelineSlider.value = time;
		self.timelineSlider.playing = YES;
		for (PSSRTManipulator* m in self.manipulators)
			if ( ! (self.isRecording && m.group == self.selectedGroup) )
				m.hidden = YES;
		if(!self.isRecording)
			self.motionPathView.hidden = YES;
	}
}


/*
 ----------------------------------------------------------------------------
 Private functions
 (they are private because they are declared at the top of this file instead of
 in the .h file)
 ----------------------------------------------------------------------------
 */


- (PSSRTManipulator*)createManipulatorForGroup:(PSDrawingGroup*)group
{
	CGPoint groupCenter = CGPointMake(group.currentCachedPosition.location.x,
									  group.currentCachedPosition.location.y);

	// Create the manipulator & set its location
	PSSRTManipulator* man = [[PSSRTManipulator alloc] initAtLocation:groupCenter];
	[self.renderingController.view insertSubview:man belowSubview:self.selectionOverlayButtons];
	man.delegate = self;
	man.group = group;

	[man setApperanceIsSelected:(group == self.selectedGroup)
					   isCharacter:[group.explicitCharacter boolValue]
					   isRecording:NO];

	[self.manipulators addObject:man];
	
	return man;
}

- (void)removeManipulatorForGroup:(PSDrawingGroup*)group
{
	PSSRTManipulator* groupMan = [self manipulatorForGroup:group];
	[PSHelpers assert:(groupMan != nil) withMessage:@"removeManipulator for group without one!"];
	[groupMan removeFromSuperview];
	[self.manipulators removeObject:groupMan];
}

- (PSSRTManipulator*)manipulatorForGroup:(PSDrawingGroup*)group
{
	for (PSSRTManipulator* m in self.manipulators)
		if ( m.group == group )
			return m;
	return nil;
}


- (void)refreshManipulatorLocations
{
	for (PSSRTManipulator* m in self.manipulators)
		m.center = 	CGPointMake(m.group.currentCachedPosition.location.x,
								m.group.currentCachedPosition.location.y);

	
	if(self.selectedGroup)
	{
		CGPoint newPoint = [[self manipulatorForGroup:self.selectedGroup] upperRightPoint];
		[self.selectionOverlayButtons setLocation: newPoint];
	}
}


- (void)highlightButton:(UIButton*)b
{
	if(self.highlightedButton)
	{
		self.highlightedButton.layer.shadowRadius = 0.0;
		self.highlightedButton.layer.shadowOpacity = 0.0;
	}
	
	if (b)
	{
		b.layer.shadowRadius = 10.0;
		b.layer.shadowColor = [UIColor whiteColor].CGColor;
		b.layer.shadowOffset = CGSizeMake(0,0);
		b.layer.shadowOpacity = 1.0;
	}
	
	self.highlightedButton = b;
}


/*
 ----------------------------------------------------------------------------
 Property Setters
 @synthesize generates a default pair of get/set methods
 You can override any of them here to customize behavior
 These are also called if you use dot-notaion: foo.currentDocument
 ----------------------------------------------------------------------------
 */


-(void)setCurrentDocument:(PSDrawingDocument *)currentDocument
{
	_currentDocument = currentDocument;
	//Also tell the rendering controller about the document to render it
	self.renderingController.currentDocument = currentDocument;
}

-(void)setRootGroup:(PSDrawingGroup *)rootGroup
{
	_rootGroup = rootGroup;
	//Also tell the rendering controller about the group to render it
	self.renderingController.rootGroup = rootGroup;
}


-(void)setSelectionHelper:(PSSelectionHelper *)selectionHelper
{
	_selectionHelper = selectionHelper;
	//Also tell the rendering controller about the selection helper so it can draw the loupe and highlight objects
	self.renderingController.selectionHelper = selectionHelper;
}


- (void)setSelectedGroup:(PSDrawingGroup *)selectedGroup
{
	if (selectedGroup == _selectedGroup)
		return;
	
	// De select the current one
	if (_selectedGroup)
	{
		PSSRTManipulator* oldManipulator = [self manipulatorForGroup:_selectedGroup];
		[oldManipulator setApperanceIsSelected:NO
								   isCharacter:[_selectedGroup.explicitCharacter boolValue]
								   isRecording:NO];

		// Merge it back into the parent if it hasn't been explicitly made a character
		if([_selectedGroup.explicitCharacter boolValue] == NO)
		{
			[self removeManipulatorForGroup:_selectedGroup];
			[self.motionPathView removeLineForGroup:_selectedGroup];
			[PSDataModel mergeGroup:_selectedGroup intoParentAtTime:self.timelineSlider.value];
		}
	}
	
	_selectedGroup = selectedGroup;
	self.renderingController.selectedGroup = selectedGroup;
	
	// Start the new one being selected
	if ( selectedGroup )
	{
		PSSRTManipulator* newManipulator = [self manipulatorForGroup:selectedGroup];
		[newManipulator setApperanceIsSelected:YES
								   isCharacter:[selectedGroup.explicitCharacter boolValue]
								   isRecording:NO];
		
		[self.selectionOverlayButtons configureForGroup:selectedGroup];
		[self.selectionOverlayButtons setLocation: [newManipulator upperRightPoint]];
		[self.selectionOverlayButtons show:YES];
	}
	else
	{
		[self.selectionOverlayButtons hide:YES];
	}
	
	// Reset any recording we are doing
	self.isReadyToRecord = NO;

}

- (void)setIsReadyToRecord:(BOOL)isReadyToRecord
{
	if(_isReadyToRecord && !isReadyToRecord)
	{
		//Stop Recording
		[self.selectionOverlayButtons stopRecordingMode];
		[[self manipulatorForGroup:self.selectedGroup] setApperanceIsSelected:YES
																  isCharacter:YES
																  isRecording:NO];
	}
	
	if(!_isReadyToRecord && isReadyToRecord)
	{
		//Start Recording
		[self.selectionOverlayButtons startRecordingMode];
		[[self manipulatorForGroup:self.selectedGroup] setApperanceIsSelected:YES
																  isCharacter:YES
																  isRecording:YES];
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
-(PSDrawingLine*)newLineToDrawTo:(id)drawingView
{
	//Clear out any old selection state
	if(self.selectionHelper)
	{
		self.selectionHelper = nil;
		self.createCharacterButton.enabled = NO;
	}
	
	self.selectedGroup = nil;

	
	if (! self.isSelecting )
	{
		PSDrawingLine* line = [PSDataModel newLineInGroup:self.rootGroup];
		line.color = [NSNumber numberWithUnsignedLongLong:self.currentColor];
		return line;
	}
	else
	{
		// Create a line to draw
		PSDrawingLine* selectionLine = [PSDataModel newLineInGroup:nil];
		selectionLine.color = [NSNumber numberWithUnsignedLongLong:[PSHelpers colorToInt64:[UIColor redColor]]];
		
		// Start a new selection set helper
		self.selectionHelper = [[PSSelectionHelper alloc] initWithGroup:self.rootGroup
																	 andLine:selectionLine];		
		return selectionLine;
	}
		
}


-(void)addedToLine:(PSDrawingLine*)line fromPoint:(CGPoint)from toPoint:(CGPoint)to inDrawingView:(id)drawingView
{
	
	if ( line == self.selectionHelper.selectionLoupeLine )
	{
		// Give this new line segment to the selection helper to update the selected set
		
		// We want to add this line to the selectionHelper on a background
		// thread so it won't block the redrawing as much as possible
		// That requires us to bundle up the points as objects instead of structs
		// so they'll fit in a dictionary to pass to the performSelectorInBackground method
		NSDictionary* pointsDict = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSValue valueWithCGPoint:from], @"from",
									[NSValue valueWithCGPoint:to], @"to", nil];
		[self.selectionHelper performSelectorInBackground:@selector(addLineFromDict:) withObject:pointsDict];
	}
}


-(void)finishedDrawingLine:(PSDrawingLine*)line inDrawingView:(id)drawingView
{
	if ( line == self.selectionHelper.selectionLoupeLine )
	{
		//Clean up selection state
		[PSDataModel deleteDrawingLine:self.selectionHelper.selectionLoupeLine];
		self.selectionHelper.selectionLoupeLine = nil;
		
		//Show the manipulator if it was worthwhile
		if(self.selectionHelper.selectedLines.count > 0)
		{
			self.createCharacterButton.enabled = YES;
			
			// create a new group for the lines
			PSDrawingGroup* newGroup = [PSDataModel newChildOfGroup:self.rootGroup
												   withLines:self.selectionHelper.selectedLines];
			
			[newGroup jumpToTime:self.timelineSlider.value];
			
			// create a new manipulator for the new group
			PSSRTManipulator* newMan = [self createManipulatorForGroup:newGroup];
			[newMan setApperanceIsSelected:YES
							   isCharacter:NO
							   isRecording:NO];

			
			self.selectedGroup = newGroup;
			
			// get rid of the selection helper so our lines are highlighted anymore
			self.selectionHelper = nil;
			
		}
	}
	else
	{
		[PSDataModel save];
	}
}


-(void)cancelledDrawingLine:(PSDrawingLine*)line inDrawingView:(id)drawingView
{
	//TODO: similar to finishedDrawing
	[PSHelpers NYIWithmessage:@"scene controller view: cancelledDrawingLine"];
}


/*
 ----------------------------------------------------------------------------
 PSSRTManipulatoDelegate methods
 Called by our manipulator(s) when they are manipulated
 ----------------------------------------------------------------------------
 */

-(void)manipulatorDidStartInteraction:(id)sender
						willTranslate:(BOOL)isTranslating
						   willRotate:(BOOL)isRotating
							willScale:(BOOL)isScaling
{
	
	PSSRTManipulator* manipulator = sender;
	self.selectedGroup = manipulator.group;
	[manipulator setApperanceIsSelected:YES
							isCharacter:[self.selectedGroup.explicitCharacter boolValue]
							isRecording:self.isReadyToRecord];
	
	if(self.isReadyToRecord)
	{
		self.isRecording = YES;
		
		//Remember this location and clear everything after it
		SRTPosition currentPos = [manipulator.group currentCachedPosition];
		currentPos.timeStamp = self.timelineSlider.value;
		currentPos.keyframeType = SRTKeyframeMake(isScaling, isRotating, isTranslating);
		[manipulator.group addPosition:currentPos withInterpolation:NO];

		// Start playing the timeline
		[self setPlaying:YES];
		
		// Pause the group
		[manipulator.group pauseUpdatesOfTranslation:isTranslating
											rotation:(isRotating||isTranslating)
											   scale:(isScaling||isTranslating)];
		
		[manipulator.group flattenTranslation:isTranslating
								   rotation:(isRotating||isTranslating)
									  scale:(isScaling||isTranslating)
								  betweenTime:self.timelineSlider.value
									  andTime:1e99];

		self.selectionOverlayButtons.recordPulsing = YES;
	}
	
	
	// We would like to keep the motion paths updating in realtime while we
	// record, but that's too expensive until we optimize the path updating
	// So instead we just hide
	self.motionPathView.hidden = YES;
	
}

-(void)manipulator:(id)sender
   didTranslateByX:(float)dX
			andY:(float)dY
		  rotation:(float)dRotation
			 scale:(float)dScale
	 isTranslating:(BOOL)isTranslating
		isRotating:(BOOL)isRotating
		 isScaling:(BOOL)isScaling
	  timeDuration:(float)duration
{
	PSSRTManipulator* manipulator = sender;
	
	// Clear out the frames we are overwriting if this is a recording!
	if( self.isRecording)
		[manipulator.group flattenTranslation:isTranslating
								   rotation:isRotating || isTranslating
									  scale:isScaling || isTranslating
								  betweenTime:self.timelineSlider.value - duration
									  andTime:self.timelineSlider.value];

	// Get the group's position
	SRTPosition position = [manipulator.group currentCachedPosition];

	// Update it with these changes
	position.location.x += dX;
	position.location.y += dY;
	position.rotation += dRotation;
	position.scale *= dScale;
	
	//Store the position at the current time
	position.timeStamp = self.timelineSlider.value;
	position.keyframeType = self.isRecording ? SRTKeyframeTypeNone() :
												SRTKeyframeMake(isScaling, isRotating, isTranslating);
	[manipulator.group addPosition:position withInterpolation:!self.isRecording];
	
	[manipulator.group setCurrentCachedPosition:position];
	
	//Keep our buttons properly aligned
	[self.selectionOverlayButtons setLocation:[manipulator upperRightPoint]];
	
}

-(void)manipulatorDidStopInteraction:(id)sender
					  wasTranslating:(BOOL)isTranslating
						 wasRotating:(BOOL)isRotating
						  wasScaling:(BOOL)isScaling
						withDuration:(float)duration
{
	PSSRTManipulator* manipulator = sender;
	
	if(self.isRecording)
	{
		self.isRecording = NO;
		
		// Before we add our last keyframe, snap the timeline so our keyframe
		// will be easy to scrub to later
		[self snapTimeline:nil];
		
		// Erase all the data after this point
		[manipulator.group flattenTranslation:isTranslating
									 rotation:isRotating || isTranslating
										scale:isScaling || isTranslating
								  betweenTime:self.timelineSlider.value - duration
									  andTime:1e100];
		
		// Put a marker at this location and stop playing
		SRTPosition currentPos = [manipulator.group currentCachedPosition];
		currentPos.timeStamp = self.timelineSlider.value;
		NSLog(@"stopping at time: %lf", self.timelineSlider.value);
		currentPos.keyframeType = SRTKeyframeMake(isScaling, isRotating, isTranslating);
		[manipulator.group addPosition:currentPos withInterpolation:NO];

		self.selectionOverlayButtons.recordPulsing = NO;
		
		// Unpause the group
		[manipulator.group unpauseAll];

		// Stop playing
		[self setPlaying:NO];

	}
	
	// We would rather be doing this real-time instead of at the end of the interaction
	[self.motionPathView addLineForGroup:manipulator.group];
	self.motionPathView.hidden = NO;
}

@end
