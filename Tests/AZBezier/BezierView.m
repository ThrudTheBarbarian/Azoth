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
@property(strong) IBOutlet AZSlider *								steps;
@property(strong) IBOutlet AZImageView *							img;
@property(strong) IBOutlet AZButton *								loadButton;

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

// The Texture to texture-map onto the curve
@property(strong,nonatomic) AZImage *								texture;

// The data for the vertices
@property(assign,nonatomic) SDL_Vertex *							vertices;
@property(assign,nonatomic) int 									numVertices;
@property(assign,nonatomic) int 									maxVertices;
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

	_vertices				= NULL;
	_numVertices			= 0;
	_maxVertices			= 0;
	}

/*****************************************************************************\
|* Draw the view
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[super drawInRect:dirtyRect withPainter:painter];

	if (_numVertices)
		{
		NSInteger texId 	= (_texture != nil)
							? _texture.asTexture.index.integerValue
							: 0;
		AZRenderer3d *azr 	= AZRenderer.renderer;
		azr.addressMode		= AZTextureAddressWrap;
		[azr blit:texId with:_numVertices vertices:_vertices];
		}

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


/*****************************************************************************\
|* Steps value changed
\*****************************************************************************/
- (IBAction)stepsChanged:(id)sender
	{
	}

/*****************************************************************************\
|* Load texture called
\*****************************************************************************/
- (IBAction)loadTexturePressed:(id)sender
	{
	char *path 			= NULL;
	NSUserDefaults *ud 	= NSUserDefaults.standardUserDefaults;
	NSString *at 		= [ud stringForKey:@"texturePath"];
	if (at)
		path 			= (char *) at.UTF8String;

	SDL_ShowOpenFileDialog(openCallback,			// Called on completion
						   (__bridge void *)(self), // Passed to callback
						   self.window.window, 		// Modal for this window
						   NULL, 				// The filter above
						   0, 						// Number of filters
						   path, 					// Default location
						   NO);						// Allow many files
	}

