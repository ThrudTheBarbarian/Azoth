//
//  AZSegmentedControl.m
//  Azoth
//
//  Created by Simon Gornall on 12/20/24.
//

#import <SDL3/SDL.h>

#import "AZApplication.h"
#import "AZColour.h"
#import "AZEvent.h"
#import "AZFont.h"
#import "AZPainter.h"
#import "AZRenderer.h"
#import "AZSegmentedControl.h"
#import "AZWindow.h"

#define SEGMENT_LEADING   		6
#define SEGMENT_TRAILING		6

enum
	{
	STATE_N	= 0,				// Normal
	STATE_H,					// Highlighted
	STATE_D,					// Disabled
	STATE_HD,					// Highlighted and disabled
	STATE_P,					// Pushed
	STATE_HP,					// Highlighted and pushed

	STATE_NUM
	};

static NSRect	_cL[STATE_NUM];	// Left bezel
static NSRect	_cC[STATE_NUM];	// Center bezel
static NSRect	_cR[STATE_NUM];	// Right bezel
static NSRect	_cD[STATE_NUM];	// Divider bezel

typedef struct
	{
	NSString * label;				// The text string
	int width;						// How wide this segment itself is
	AZTextAlignment alignment;		// How to draw the text
	BOOL selected;					// Whether this segment is selected
	NSInteger tag;					// The tag for the segment
	BOOL enabled;					// Whether the segment is enabled
	BOOL pushed;					// Whether it's currently pushed
	} LabelInfo;

@interface AZSegmentedControl()
@property(assign, nonatomic) LabelInfo *						info;
@property(assign, nonatomic) NSInteger 							numLabels;
@end


@implementation AZSegmentedControl
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	[AZSegmentedControl _fetchRects];

	if (self = [super initWithFrame:frame])
		{
		_info 				= NULL;
		_numLabels 			= 0;

		// Insert a dummy segment (which will certainly be overwritten)
		// just so we can set up the selected state coherently
		[self setLabel:@"[x]" forSegment:0];
		_trackingMode			= AZSegmentSwitchTrackingSelectOne;
		_info[0].selected		= YES;

		self.backgroundColour	= AZColour.clearColour;
		}

	return self;
	}

/*****************************************************************************\
|* Convenience initialiser. Note the frame origin is set to 0,0
\*****************************************************************************/
+ (instancetype) segmentedControlWithLabels:(NSArray<NSString *> *) labels
                               trackingMode:(AZSegmentSwitchTracking)mode
                                     target:(id) target
                                     action:(SEL) action
	{
	[AZSegmentedControl _fetchRects];

	float width = (labels.count - 1) * NSWidth(_cD[0])
			    + NSWidth(_cL[0])
			    + NSWidth(_cR[0]);

	for (NSString *label in labels)
		width += [AZSegmentedControl widthForString:label];

	NSRect frame = NSMakeRect(0,0,width, NSHeight(_cC[0]));
	AZSegmentedControl *ctrl = [[AZSegmentedControl alloc] initWithFrame:frame];

	int index = 0;
	for (NSString *label in labels)
		{
		[ctrl setLabel:label forSegment:index];
		index ++;
		}

	ctrl.action = action;
	ctrl.target = target;

	return ctrl;
	}

/*****************************************************************************\
|* Clean up memory allocation
\*****************************************************************************/
- (void) dealloc
	{
	if (_info)
		{
		free(_info);
		_info = NULL;
		}
	}


// MARK: Event handling

/*****************************************************************************\
|* We got a mouse-down, see if we need to re-select
\*****************************************************************************/
- (BOOL) mouseDown:(AZEvent *)e
	{
	if (self.state == AZControlStateDisabled)
		return NO;

	NSPoint p = [self convertPoint:e.locationInWindow fromView:nil];

	NSInteger segment = [self _segmentForPoint:p];
	if (segment >= 0)
		{
		if (segment != [self selectedSegment])
			{
			if (_info[segment].enabled)
				{
				BOOL isSelected = [self isSelectedForSegment:segment];
				[self setSelected:!isSelected forSegment:segment];
				[self setNeedsDisplay:YES];
				[self sendAction:self.action to:self.target];
				}
			}
		}

	return YES;
	}


