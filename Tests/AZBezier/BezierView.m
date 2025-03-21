//
//  BezierView.m
//  Azoth
//
//  Created by Simon Gornall on 3/17/25.
//

#import "BezierView.h"
#import "Cursors.h"
#import "PointView.h"

#define STEP 100
#define ROW_HEIGHT  (79.f)

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
@property(assign, nonatomic) PointState								state;

// The system cursor
@property(assign, nonatomic) SDL_Cursor *							arrow;

// The Bezier curves to draw
@property(strong, nonatomic) NSMutableArray<AZBezierPath *> *		paths;
@property(strong, nonatomic) NSMutableArray<AZBezierPath *> *		inner;
@property(strong, nonatomic) NSMutableArray<AZBezierPath *> *		outer;

// Colours for drawing, saves re-creating
@property(strong, nonatomic) AZColour *								fg;
@property(strong, nonatomic) AZColour *								pt;
@property(strong, nonatomic) AZColour *								ctrl;

// The index of the curve we're editing (to show handles)
@property(assign,nonatomic) NSInteger 								edit;

// The handle of the curve we're dragging
@property(assign,nonatomic) PointState 								handle;
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
	_inner					= NSMutableArray.new;
	_outer					= NSMutableArray.new;
	self.state 				= Pt_None;
	_arrow 					= SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_DEFAULT);
	[self _updateCursor];

	_c0						= NSMakePoint(0,0);
	_edit					= -1;

	_fg						= AZColour.black;
	_pt 					= AZColour.yellow;
	_ctrl					= AZColour.red;
	_table.rowHeight		= ROW_HEIGHT;
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

	int idx = 0;
	for (AZBezierPath *path in _paths)
		{
		[self draw:path showHandles:(idx == _edit) withPainter:painter];
		idx ++;
		}

	for (AZBezierPath *path in _inner)
		[self draw:path showHandles:NO withPainter:painter];

	}

/*****************************************************************************\
|* Draw a bezier curve with handles
\*****************************************************************************/
- (void)        draw:(AZBezierPath *)path
		 showHandles:(BOOL) handles
		 withPainter:(AZPainter *)painter
	{
	if (handles)
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
		}
	[painter bezier:path steps:20 colour:_fg fill:NO];
	}


// MARK: Events

/*****************************************************************************\
|* The mouse moved
\*****************************************************************************/
- (BOOL) mouseDragged:(AZEvent *)e
	{
	BOOL redraw 		= NO;
	NSPoint p 			= [self convertPoint:e.locationInWindow fromView:nil];
	if (_edit >= 0)
		{
		AZBezierPath *path 	= _paths[_edit];

		switch (_handle)
			{
			case Pt_None:
				break;
			case Pt_Point0:
				path.p0 = [AZBezierPoint point:p];
				if (_edit > 0)
					{
					_paths[_edit-1].p1 = [AZBezierPoint point:p];
					_paths[_edit-1].c1 = [self _extend:path.c0 through:path.p0];
					}

				redraw  = YES;
				break;
			case Pt_Control0:
				path.c0 = [AZBezierPoint point:p];
				if (_edit > 0)
					_paths[_edit-1].c1 = [self _extend:path.c0 through:path.p0];
				redraw  = YES;
				break;
			case Pt_Control1:
				path.c1 = [AZBezierPoint point:p];
				if (_edit < _paths.count-1)
					_paths[_edit+1].c0 = [self _extend:path.c1 through:path.p1];
				redraw  = YES;
				break;
			case Pt_Point1:
				path.p1 = [AZBezierPoint point:p];
				if (_edit < _paths.count-1)
					{
					_paths[_edit+1].c0 = [self _extend:path.c1 through:path.p1];
					_paths[_edit+1].p0 = [AZBezierPoint point:p];
					}
				redraw  = YES;
				break;
			}

		if (redraw)
			{
			[self _updateOffsetCurves];
			[self setNeedsDisplay:YES];
			}
		}
	return YES;
	}


/*****************************************************************************\
|* Get mouse clicks
\*****************************************************************************/
- (BOOL) mouseDown:(AZEvent *)e
	{
	NSPoint p			= [self convertPoint:e.locationInWindow fromView:nil];
	AZBezierPath *path	= nil;
	PointState handle	= [self _onHandle:p];

	if (handle == Pt_None)
		{
		switch (_state)
			{
			case Pt_None:
				break;
			case Pt_Point0:
				_p0			= p;
				break;

			case Pt_Control0:
				_edit 	= _paths.count;
				path	= [AZBezierPath pathFrom:_p0 to:p];
				[_paths addObject:path];
				[self _updateOffsetCurves];
				[_table reloadData];
				break;
			case Pt_Control1:
				if (FUZZY_ZERO(_c0.x) && FUZZY_ZERO(_c0.y))
					{
					// We're creating our first curve
					path 	= [_paths lastObject];
					path.c0 = path.p1;
					path.p1	= [AZBezierPoint point:p];
					[path reconfigureAsQuadratic];
					}
				else
					{
					_edit 	= _paths.count;
					path	= [AZBezierPath pathFrom:_p0 control:_c0 to:p];
					[_paths addObject:path];
					[_table reloadData];
					}
				[self _updateOffsetCurves];
				break;

			case Pt_Point1:
				path 		= [_paths lastObject];
				path.c1 	= path.p1;
				path.p1		= [AZBezierPoint point:p];
				_p0			= p;
				_c0 		= [self _extend:path.c1 through:path.p1].asPoint;

				_state		= Pt_Control0;
				[self _updateOffsetCurves];
				break;
			}

		[self _updateCursor];
		[self setNeedsDisplay:YES];
		}
	else
		{
		_handle = handle;
		}

	return YES;
	}


