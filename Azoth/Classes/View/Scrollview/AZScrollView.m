//
//  AZScrollView.m
//  Azoth
//
//  Created by Simon Gornall on 12/22/24.
//

#import "AZClipView.h"
#import "AZColour.h"
#import "AZPainter.h"
#import "AZRulerView.h"
#import "AZScroller.h"
#import "AZScrollView.h"
#import "AZTypes.h"
#import "AZZib.h"

static Class _rulerViewClass = nil;

@implementation AZScrollView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,
		^{
		_rulerViewClass = AZRulerView.class;
		});

	if (self = [super initWithFrame:frame])
		{
		[self _commonScrollviewInit];

		AZClipView *clip = [[AZClipView alloc] initWithFrame:[self _clipViewFrame]];
		[clip setAutoresizingMask:AZViewWidthSizable|AZViewHeightSizable];

		[self addSubview:clip];
		}
	return self;
	}

/*****************************************************************************\
|* Configuration via dictionary. This is called by the NIB loader, but is a
|* valid way to create the view
\*****************************************************************************/
- (instancetype) initWithDictionary:(NSDictionary *)info;
	{
	if (self = [super initWithDictionary:info])
		{
		[self _commonScrollviewInit];

		// Set horizontal and vertical line and page scrolls
		NSNumber *v = ((NSNumber *)info[kZibHLineScroll]);
		self.horizontalLineScroll = (v) ? v.floatValue 	: 10;
		v = ((NSNumber *)info[kZibHPageScroll]);
		self.horizontalPageScroll = (v) ? v.floatValue 	: 50;
		v = ((NSNumber *)info[kZibVLineScroll]);
		self.verticalLineScroll = (v) ? v.floatValue 	: 10;
		v = ((NSNumber *)info[kZibVPageScroll]);
		self.verticalPageScroll = (v) ? v.floatValue 	: 50;

		BOOL hScroll = ([info[kZibHScroller] isEqualToString:@"YES"]);
		[self setHasHorizontalScroller:hScroll];

		BOOL vScroll = ([info[kZibVScroller] isEqualToString:@"YES"]);
		[self setHasVerticalScroller:vScroll];
		}

	return self;
	}

/*****************************************************************************\
|* Common initialisation
\*****************************************************************************/
- (void) _commonScrollviewInit
	{

	_hasVerticalScroller	= NO;
	_hasHorizontalScroller	= NO;
	self.drawsBackground	= YES;
	_borderType				= AZNoBorder;
	self.backgroundColour	= [[AZColour grey95Colour] copy];

	self.lineScroll			= 1.f;
	self.pageScroll			= 50.f;		//entirely arbitrary
	self.autoresizesSubviews= YES;

	}

// MARK: Class methods

/*****************************************************************************\
|* Work out the frame size for a given content size (or vice versa),
|* taking into account whether the scrollers exist or not
\*****************************************************************************/
+ (NSSize) frameSizeForContentSize:(NSSize)contentSize
			 hasHorizontalScroller:(BOOL)hasHorizontalScroller
			   hasVerticalScroller:(BOOL)hasVerticalScroller
						borderType:(AZBorderType)borderType
	{
	if (hasHorizontalScroller)
		contentSize.height += [AZScroller scrollerWidth];

	if (hasVerticalScroller)
		contentSize.width += [AZScroller scrollerWidth];

	switch(borderType)
		{
		case AZNoBorder:
			break;

		case AZLineBorder:
			contentSize.height+=1;
			contentSize.width+=1;
			break;

		case AZBezelBorder:
			contentSize.height+=2;
			contentSize.width+=2;
			break;

		case AZGrooveBorder:
			contentSize.height+=2;
			contentSize.width+=2;
			break;
		}

	return contentSize;
	}

+ (NSSize) contentSizeForFrameSize:(NSSize)frameSize
			 hasHorizontalScroller:(BOOL)hasHorizontalScroller
			   hasVerticalScroller:(BOOL)hasVerticalScroller
						borderType:(AZBorderType)borderType
	{
	if (hasHorizontalScroller)
		frameSize.height -= [AZScroller scrollerWidth];

	if (hasVerticalScroller)
		frameSize.width -= [AZScroller scrollerWidth];

	switch(borderType)
		{
		case AZNoBorder:
			break;

		case AZLineBorder:
			frameSize.height-=1;
			frameSize.width-=1;
			break;

		case AZBezelBorder:
			frameSize.height-=2;
			frameSize.width-=2;
			break;

		case AZGrooveBorder:
			frameSize.height-=2;
			frameSize.width-=2;
			break;
		}

	return frameSize;
	}