// MARK: Drawing

/*****************************************************************************\
|* fetch the label for a given segment
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[super drawInRect:dirtyRect withPainter:painter];

	NSRect b 			= self.bounds;
	AZRenderer *azr		= AZRenderer.renderer;
	NSInteger ui		= [AZApp textureFor:kUiMap];
	BOOL allDisabled 	= (self.state == AZControlStateDisabled);

	[azr setBlendMode:SDL_BLENDMODE_ADD];

	if (_numLabels < 1)
		{
		// Map the source rectangles
		NSRect srcL = _cL[allDisabled ? STATE_D : STATE_N];
		NSRect srcC = _cC[allDisabled ? STATE_D : STATE_N];
		NSRect srcR = _cR[allDisabled ? STATE_D : STATE_N];

		// Draw the left bezel
		NSRect dstL = NSMakeRect(0, 0, NSWidth(srcL), NSHeight(srcL));
		[azr blitFrom:ui src:srcL dst:dstL];

		// Draw the center bezel
		int stretch = NSWidth(b) - NSWidth(srcL) - NSWidth(srcR);
		NSRect dstC = NSMakeRect(NSWidth(srcL), 0, stretch, NSHeight(srcL));
		[azr blitFrom:ui src:srcC dst:dstC];

		// Draw the right bezel
		int x		= NSWidth(b) - NSWidth(dstL) - NSWidth(dstC);
		NSRect dstR = NSMakeRect(x, 0, NSWidth(srcR), NSHeight(srcR));
		[azr blitFrom:ui src:srcR dst:dstR];
		}
	else
		{
		// Draw the left bezel
		int idx		= (allDisabled) ? STATE_D
					: (_info[0].selected & (_info[0].enabled == NO)) ? STATE_HD
					: (_info[0].selected) ? STATE_H
					: (_info[0].enabled == NO) ? STATE_D
					: (_info[0].pushed & _info[0].enabled) ? STATE_HP
					: (_info[0].pushed) ? STATE_P
					: STATE_N;

		NSRect srcL = _cL[idx];
		NSRect dstL = NSMakeRect(0, 0, NSWidth(srcL), NSHeight(srcL));
		[azr blitFrom:ui src:srcL dst:dstL];

		// Draw each segment...
		int x = NSWidth(srcL);
		for (NSInteger i=0; i<_numLabels; i++)
			{
			idx		= (allDisabled) ? STATE_D
					: (_info[i].selected & (_info[i].enabled == NO)) ? STATE_HD
					: (_info[i].selected) ? STATE_H
					: (_info[i].enabled == NO) ? STATE_D
					: (_info[i].pushed & _info[i].enabled) ? STATE_HP
					: (_info[i].pushed) ? STATE_P
					: STATE_N;

			NSRect srcC = _cC[idx];
			NSRect dstC = NSMakeRect(x, 0, _info[i].width, NSHeight(srcL));
			[azr tileFrom:ui src:srcC dst:dstC];
			x += _info[i].width;

			int black = (idx == STATE_N) | (idx == STATE_D);

			[painter setTextColour:black ? [AZColour blackColour]
										 : [AZColour whiteColour]];
			[painter setTextAlignment:_info[i].alignment];

			NSRect box = NSInsetRect(dstC, 3, 2);
			[painter drawInBox:box text:_info[i].label];

			// ... and if it's not the last segment, draw a divider too
			if (i < _numLabels-1)
				{
				srcC = _cD[idx];
				dstC = NSMakeRect(x, 0, NSWidth(srcC), NSHeight(srcC));
				[azr blitFrom:ui src:srcC dst:dstC];
				x += NSWidth(srcC);
				}
			}

		// Draw the right bezel
		NSRect srcR = _cR[idx];
		NSRect dstR = NSMakeRect(x, 0, NSWidth(srcR), NSHeight(srcR));
		[azr blitFrom:ui src:srcR dst:dstR];
		}
	}


// MARK: Labels...

/*****************************************************************************\
|* fetch the label for a given segment
\*****************************************************************************/
- (nullable NSString *) labelForSegment:(NSInteger)segment
	{
	if (segment <0 || segment >= _numLabels)
		return nil;
	return _info[segment].label;
	}

