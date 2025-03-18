//
//  BezierView.m
//  Azoth
//
//  Created by Simon Gornall on 3/17/25.
//

#import "BezierView.h"
#import "Cursors.h"

#define STEP 100

typedef enum
	{
	Pt_None			= 0,
	Pt_Point0,
	Pt_Control0,
	Pt_Control1,
	Pt_Point1
	} PointState;

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface BezierView()

// IBOutlets from the ZIB
@property(strong) IBOutlet AZTableView *							table;
@property(strong) IBOutlet AZSlider *								innerSize;
@property(strong) IBOutlet AZSlider *								outerSize;

// The points we have made, and which state we're in
@property(assign, nonatomic) NSPoint								p0;
@property(assign, nonatomic) NSPoint								c0;
@property(assign, nonatomic) NSPoint								c1;
@property(assign, nonatomic) NSPoint								p1;
@property(assign, nonatomic) PointState								state;

// The system cursor
@property(assign, nonatomic) SDL_Cursor *							arrow;

// The current Bezier path
@property(strong, nonatomic) AZBezierPath *							current;

// The Bezier curves to draw
@property(strong, nonatomic) NSMutableArray<AZBezierPath *> *		paths;

// Colours for drawing, saves re-creating
@property(strong, nonatomic) AZColour *								fg;
@property(strong, nonatomic) AZColour *								pt;
@property(strong, nonatomic) AZColour *								ctrl;
@end


@implementation BezierView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (void) awakeFromNib
	{
	self.backgroundColour 	= [AZColour colourNamed:@"olivedrab"];
	self.isOpaque		  	= YES;
	_paths					= NSMutableArray.new;
	self.state 				= Pt_None;
	_arrow 					= SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_DEFAULT);
	[self _updateCursor];

	_fg						= AZColour.black;
	_pt 					= AZColour.yellow;
	_ctrl					= AZColour.red;
	}

/*****************************************************************************\
|* Draw the view
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[super drawInRect:dirtyRect withPainter:painter];

	int W 			= self.bounds.size.width;
	int H 			= self.bounds.size.height;
	AZColour *line 	= [AZColour colourNamed:@"cadetblue3"];

	for (int i=0; i<W; i+= STEP)
		[painter lineAtX:i y:0 toX:i y:H colour:line];
	for (int i=0; i<H; i+= STEP)
		[painter lineAtX:0 y:i toX:W y:i colour:line];

	for (AZBezierPath *path in _paths)
		[self draw:path withPainter:painter];
	if (_current)
		[self draw:_current withPainter:painter];

	}

/*****************************************************************************\
|* Draw a bezier curve with handles
\*****************************************************************************/
- (void) draw:(AZBezierPath *)path withPainter:(AZPainter *)painter
	{
	NSRect r = NSMakeRect(path.p0.x - 5, path.p0.y - 5, 10, 10);
	[painter rectangleWithRect:r colour:_pt];

	r = NSMakeRect(path.p1.x - 5, path.p1.y - 5, 10, 10);
	[painter rectangleWithRect:r colour:_pt];

	r = NSMakeRect(path.c0.x - 5, path.c0.y - 5, 10, 10);
	[painter rectangleWithRect:r colour:_ctrl];
	[painter lineAtX:path.c0.x y:path.c0.y toX:path.p0.x y:path.p0.y];

	r = NSMakeRect(path.c1.x - 5, path.c1.y - 5, 10, 10);
	[painter rectangleWithRect:r colour:_ctrl];
	[painter lineAtX:path.c1.x y:path.c1.y toX:path.p1.x y:path.p1.y];

	[painter bezier:path steps:20 colour:_fg fill:NO];
	}

/*****************************************************************************\
|* Get mouse input
\*****************************************************************************/
- (BOOL) mouseDown:(AZEvent *)e
	{
	NSPoint p = [self convertPoint:e.locationInWindow fromView:nil];

	switch (_state)
		{
		case Pt_None:
			_current = nil;
			break;
		case Pt_Point0:
			_p0			= p;
			break;
		case Pt_Control0:
			_p1			= p;
			_current 	= [AZBezierPath pathFrom:_p0 to:_p1];
			break;
		case Pt_Control1:
			_c0			= _p1;
			_p1 		= p;
			_current 	= [AZBezierPath pathFrom:_p0 control:_c0 to:_p1];
			break;
		case Pt_Point1:
			_c1			= _p1;
			_p1 		= p;
			_current 	= [AZBezierPath pathFrom:_p0
										control1:_c0
										control2:_c1
											  to:_p1];
			[_paths addObject:_current];
			_current 	= nil;
			_p0			= p;
			_state		= Pt_Point0;
			break;
		}

	[self _updateCursor];
	[self setNeedsDisplay:YES];
	return YES;
	}


// MARK: Table view

/*****************************************************************************\
|* Give up a view for the table
\*****************************************************************************/
- (AZView *)tableView:(AZTableView *)tv
   viewForTableColumn:(AZTableColumn *)tc
				  row:(NSInteger)row
	{
	return AZView.new;
	}

/*****************************************************************************\
|* Return the number of entries in the table
\*****************************************************************************/
- (NSInteger)numberOfRowsInTableView:(AZTableView *)tableView
	{
	return 0;
	}

// MARK: Private methods


/*****************************************************************************\
|* Update the cursor
\*****************************************************************************/
- (void) _updateCursor
	{
	switch (_state)
		{
		case Pt_None:
			_state = Pt_Point0;
			self.mouseCursor = [Cursors type:Cursor_P0];
			break;
		case Pt_Point0:
			_state 	= Pt_Control0;
			self.mouseCursor = [Cursors type:Cursor_C0];
			break;
		case Pt_Control0:
			_state = Pt_Control1;
			self.mouseCursor = [Cursors type:Cursor_C1];
			break;
		case Pt_Control1:
			_state = Pt_Point1;
			self.mouseCursor = [Cursors type:Cursor_P1];
			break;
		case Pt_Point1:
			_state 	= Pt_None;
			self.mouseCursor = _arrow;
			break;
		}
	SDL_SetCursor(self.mouseCursor);
	}



@end