/*****************************************************************************\
|* Get/Set which class of view will implement the ruler views
\*****************************************************************************/
+ (void) setRulerViewClass:(Class)klass
	{
	_rulerViewClass = klass;
	}

+ (Class) rulerViewClass
	{
	return _rulerViewClass;
	}


/*****************************************************************************\
|* Override subview to also set contentView
\*****************************************************************************/
- (BOOL) addSubview:(AZView *)subview
	{
	BOOL ok = [super addSubview:subview];
	if (ok && [subview isKindOfClass:AZClipView.class])
		{
		[subview setFrame:[self _clipViewFrame]];
		_contentView = (AZClipView *)subview;
		}
	return ok;
	}

/*****************************************************************************\
|* Return opacity based on whether we draw the background
\*****************************************************************************/
- (BOOL) isOpaque
	{
	return self.drawsBackground;
	}

/*****************************************************************************\
|* Return the size of the content itself
\*****************************************************************************/
- (NSSize)contentSize
	{
	return _contentView.frame.size;
	}

/*****************************************************************************\
|* Get/Set the document view via the content view
\*****************************************************************************/
- (AZView *) documentView
	{
	return _contentView.documentView;
	}

- (void) setDocumentView:(AZView *)view
	{
	[_contentView setDocumentView:view];
	[self reflectScrolledClipView:_contentView];
	}

/*****************************************************************************\
|* Set the content view
\*****************************************************************************/
-(void)setContentView:(AZClipView *)clipView
	{
	[_contentView removeFromSuperview];
	_contentView = clipView;

	[self addSubview:_contentView];
	[_contentView setAutoresizingMask:AZViewWidthSizable|AZViewHeightSizable];
	[_contentView setAutoresizesSubviews:YES];
	[self tile];
	}

/*****************************************************************************\
|* Return the visible rectangle of the document view
\*****************************************************************************/
- (NSRect) documentVisibleRect
	{
	return _contentView.documentVisibleRect;
	}

/*****************************************************************************\
|* Get/set whether we draw the background via the content view
\*****************************************************************************/
- (BOOL) drawsBackground
	{
	return _contentView.drawsBackground;
	}

- (void) setDrawsBackground:(BOOL)value
	{
	_contentView.drawsBackground = value;
	if (!_contentView.drawsBackground)
		[_contentView setCopiesOnScroll:NO];
	}

/*****************************************************************************\
|* Get/set the background colour via the content view
\*****************************************************************************/
- (AZColour *) backgroundColour
	{
	return _contentView.backgroundColour;
	}

- (void) setBackgroundColour:(AZColour *)colour
	{
	_contentView.backgroundColour = colour;
	}


/*****************************************************************************\
|* Set the border type and update the tiling
\*****************************************************************************/
-(void)setBorderType:(AZBorderType)borderType
	{
	if(_borderType!=borderType)
		{
		_borderType=borderType;
		[self tile];
		}
	}

/*****************************************************************************\
|* Set a scroller and update the tiling
\*****************************************************************************/
-(void)setVerticalScroller:(AZScroller *)scroller
	{
	[_verticalScroller removeFromSuperview];
	_verticalScroller = scroller;
	[_verticalScroller setTarget:self];
	[_verticalScroller setAction:@selector(_verticalScroll:)];

	if(_hasVerticalScroller)
		[self addSubview:_verticalScroller];
   
	[self tile];
	}

-(void)setHorizontalScroller:(AZScroller *)scroller
	{
	[_horizontalScroller removeFromSuperview];
	_horizontalScroller = scroller;
	[_horizontalScroller setTarget:self];
	[_horizontalScroller setAction:@selector(_horizontalScroll:)];

	if (_hasHorizontalScroller)
		[self addSubview:_horizontalScroller];
    
	[self tile];
	}