/*****************************************************************************\
|* set the label for a given segment
\*****************************************************************************/
- (void) setLabel:(NSString *)label forSegment:(NSInteger)segment
	{
	if (segment >= 0)
		{
		[self _ensureSufficientSegments:segment];
		_info[segment].label = label;
		}
	}

/*****************************************************************************\
|* Sets the alignment of the specified segment
\*****************************************************************************/
- (void) setAlignment:(AZTextAlignment)alignment forSegment:(NSInteger)segment
	{
	if (segment >= 0)
		{
		[self _ensureSufficientSegments:segment];
		_info[segment].alignment = alignment;
		}
	}

/*****************************************************************************\
|* Returns the alignment of the specified segment
\*****************************************************************************/
- (AZTextAlignment) alignmentForSegment:(NSInteger) segment
	{
	if ((segment >= 0) && (segment < _numLabels))
		return _info[segment].alignment;

	SDL_Log("Asked for out-of-bounds segment alignment %ld",(long)segment);
	return -1;
	}

/*****************************************************************************\
|* Returns the segment count
\*****************************************************************************/
- (NSInteger) segmentCount
	{
	return _numLabels;
	}

/*****************************************************************************\
|* Returns the first segment that is selected, or -1
\*****************************************************************************/
- (NSInteger) selectedSegment
	{
	for (NSInteger i=0; i<_numLabels; i++)
		if (_info[i].selected)
			return i;
	return -1;
	}


// MARK: Managing the selected segment

/*****************************************************************************\
|* Returns the index of the selected segment
\*****************************************************************************/
- (NSInteger) indexOfSelectedItem
	{
	return [self selectedSegment];
	}


/*****************************************************************************\
|* Selects the segment with the specified tag
\*****************************************************************************/
- (BOOL) selectSegmentWithTag:(NSInteger) tag
	{
	BOOL found = NO;
	if (_trackingMode == AZSegmentSwitchTrackingSelectOne)
		{
		for (NSInteger i=0; i<_numLabels; i++)
			if (_info[i].tag == tag)
				{
				found = YES;
				_info[i].selected = YES;
				}
			else
				_info[i].selected = NO;
		}
	else if (_trackingMode == AZSegmentSwitchTrackingSelectAny)
		{
		for (NSInteger i=0; i<_numLabels; i++)
			if (_info[i].tag == tag)
				{
				found = YES;
				_info[i].selected = YES;
				}
		}

	return found;
	}

/*****************************************************************************\
|* Sets the selection state of the specified segment
\*****************************************************************************/
- (void) setSelected:(BOOL)yn forSegment:(NSInteger)segment
	{
	if ((segment >= 0) && (segment < _numLabels))
		{
		if (_trackingMode == AZSegmentSwitchTrackingSelectOne)
			{
			for (NSInteger i=0; i<_numLabels; i++)
				_info[i].selected = NO;
			_info[segment].selected = YES;
			}
		else
			{
			_info[segment].selected = YES;
			}
		}
	}

/*****************************************************************************\
|* Returns a Boolean value indicating whether the specified segment is selected
\*****************************************************************************/
- (BOOL) isSelectedForSegment:(NSInteger)segment
	{
	if ((segment >= 0) && (segment < _numLabels))
		return _info[segment].selected;
	return NO;
	}


// MARK: Adjusting the segment spacing