static void openCallback(void *userData, const char * const *files, int filter)
    {
	BezierView *bv = (__bridge BezierView *)userData;

	if (files == NULL)
		SDL_Log("Cannot read file: %s", SDL_GetError());
	else if (files[0] == NULL)
		{
		// User cancelled the op. Just ignore
		}
	else
		{
		NSString *path 	= [NSString stringWithUTF8String:files[0]];
		bv.texture 		= [AZImage imageWithContentsOfFile:path];
		if (bv.texture)
			{
			[bv.img setImage:bv.texture];

			NSUserDefaults *ud 	= NSUserDefaults.standardUserDefaults;
			path = [path stringByDeletingLastPathComponent];
			[ud setObject:path forKey:@"texturePath"];
			}
		}

	bv.loadButton.state = AZControlStateNormal;
	[bv setNeedsDisplay:YES];
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
|* Get the bezier curves that are offset from all the drawn ones. Once the
|* offset curve is created, tesselate a bunch of triangles over the area
|* defined by the two bezier curves, connecting adjacent ends with lines
\*****************************************************************************/
- (void) _updateOffsetCurves
	{
	if (_paths.count == 0)
		return;

	/*************************************************************************\
	|* Calculate the offset curve
	\*************************************************************************/
	float size = _innerSize.doubleValue;
	[self _updateCurve:_inner with:size];

	/*************************************************************************\
	|* figure out the total length of each bezier curve from constituents. We
	|* force an odd number of steps here, so we get back an even number of
	|* points after taking into account both end-points. That means we can
	|* always make quadrilaterals out of the point series
	\*************************************************************************/
	int steps  = _steps.intValue | 1;
	int max    = (int)(MAX(_inner.count, _paths.count));

	double lengths[2];			// The overall lengths of each extended curve
	double segment[2][max];		// The lengths of each constituent curve

	lengths[0] = [self _calculateLengthsFor:_paths
								 usingSteps:steps
									lengths:segment[0]];
	lengths[1] = [self _calculateLengthsFor:_inner
								 usingSteps:steps
									lengths:segment[1]];


	/*************************************************************************\
	|* divide each to get 'steps' points on each extended curve
	\*************************************************************************/
	int numPoints[2];			// Number of segments in each extended curve
	NSPoint points[2][steps+2];	// The points along the curves

	numPoints[0] = [self _generatePoints:points[0]
								 forPath:_paths
							  usingSteps:steps
							   forLength:lengths[0]
						  segmentLengths:segment[0]];

	numPoints[1] = [self _generatePoints:points[1]
								 forPath:_inner
							  usingSteps:steps
							   forLength:lengths[1]
						  segmentLengths:segment[1]];

	int count = numPoints[0];
	if (numPoints[0] != numPoints[1])
		{
		SDL_Log("Points don't match, using smaller of two!");
		count = MIN(numPoints[0], numPoints[1]);
		}
	count &= (~1);

	/*************************************************************************\
	|* Make sure we have enough space to allocate the vertices
	\*************************************************************************/
	_numVertices = count * 6;
	if (_maxVertices < _numVertices)
		{
		SAFELY_FREE(_vertices);
		_maxVertices = _numVertices;
		_vertices = calloc(_numVertices, sizeof(SDL_Vertex));
		}
	;

	/*************************************************************************\
	|* create triangles from points A,B,C and B,C,D to cover quadrilateral.
	|* For every 2 points along the curve, we will need 6 vertices
	\*************************************************************************/
	int vertex 		= 0;
	double tWidth	= _texture ? _texture.asTexture.size.width : 1.0;
	double stepSize	= _texture ? tWidth / count * 2 : 0.0;

	for (int i=0; i<count-1; i ++)
		{
		NSPoint A = points[0][i];
		NSPoint B = points[1][i];
		NSPoint C = points[0][i+1];
		NSPoint D = points[1][i+1];

		_vertices[vertex  ].tex_coord.x	= (i * stepSize)/tWidth;
		_vertices[vertex  ].tex_coord.y	= 0;
		_vertices[vertex  ].color		= (SDL_FColor){1,1,1,1};
		_vertices[vertex  ].position.x 	= A.x;
		_vertices[vertex++].position.y 	= A.y;

		_vertices[vertex  ].tex_coord.x	= i * stepSize/tWidth;
		_vertices[vertex  ].tex_coord.y	= 1;
		_vertices[vertex  ].color		= (SDL_FColor){1,1,1,1};
		_vertices[vertex  ].position.x 	= B.x;
		_vertices[vertex++].position.y 	= B.y;

		_vertices[vertex  ].tex_coord.x	= (i+1) * stepSize/tWidth;
		_vertices[vertex  ].tex_coord.y	= 0;
		_vertices[vertex  ].color		= (SDL_FColor){1,1,1,1};
		_vertices[vertex  ].position.x 	= C.x;
		_vertices[vertex++].position.y 	= C.y;

		_vertices[vertex  ].tex_coord.x	= (i+1) * stepSize/tWidth;
		_vertices[vertex  ].tex_coord.y	= 0;
		_vertices[vertex  ].color		= (SDL_FColor){1,1,1,1};
		_vertices[vertex  ].position.x 	= C.x;
		_vertices[vertex++].position.y 	= C.y;

		_vertices[vertex  ].tex_coord.x	= (i+1) * stepSize/tWidth;
		_vertices[vertex  ].tex_coord.y	= 1;
		_vertices[vertex  ].color		= (SDL_FColor){1,1,1,1};
		_vertices[vertex  ].position.x 	= D.x;
		_vertices[vertex++].position.y 	= D.y;

		_vertices[vertex  ].tex_coord.x	= i * stepSize/tWidth;
		_vertices[vertex  ].tex_coord.y	= 1;
		_vertices[vertex  ].color		= (SDL_FColor){1,1,1,1};
		_vertices[vertex  ].position.x 	= B.x;
		_vertices[vertex++].position.y 	= B.y;
		}
	}


/*****************************************************************************\
|* Work out the length/s of a given set of bezier curves
\*****************************************************************************/
- (double) _calculateLengthsFor:(NSArray<AZBezierPath*> *)paths
				     usingSteps:(int)step
					    lengths:(double *)lengths
	{
	double totalLength	= 0;
	double stepSize		= 1.0/step;
	int curve			= 0;

	for (AZBezierPath *path in paths)
		{
		double at 			= stepSize;
		AZBezierPoint *p0 	= [path pointAt:0.0];
		lengths[curve]		= 0.0;

		for (int i=1; i<=step; i++)
			{
			AZBezierPoint *p1 	= [path pointAt:at];
			AZBezierPoint *vec	= [p1.copy subtract:p0];
			p0 					= p1;
			lengths[curve]	   += vec.length;
			at 				   += stepSize;
			}
		totalLength += lengths[curve];
		curve ++;
		}
		
	return totalLength;
	}

/*****************************************************************************\
|* Position points along a bezier curve so they're equally distributed
\*****************************************************************************/
- (int) _generatePoints:(NSPoint *)points
			    forPath:(NSArray<AZBezierPath *> *)paths
			 usingSteps:(int)steps
			  forLength:(double)length
		 segmentLengths:(double *)lengths
	{
	int num 			= 0;
	int curve			= 0;
	double stepSize 	= length / steps;
	double cumulative	= 0.0;
	BOOL finished		= NO;

	AZBezierPath *path	= paths[0];

	for (int i=0; i<=steps; i++)
		{
		double at 			= cumulative / lengths[curve];
		AZBezierPoint *p 	= [paths[curve] pointAt:at];
		points[num++] 	 	= p.asPoint;

		cumulative		   += stepSize;
		while (cumulative > lengths[curve])
			{
			cumulative -= lengths[curve];
			curve ++;

			// Should never happen twice
			if (curve >= paths.count)
				{
				if (!finished)
					{
					finished = YES;
					curve --;
					cumulative = lengths[curve];
					}
				else
					break;
				}
			}
		}

//	for (int i=0; i<num; i++)
//		printf("%4d: %.2f,%.2f\n", i, points[i].x, points[i].y);
//	printf("%d points\n\n", num);

	return num;
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