/*****************************************************************************\
|* Update the properties indicating whether we have a scroller
\*****************************************************************************/
-(void)setHasVerticalScroller:(BOOL)flag
	{
	if (flag)
		{
		if (!_hasVerticalScroller)
			{
			_hasVerticalScroller = flag;
			[self _createVerticalScrollerIfNeeded];
			[self addSubview:_verticalScroller before:nil];
			[self tile];
			}
		}
	else
		{
		if (_hasVerticalScroller)
			{
			_hasVerticalScroller=flag;
			[_verticalScroller removeFromSuperview];
			[self tile];
			}
		}
	}

-(void)setHasHorizontalScroller:(BOOL)flag
	{
	if (flag)
		{
		if (!_hasHorizontalScroller)
			{
			_hasHorizontalScroller=flag;
			[self _createHorizontalScrollerIfNeeded];
			[self addSubview:_horizontalScroller before:nil];
			[self tile];
			}
		}
	else
		{
		if (_hasHorizontalScroller)
			{
			_hasHorizontalScroller=flag;
			[_horizontalScroller removeFromSuperview];
			[self tile];
			}
		}
	}

/*****************************************************************************\
|* Set whether we have a ruler and update the layout
\*****************************************************************************/
-(void)setHasVerticalRuler:(BOOL)flag
	{
    if (_hasVerticalRuler != flag)
		{
        _hasVerticalRuler = flag;
        [self tile];
        [_verticalRulerView setNeedsDisplay:flag];
		}
	}

-(void)setHasHorizontalRuler:(BOOL)flag
	{
    if (_hasHorizontalRuler != flag)
		{
        _hasHorizontalRuler = flag;
        [self tile];
        [_horizontalRulerView setNeedsDisplay:flag];
		}
	}

/*****************************************************************************\
|* Some control over the line spacing, make sure it's >0
\*****************************************************************************/
-(void)setVerticalLineScroll:(float)value
	{
    if (value > 0.0)
        _verticalLineScroll = value;
	}

-(void)setHorizontalLineScroll:(float)value
	{
    if (value > 0.0)
        _horizontalLineScroll = value;
	}

-(void)setVerticalPageScroll:(float)value
	{
    if (value > 0.0)
        _verticalPageScroll = value;
	}

-(void)setHorizontalPageScroll:(float)value
	{
    if (value > 0.0)
        _horizontalPageScroll = value;
	}

-(void)setLineScroll:(float)value
	{
    [self setHorizontalLineScroll:value];
    [self setVerticalLineScroll:value];
	}

-(void)setPageScroll:(float)value
	{
    [self setHorizontalPageScroll:value];
    [self setVerticalPageScroll:value];
	}

/*****************************************************************************\
|* Toggle ruler visibility and update the layout
\*****************************************************************************/
-(void)setRulersVisible:(BOOL)flag
	{
    if (_rulersVisible != flag)
		{
        _rulersVisible = flag;
        [self tile];
		}
	}


/*****************************************************************************\
|* Set the vertical ruler view
\*****************************************************************************/
- (void)setVerticalRulerView:(AZRulerView *)ruler
	{
    if (_verticalRulerView)
		[_verticalRulerView removeFromSuperview];
    _verticalRulerView = ruler;

    if (_verticalRulerView)
		{
        [_verticalRulerView setScrollView:self];
        [_verticalRulerView setOrientation:AZVerticalRuler];
        [self addSubview:_verticalRulerView];
		}
    _hasVerticalRuler = _verticalRulerView != nil;
    [self tile];
	}

/*****************************************************************************\
|* Set the horizontal ruler view
\*****************************************************************************/
- (void)setHorizontalRulerView:(AZRulerView *)ruler
	{
    if (_horizontalRulerView)
		[_horizontalRulerView removeFromSuperview];
    _horizontalRulerView = ruler;

    if (_horizontalRulerView)
		{
        [_horizontalRulerView setScrollView:self];
        [_horizontalRulerView setOrientation:AZHorizontalRuler];
        [self addSubview:_horizontalRulerView];
		}
    _hasHorizontalRuler = _horizontalRulerView != nil;
    [self tile];
	}