/*****************************************************************************\
|* Sets the width of the specified segment. Adjusts the others
\*****************************************************************************/
- (void) setWidth:(float)width forSegment:(NSInteger) segment;
	{
	if ((segment >= 0) && (segment < _numLabels))
		{
		// Find the total width
		int totalWidth = 0;
		for (NSInteger i=0; i<_numLabels; i++)
			totalWidth += _info[i].width;

		int dw 			= width - _info[segment].width;
		int correction	= ABS(dw);
		int change		= dw > 0 ? 1 : -1;

		while (correction > 0)
			{
			for (NSInteger i=0; i<_numLabels; i++)
				{
				_info[i].width -= change;
				correction --;
				}
			}
		}
	}

/*****************************************************************************\
|* Returns the width of the specified segment
\*****************************************************************************/
- (float) widthForSegment:(NSInteger)segment
	{
	if ((segment >= 0) && (segment < _numLabels))
		return _info[segment].width;
	return -1.f;
	}



// MARK: Enabling and disabling segments

/*****************************************************************************\
|* Sets the enabled state of the specified segment
\*****************************************************************************/
- (void) setEnabled:(BOOL) enabled forSegment:(NSInteger) segment
	{
	if ((segment >= 0) && (segment < _numLabels))
		_info[segment].enabled = enabled;
	}

/*****************************************************************************\
|* Returns a Boolean value indicating whether the specified segment is enabled
\*****************************************************************************/
- (BOOL) isEnabledForSegment:(NSInteger) segment
	{
	if ((segment >= 0) && (segment < _numLabels))
		return _info[segment].enabled;
	return NO;
	}



// MARK: Tags..

/*****************************************************************************\
|* Return the tag of the specified segment
\*****************************************************************************/
- (NSInteger) tagForSegment:(NSInteger) segment
	{
	if ((segment >= 0) && (segment < _numLabels))
		return _info[segment].tag;
	return -1;
	}

/*****************************************************************************\
|* Set a tag on a specified segment
\*****************************************************************************/
- (void) setTag:(NSInteger) tag forSegment:(NSInteger) segment
	{
	if ((segment >= 0) && (segment < _numLabels))
		_info[segment].tag = tag;
	}




// MARK: Private methods

/*****************************************************************************\
|* Return the segment for a given point
\*****************************************************************************/
- (NSInteger) _segmentForPoint:(NSPoint)p
	{
	int x = p.x - NSWidth(_cL[0]);
	for (NSInteger i=0; i<_numLabels; i++)
		{
		if (x < _info[i].width)
			return i;
		x -= _info[i].width;
		}
	return -1;
	}

/*****************************************************************************\
|* Make sure we can store to the segment-id passed in. We need +1 over the
|* value passed...
\*****************************************************************************/
- (void) _ensureSufficientSegments:(NSInteger)segment
	{
	NSInteger num 	= segment + 1;
	int extra		= (int)(num - _numLabels);
	if (extra == 0)
		return;

	if (_numLabels < num)
		{
		LabelInfo *info = calloc(num, sizeof(LabelInfo));
		memcpy((void*)info, (void*)_info, _numLabels * sizeof(LabelInfo));
		if (_info)
			free(_info);
		_info = info;
		}

	int totalWidth = (self.bounds.size.width		// Total width
				   - NSWidth(_cL[0])				// minus left end-cap
				   - NSWidth(_cR[0])				// minus right end-cap
				   - segment * NSWidth(_cD[0]));	// minux divider size
	int width	   = totalWidth / num;

	for (NSInteger i=_numLabels; i<num; i++)
		{
		_info[i].alignment 	= AZTextAlignmentCenter;
		_info[i].label		= @"";
		_info[i].width		= width;
		_info[i].enabled	= YES;
		_info[i].selected 	= NO;
		_info[i].tag 		= i;
		_info[i].pushed		= NO;
		}

	// Fairly subtract the space from the other segments
	int dw = (int)(width * extra / _numLabels);
	for (NSInteger i=0; i<_numLabels; i++)
		_info[i].width -= dw;

	// And finally make it all work by trimming the last one
	int otherW = 0;
	for (NSInteger i=0; i<num-1; i++)
		otherW += _info[i].width;
	_info[num-1].width = (totalWidth - otherW);

	// Update state
	_numLabels = num;
	}