/*****************************************************************************\
|* Reflect one point through another to get the next control
\*****************************************************************************/
- (AZBezierPoint *) _extend:(AZBezierPoint *)c1 through:(AZBezierPoint *)p3
	{
	AZBezierPoint *vec = [[p3.copy subtract:c1] add:p3];
	return vec;
	}

/*****************************************************************************\
|* Get mouse release
\*****************************************************************************/
- (BOOL) mouseUp:(AZEvent *)e
	{
	_handle = Pt_None;
	return YES;
	}



// MARK: Actions

/*****************************************************************************\
|* Inner size changed
\*****************************************************************************/
- (IBAction)innerSizeChanged:(id)sender
	{
	[self _updateOffsetCurves];
	[self setNeedsDisplay:YES];
	}



// MARK: Table view

/*****************************************************************************\
|* Give up a view for the table
\*****************************************************************************/
- (AZView *)tableView:(AZTableView *)tv
   viewForTableColumn:(AZTableColumn *)tc
				  row:(NSInteger)row
	{
	AZView *view = [tv dequeueViewWithIdentifier:@"point"];
	if (view == nil)
		{
		AZViewController *vc;
		NSBundle *bndl	= [NSBundle mainBundle];
		vc				= [[AZViewController alloc] initWithNibName:@"point"
															 bundle:bndl];
		view			= vc.view;
		view.identifier	= @"point";
		}

	PointView *pv 		= (PointView *)view;
	AZBezierPath *path	= _paths[row];
	NSString *info  	= [NSString stringWithFormat:@"(%.2f, %.2f) [%.2f,%.2f]",
						   path.p0.x, path.p0.y, path.c0.x, path.c0.y];
	pv.point1.stringValue = info;

	info  				= [NSString stringWithFormat:@"(%.2f, %.2f) [%.2f,%.2f]",
						   path.p1.x, path.p1.y, path.c1.x, path.c1.y];
	pv.point2.stringValue = info;

	return view;
	}

/*****************************************************************************\
|* Return the number of entries in the table
\*****************************************************************************/
- (NSInteger)numberOfRowsInTableView:(AZTableView *)tableView
	{
	return _paths.count;
	}

/*****************************************************************************\
|* selection did change, called after the selection changed
\*****************************************************************************/
- (void)tableViewSelectionDidChange:(NSNotification *)note
	{
	AZTableView *tv 	= note.object;
	NSInteger row		= tv.selectedRow;
	if (row >= 0)
		{
		_edit = row;
		[self setNeedsDisplay:YES];
		}
	}

/*****************************************************************************\
|* See if the user pressed delete/backspace while a row was selected
\*****************************************************************************/
- (BOOL)tableView:(AZTableView *)tv keyDown:(AZEvent *)e
	{
	if ((e.keyCode == SDLK_DELETE) || (e.keyCode == SDLK_BACKSPACE))
		{
		if (_edit >= 0)
			{
			[_paths removeObjectAtIndex:_edit];
			_edit --;
			if (_paths.count > 0)
				{
				_state  = Pt_Point0;
				_p0 	= _paths.lastObject.p1.asPoint;
				}
			else
				_state 	= Pt_None;

			[_table reloadData];
			[self _updateOffsetCurves];
			[self setNeedsDisplay:YES];
			[self _updateCursor];
			}
		return YES;
		}
	return NO;
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


/*****************************************************************************\
|* Figure out which handle a point is on, if any
\*****************************************************************************/
- (PointState) _onHandle:(NSPoint)p
	{
	PointState handle 	= Pt_None;
	if (_edit >= 0)
		{
		AZBezierPath *path 	= _paths[_edit];
		NSRect r;

		if (path)
			{
			r = NSMakeRect(path.p0.x - 5, path.p0.y - 5, 10, 10);
			if (NSPointInRect(p,r))
				{
				handle = Pt_Point0;
				}
			else
				{
				r = NSMakeRect(path.c0.x - 5, path.c0.y - 5, 10, 10);
				if (NSPointInRect(p,r))
					{
					handle = Pt_Control0;
					}
				else
					{
					r = NSMakeRect(path.c1.x - 5, path.c1.y - 5, 10, 10);
					if (NSPointInRect(p,r))
						{
						handle = Pt_Control1;
						}
					else
						{
						r = NSMakeRect(path.p1.x - 5, path.p1.y - 5, 10, 10);
						if (NSPointInRect(p,r))
							{
							handle = Pt_Point1;
							}
						}
					}
				}
			}
		}
	return handle;
	}

/*****************************************************************************\
|* Get the bezier curves that are offset from all the drawn ones
\*****************************************************************************/
- (void) _updateOffsetCurves
	{
	float size = _innerSize.doubleValue;
	NSLog(@"size: %.2f", size);
	[self _updateCurve:_inner with:size];
	}

/*****************************************************************************\
|* Get the bezier curve that is offset from all the drawn ones
\*****************************************************************************/
- (void) _updateCurve:(NSMutableArray<AZBezierPath *>*)curve with:(float)size
	{
	[curve removeAllObjects];
	for (AZBezierPath *path in _paths)
		{
		AZBezierPath *offset = [path curveWithOffset:size maxError:.15];
		for (AZBezierPath *segment in offset.segments)
			[curve addObject:segment];
		}
	}




@end