/*****************************************************************************\
|* Lay out the various views
\*****************************************************************************/
-(void) tile
	{
	[self _createHeaderAndCornerViewsIfNeeded];
	[self _createRulerViewsIfNeeded];

	NSRect frame = [self _headerClipViewFrame];
	[_headerClipView setFrame:frame];

	frame = [self _cornerViewFrame];
	[_cornerView setFrame:frame];

    frame = [self _verticalScrollerFrame];
	[_verticalScroller setFrame:frame];

    frame = [self _horizontalScrollerFrame];
	[_horizontalScroller setFrame:frame];
    
    frame = [self _clipViewFrame];
	[_contentView setFrame:frame];

	frame = [self _horizontalRulerFrame];
	[_horizontalRulerView setFrame:frame];

	frame = [self _verticalRulerFrame];
	[_verticalRulerView setFrame:frame];

	frame = [_contentView bounds];
	if (!self.hasVerticalScroller)
		frame.origin.y = 0;
	if( !self.hasHorizontalScroller)
		frame.origin.x = 0;
	[_contentView setBoundsOrigin:frame.origin];

	[self reflectScrolledClipView:_contentView];
	}

/*****************************************************************************\
|* Update the state of the scrollers based on the clipview
\*****************************************************************************/
-(void) reflectScrolledClipView:(AZClipView *)clipView
	{
	if (_contentView == clipView)
		{
		AZView *docView 		= [self documentView];
		NSRect headerClipRect	= [_headerClipView frame];

		if(docView == nil)
			{
			[_verticalScroller setEnabled:NO];
			[_verticalScroller setIsHidden:_autohidesScrollers];
			[_horizontalScroller setEnabled:NO];
			[_horizontalScroller setIsHidden:_autohidesScrollers];
			}
		else
			{
			NSRect docRect 	= [docView frame];
			NSRect clipRect	= [_contentView bounds];

			float  dh		= docRect.size.height - clipRect.size.height;
			float  dw		= docRect.size.width - clipRect.size.width;

			if (dh <= 0)
				{
				[_verticalScroller setEnabled:NO];
				[_verticalScroller setIsHidden:_autohidesScrollers];
				}
			else
				{
				float ody 		= clipRect.origin.y - docRect.origin.y;
				float value 	= (dh <= 0) ? 0 : ody / dh;
				float fraction	= NSHeight(clipRect) / NSHeight(docRect);
				[_verticalScroller setEnabled:YES];
				[_verticalScroller setIsHidden:NO];
				[_verticalScroller setDoubleValue:value];
				[_verticalScroller setKnobProportion:fraction];
				}

			if (dw <= 0)
				{
				[_horizontalScroller setEnabled:NO];
				[_horizontalScroller setIsHidden:_autohidesScrollers];
				}
			else
				{
 				float odx 		= clipRect.origin.x - docRect.origin.x;
				float value		= (dw <= 0) ? 0 : odx / dw;
				float fraction	= NSWidth(clipRect) / NSWidth(docRect);
				[_horizontalScroller setEnabled:YES];
				[_horizontalScroller setIsHidden:NO];
				[_horizontalScroller setDoubleValue:value];
				[_horizontalScroller setKnobProportion:fraction];
				}
			}

		// Can't do sublayout in here because it messes with the tile method
		[_horizontalRulerView invalidateHashMarks];
		[_verticalRulerView invalidateHashMarks];

		// keep the header in line with the document
		// using scrollToPoint: ran into some ordering issues, since
		// -scrollToPoint calls constrainScrollPoint *and* this method.
		headerClipRect.origin.x 	= _contentView.frame.origin.x;
		headerClipRect.size.width 	= _contentView.frame.size.width;
		[_headerClipView setFrame:headerClipRect];
		[_headerClipView setNeedsDisplay:YES];
		}
	}