/*****************************************************************************\
|* Fetch the rectangles for the UI backing pixmaps from the atlas
\*****************************************************************************/
+ (void) _fetchRects
	{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,
		^{
		_cL[STATE_N]  	= [AZApp srcRectFor:@"segmented-control-bezel-left" in:kUiMap];
		_cC[STATE_N]  	= [AZApp srcRectFor:@"segmented-control-bezel-center" in:kUiMap];
		_cR[STATE_N]  	= [AZApp srcRectFor:@"segmented-control-bezel-right" in:kUiMap];
		_cD[STATE_N]  	= [AZApp srcRectFor:@"segmented-control-bezel-divider" in:kUiMap];

		_cL[STATE_H]  	= [AZApp srcRectFor:@"segmented-control-bezel-highlighted-left" in:kUiMap];
		_cC[STATE_H]  	= [AZApp srcRectFor:@"segmented-control-bezel-highlighted-center" in:kUiMap];
		_cR[STATE_H]  	= [AZApp srcRectFor:@"segmented-control-bezel-highlighted-right" in:kUiMap];
		_cD[STATE_H]  	= [AZApp srcRectFor:@"segmented-control-bezel-highlighted-divider" in:kUiMap];

		_cL[STATE_D]  	= [AZApp srcRectFor:@"segmented-control-bezel-disabled-left" in:kUiMap];
		_cC[STATE_D]  	= [AZApp srcRectFor:@"segmented-control-bezel-disabled-center" in:kUiMap];
		_cR[STATE_D]  	= [AZApp srcRectFor:@"segmented-control-bezel-disabled-right" in:kUiMap];
		_cD[STATE_D]  	= [AZApp srcRectFor:@"segmented-control-bezel-disabled-divider" in:kUiMap];

		_cL[STATE_HD]  	= [AZApp srcRectFor:@"segmented-control-bezel-highlighted-disabled-left" in:kUiMap];
		_cC[STATE_HD]  	= [AZApp srcRectFor:@"segmented-control-bezel-highlighted-disabled-center" in:kUiMap];
		_cR[STATE_HD]  	= [AZApp srcRectFor:@"segmented-control-bezel-highlighted-disabled-right" in:kUiMap];
		_cD[STATE_HD]  	= [AZApp srcRectFor:@"segmented-control-bezel-highlighted-disabled-divider" in:kUiMap];

		_cL[STATE_P]  	= [AZApp srcRectFor:@"segmented-control-bezel-pushed-left" in:kUiMap];
		_cC[STATE_P]  	= [AZApp srcRectFor:@"segmented-control-bezel-pushed-center" in:kUiMap];
		_cR[STATE_P]  	= [AZApp srcRectFor:@"segmented-control-bezel-pushed-right" in:kUiMap];
		_cD[STATE_P]  	= [AZApp srcRectFor:@"segmented-control-bezel-divider" in:kUiMap];

		_cL[STATE_HP]  	= [AZApp srcRectFor:@"segmented-control-bezel-pushed-highlighted-left" in:kUiMap];
		_cC[STATE_HP]  	= [AZApp srcRectFor:@"segmented-control-bezel-pushed-highlighted-center" in:kUiMap];
		_cR[STATE_HP]  	= [AZApp srcRectFor:@"segmented-control-bezel-pushed-highlighted-right" in:kUiMap];
		_cD[STATE_HP]  	= [AZApp srcRectFor:@"segmented-control-bezel-highlighted-divider" in:kUiMap];
		});
	}

/*****************************************************************************\
|* Figure out the width requirements of an item's string
\*****************************************************************************/
+ (int) widthForString:(NSString *)text
	{
	int width  			= [AZApp.controlFont textWidthFor:text]
						+ SEGMENT_LEADING + SEGMENT_TRAILING;
	return width;
	}


@end