/*****************************************************************************\
|* Draw...
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	if (self.drawsBackground)
		{
		[painter rectangleWithRect:dirtyRect
							filled:YES
							colour:[self backgroundColour]];
		}

	switch (_borderType)
		{
		case AZNoBorder:
			break;

		case AZLineBorder:
			[painter rectangleWithRect:self.bounds colour:AZColour.blackColour];
			break;

		case AZBezelBorder:
			[painter rectangleWithBezel:self.bounds withClip:dirtyRect];
			break;

		case AZGrooveBorder:
			[painter rectangleWithGroove:self.bounds withClip:dirtyRect];
			break;
		}
	}

/*****************************************************************************\
|* Return the header view by querying the document view
\*****************************************************************************/
- (nullable AZView *) headerView
	{
	AZView *document = self.documentView;

	if ([document respondsToSelector:@selector(headerView)])
		return [document performSelector:@selector(headerView)];

	return nil;
	}

// MARK: Override NSView

-(void)resizeSubviewsWithOldSize:(NSSize)oldSize
	{
	[self tile];

	if ([self hasVerticalScroller])
		[self _verticalScroll:_verticalScroller];

	if ([self hasHorizontalScroller])
		[self _horizontalScroll:_horizontalScroller];
	}


// MARK: Private methods

/*****************************************************************************\
|* Return the bounds after any border space is removed
\*****************************************************************************/
-(NSRect) _insetBounds
	{
	NSRect bounds = self.bounds;

	switch(_borderType)
		{
		case AZNoBorder:
			break;

		case AZLineBorder:
			bounds=NSInsetRect(bounds,1,1);
			break;

		case AZBezelBorder:
			bounds=NSInsetRect(bounds,1,1);
			break;

		case AZGrooveBorder:
			bounds=NSInsetRect(bounds,2,2);
			break;
		}

	return bounds;
	}

/*****************************************************************************\
|* Return the corner view by querying the document view
\*****************************************************************************/
- (nullable AZView *) _cornerView
	{
	AZView *document = self.documentView;

	if ([document respondsToSelector:@selector(cornerView)])
		return [document performSelector:@selector(cornerView)];

	return nil;
	}

/*****************************************************************************\
|* Return the frame of the header-view
\*****************************************************************************/
-(NSRect) _headerClipViewFrame
	{
    AZView *headerView= [self headerView];

    if (headerView == nil)
        return NSZeroRect;

    NSRect  result 		= [self _insetBounds];
    result.size.height	= headerView.bounds.size.height;
    result.size.width  -= [AZScroller scrollerWidth];

    return result;
	}

/*****************************************************************************\
|* Return the frame of the corner-view
\*****************************************************************************/
-(NSRect) _cornerViewFrame
	{
    AZView *headerView= [self headerView];

    if (headerView == nil)
        return NSZeroRect;

	NSRect frame;
	NSRect bounds 		= [self _insetBounds];
	frame.origin.x 		= NSMaxX(bounds) - AZScroller.scrollerWidth;
    frame.origin.y 		= bounds.origin.y;
    frame.size.width 	= AZScroller.scrollerWidth;
    frame.size.height 	= headerView.bounds.size.height;

    return frame;
	}

/*****************************************************************************\
|* Return the frame of the horizontal rule, which spans the entire width of the
|* scrollview
\*****************************************************************************/
-(NSRect) _horizontalRulerFrame
	{
    NSRect result 		= [self _insetBounds];
    result.size.height 	= _horizontalRulerView.requiredThickness;
    return result;
	}

/*****************************************************************************\
|* Return the frame of the vertical rule, which is positioned below the
|* horizontal ruler
\*****************************************************************************/
-(NSRect) _verticalRulerFrame
	{
    NSRect result 		= [self _insetBounds];
    result.size.width 	= _verticalRulerView.requiredThickness;

    if (self.rulersVisible && self.hasHorizontalRuler)
		{
		float dy			 = [_horizontalRulerView requiredThickness];
        result.origin.y 	+= dy;
        result.size.height 	-= dy;
		}
    
    return result;
	}

/*****************************************************************************\
|* Return the frame of the clip view for the document view
\*****************************************************************************/
-(NSRect) _clipViewFrame
	{
    NSRect bounds 		= [self _insetBounds];

	NSRect result;
	result.origin.x		= bounds.origin.x;
	result.origin.y 	= bounds.origin.y;

	result.size.width	= bounds.size.width;
	if (self.hasVerticalScroller && !_verticalScroller.isHidden)
		result.size.width -= AZScroller.scrollerWidth;

	if (self.rulersVisible && self.hasVerticalRuler)
		{
		float dx			 = [self _verticalRulerFrame].size.width;
		result.origin.x		+= dx;
		result.size.width	-= dx;
		}

	result.size.height	= bounds.size.height;
	if (self.hasHorizontalScroller && !_horizontalScroller.isHidden)
		result.size.height	-= AZScroller.scrollerWidth;

	if (self.rulersVisible && [self hasHorizontalRuler])
		{
		float dy			 = [self _horizontalRulerFrame].size.height;
		result.origin.y		+= dy;
		result.size.height	-= dy;
		}

	if ([self headerView] != nil)
		{
		float dy			 = [self _headerClipViewFrame].size.height;
		result.origin.y		+= dy;
		result.size.height	-= dy;
		}

	return result;
	}

/*****************************************************************************\
|* Return the frame of the vertical scroller
\*****************************************************************************/
-(NSRect) _verticalScrollerFrame
	{
    NSRect bounds 		= [self _insetBounds];

	NSRect result;
	result.origin.x		= NSMaxX(bounds) - AZScroller.scrollerWidth;
	result.origin.y		= bounds.origin.y;
	result.size.width	= AZScroller.scrollerWidth;

	result.size.height	= bounds.size.height;
    if (self.hasHorizontalScroller && !_horizontalScroller.isHidden)
		result.size.height	-= AZScroller.scrollerWidth;

    if ([self headerView] != nil)
		{
		float dy			 = [self _headerClipViewFrame].size.height;
		result.origin.y		+= dy;
		result.size.height	-= dy;
		}

    if (self.rulersVisible && self.hasHorizontalRuler)
		{
		float dy			 = _horizontalRulerView.requiredThickness;
		result.origin.y		+= dy;
		result.size.height	-= dy;
		}

	return result;
	}

/*****************************************************************************\
|* Return the frame of the horizontal scroller
\*****************************************************************************/
-(NSRect) _horizontalScrollerFrame
	{
	NSRect bounds		= [self _insetBounds];

	NSRect result;
	result.origin.x		= bounds.origin.x;
	result.origin.y		= NSMaxY(bounds) - AZScroller.scrollerWidth;

	result.size.width	= bounds.size.width;
	if (self.hasVerticalScroller && !_verticalScroller.isHidden)
		result.size.width	-= AZScroller.scrollerWidth;

	result.size.height	= AZScroller.scrollerWidth;
    if (self.rulersVisible && self.hasVerticalRuler)
		{
		result.origin.x		+= _verticalRulerView.requiredThickness;
		result.size.width	-= _verticalRulerView.requiredThickness;
		}

	return result;
	}

/*****************************************************************************\
|* Create the vertical scroller if we don't already have one
\*****************************************************************************/
-(void) _createVerticalScrollerIfNeeded
	{
	if (_verticalScroller == nil)
		{
		NSRect frame			= [self _verticalScrollerFrame];
		_verticalScroller 		= [[AZScroller alloc] initWithFrame:frame];

		int mask				= AZViewMinXMargin | AZViewHeightSizable;
		_verticalScroller.autoresizingMask = mask;

		_verticalScroller.target = self;
		_verticalScroller.action = @selector(_verticalScroll:);
		}
	}

/*****************************************************************************\
|* Create the horizontal scroller if we don't already have one
\*****************************************************************************/
-(void) _createHorizontalScrollerIfNeeded
	{
	if (_horizontalScroller == nil)
		{
		NSRect frame				= [self _horizontalScrollerFrame];
		_horizontalScroller 		= [[AZScroller alloc] initWithFrame:frame];

		int mask					= AZViewMaxYMargin | AZViewWidthSizable;
		_horizontalScroller.autoresizingMask = mask;

		_horizontalScroller.target	= self;
		_horizontalScroller.action	= @selector(_horizontalScroll:);
		}
	}

/*****************************************************************************\
|* Create the header/corner views if we don't already have them
\*****************************************************************************/
-(void) _createHeaderAndCornerViewsIfNeeded
	{
	AZView *headerView = [self headerView];

	if (headerView == nil)
		{
		[self.headerClipView removeFromSuperview];
		self.headerClipView = nil;
		}

	else if ((headerView !=nil) && (_headerClipView==nil))
		{
		NSRect frame		= [self _headerClipViewFrame];
		self.headerClipView = [[AZClipView alloc] initWithFrame:frame];
		[_headerClipView setDocumentView:headerView];

		[self addSubview:_headerClipView];

		int mask = AZViewWidthSizable | AZViewHeightSizable;
		_headerClipView.autoresizingMask 	= mask;
		_headerClipView.autoresizesSubviews	= YES;
		}

    if (self.cornerView == nil)
		{
        [_cornerView removeFromSuperview];
        _cornerView = nil;
		}
    else if ((self.cornerView != nil) && _cornerView == nil)
		{
        // Use the document corner view - and it's a retained property
        _cornerView = self.cornerView;
        [self addSubview:_cornerView];
		}
	}

/*****************************************************************************\
|* Create the ruler views if we don't already have them
\*****************************************************************************/
-(void) _createRulerViewsIfNeeded
	{
    if (_horizontalRulerView.superview != nil)
        [_horizontalRulerView removeFromSuperview];

    if (_verticalRulerView.superview != nil)
        [_verticalRulerView removeFromSuperview];

    if (_rulersVisible)
		{
		Class klass = self.class.rulerViewClass;
        if (_hasHorizontalRuler)
			{
			AZRulerOrientation type = AZHorizontalRuler;
            if (_horizontalRulerView == nil)
                _horizontalRulerView = [[klass alloc] initWithScrollView:self
															 orientation:type];

			[self addSubview:_horizontalRulerView];
			}

        if (_hasVerticalRuler)
			{
			AZRulerOrientation type = AZVerticalRuler;
            if (_verticalRulerView == nil)
                _verticalRulerView = [[klass alloc] initWithScrollView:self
														   orientation:type];

            [self addSubview:_verticalRulerView];
			}
		}
	}


/*****************************************************************************\
|* Handle vertical scroll events from the scroller
\*****************************************************************************/
- (void) _verticalScroll:(AZScroller *)scroller
	{
	float value			= [scroller doubleValue];
	AZView *docView		= [self documentView];

	NSRect  docRect		= [docView frame];
	NSRect  clipRect	= [_contentView bounds];
	float lineScroll	= _verticalLineScroll;
	float pageScroll	= _verticalPageScroll;

	switch([scroller hitPart])
		{
		case AZScrollerIncrementLine:
			clipRect.origin.y+=lineScroll;
			break;

       case AZScrollerDecrementLine:
			clipRect.origin.y-=lineScroll;
			break;

       case AZScrollerIncrementPage:
			clipRect.origin.y+=pageScroll;
			break;

       case AZScrollerDecrementPage:
			clipRect.origin.y-=pageScroll;
			break;

       case AZScrollerKnob:
       default:
			value *= (docRect.size.height-clipRect.size.height);
			clipRect.origin.y = docRect.origin.y + (int)(value);
			break;
		}

	[_contentView scrollToPoint:clipRect.origin];
	}

/*****************************************************************************\
|* Handle horizontal scroll events from the scroller
\*****************************************************************************/
-(void) _horizontalScroll:(AZScroller *)scroller
	{
	float   value			= [scroller doubleValue];
	AZView *docView			= [self documentView];
	NSRect  docRect			= [docView frame];
	NSRect  clipRect		= [_contentView bounds];
	NSRect  headerClipRect	= [_headerClipView bounds];

   switch([scroller hitPart])
		{
		case AZScrollerIncrementLine:
			clipRect.origin.x += _horizontalLineScroll;
			break;

		case AZScrollerDecrementLine:
			clipRect.origin.x -= _horizontalLineScroll;
			break;

		case AZScrollerIncrementPage:
			clipRect.origin.x += _horizontalPageScroll;
			break;

		case AZScrollerDecrementPage:
			clipRect.origin.x -= _horizontalPageScroll;
			break;

		case AZScrollerKnob:
		default:
			value *= (docRect.size.width - clipRect.size.width);
			clipRect.origin.x = docRect.origin.x + (int)(value);
			break;
		}

	headerClipRect.origin.x = clipRect.origin.x;
	[_contentView scrollToPoint:clipRect.origin];
	[_headerClipView scrollToPoint:headerClipRect.origin];
	}

@end
