//
//  AZPainter.m
//  Azoth
//
//  Created by ThrudTheBarbarian on 12/12/24.
//

#import <SDL3/SDL.h>

#import "AZApplication.h"
#import "AZColour.h"
#import "AZImage.h"
#import "AZGeometry.h"
#import "AZObject.h"
#import "AZPainter.h"
#import "AZRenderer.h"
#import "AZTextPainter.h"
#import "AZView.h"
#import "AZView+Internal.h"
#import "AZWindow.h"

#define AAlevels 256
#define AAbits 8

#ifndef EXTRACT_VARARGS
#  define EXTRACT_VARARGS(string, fmt)		 								\
    va_list lst; 															\
    va_start(lst, fmt); 													\
    NSString *string = [[NSString alloc] initWithFormat:fmt arguments:lst];	\
    va_end(lst)
#endif

/*****************************************************************************\
|* Structures used
\*****************************************************************************/

// The internal Bresenham iterator
typedef struct
	{
	Sint16 x, y;
	int dx, dy, s1, s2, swapdir, error;
	Uint32 count;
	} SDL2_gfxBresenhamIterator;


/*****************************************************************************\
|* File-static variables
\*****************************************************************************/
static int * _polyInts 		= NULL;			// Global polygon cache for sorting
static int _polyIntsSize 	= 0;			// Size of polygon cache


/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZPainter()
@property(assign, nonatomic) id<AZRenderer>						renderer;
@property(strong, nonatomic, nullable) AZView * 				view;
@property(assign, nonatomic) NSInteger 							texture;
@property(assign, nonatomic) NSRect 							oldClip;
@property(assign, nonatomic) NSInteger 							oldFocus;
@property(assign, nonatomic) BOOL 								focusLocked;
@end

/*****************************************************************************\
|* Access to AZImage
\*****************************************************************************/
@interface AZImage(AZPainter)
- (NSRect) srcRect;
- (AZImageDrawingHandler) handler;
@end

@implementation AZPainter

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithView:(AZView *)view
	{
	if (self = [super init])
		{
		[view _installBackingTextureIfNecessary];
		_view 		= view;
		_texture	= view.bg;
		if (![self _painterCommonInit])
			self = nil;
		}
	return self;
	}

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithTexture:(NSInteger)texture
	{
	if (self = [super init])
		{
		_view 		= nil;
		_texture	= texture;
		if (![self _painterCommonInit])
			self = nil;
		}
	return self;
	}

/*****************************************************************************\
|* Common initialisation
\*****************************************************************************/
- (BOOL) _painterCommonInit
	{
	_renderer = AZRenderer.renderer;
	if (_renderer == NULL)
		{
		SDL_LogError(SDL_LOG_CATEGORY_GPU, "Cannot get window renderer");
		return NO;
		}
	_usingAntiAliasing	= NO;
	_drawAAEndpoint		= NO;
	_textPainter		= [AZTextPainter painterWithRenderer:_renderer];
	_textPainter.font	= AZApp.controlFont;
	return YES;
	}

+ (AZPainter *) painterForView:(AZView *)view
	{
	return [[AZPainter alloc] initWithView:view];
	}

+ (AZPainter *) painterForTexture:(NSInteger)texture
	{
	return [[AZPainter alloc] initWithTexture:texture];
	}

/*****************************************************************************\
|* Tidy up on dealloc
\*****************************************************************************/
- (void) dealloc
	{
	if (_focusLocked)
		[self unlockFocus];
	}

/*****************************************************************************\
|* Set up the context to draw, and call the view's method with ourselves as a
|* parameter
\*****************************************************************************/
- (BOOL) execute
	{
	[self lockFocus:YES];

	[_view drawInRect:_view.dirty withPainter:self];
	_view.dirty = NSZeroRect;

	[self unlockFocus];
	return YES;
	}

/*****************************************************************************\
|* Lock focus. Returns the previous focus
\*****************************************************************************/
- (void) lockFocus:(BOOL)clearTexture
	{
	AZColour *clearColour	= nil;
	_oldClip 				= _renderer.clipRect;
	_oldFocus 				= [_renderer currentFocus];
	_focusLocked			= YES;

	if (![_renderer lockFocusOn:_texture])
		SDL_Log("Failed to lock focus on texture %d for %s",
				(int)_texture, self.class.description.UTF8String);

	if (_view)
		{
		[_renderer setClip:_view.dirty];
		clearColour = _view.backgroundColour;
		}
	else
		{
		[_renderer setClip:[_renderer boundsOfTexture:_texture]];
		clearColour = AZColour.clear;
		}

	if (clearTexture)
		{
		[_renderer setDrawColour:clearColour];
		[_renderer clear];
		}
	}


/*****************************************************************************\
|* Unlock focus
\*****************************************************************************/
- (void) unlockFocus
	{
	_focusLocked = NO;
	[_renderer setClip:_oldClip];
	[_renderer restoreFocus:_oldFocus];
	}


// MARK: Pixel Drawing routines

/*****************************************************************************\
|* Pixel routines
\*****************************************************************************/

// Draw a single pixel in the current colour
- (int) pixelAtX:(int)x y:(int)y
	{
	return [_renderer renderPointAtX:x y:y];
	}

// Draw pixel with blending enabled if a<255
- (int) pixelAtX:(int)x y:(int)y colour:(AZColour *)colour
	{
	return [self pixelAtX:x
						y:y
				    withR:colour.R
						g:colour.G
						b:colour.B
						a:colour.A];
	}

// Draw pixel with blending enabled if a<255, using r,g,b,a
- (int) pixelAtX:(int)x y:(int)y
		 withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	int result = 0;
	if (a != 255)
		result |= [_renderer setBlendMode:SDL_BLENDMODE_BLEND];
	result |= [_renderer setDrawColourToRed:r g:g b:b a:a];
	result |= [_renderer renderPointAtX:x y:y];
	return result;
	}

// Draw pixel with blending enabled if a<255, and weight 'alpha' by 0..255
- (int) pixelAtX:(int)x y:(int)y colour:(AZColour *)colour weight:(int)weight
	{
	return [self pixelAtX:x
						y:y
			  alphaWeight:weight
					withR:colour.R
						g:colour.G
						b:colour.B
						a:colour.A];
	}

// Draw pixel with blending enabled if a<255, and weight 'alpha' by 0..255
- (int) pixelAtX:(int)x y:(int)y alphaWeight:(int)weight
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	uint32_t ax = a;
	ax = ((ax * weight) >> 8);
	if (ax > 255)
		a = 255;
	else
		a = (uint8_t)(ax & 0xff);
	return [self pixelAtX:x y:y withR:r g:g b:b a:a];
	}


// MARK: Line drawing routines


/*****************************************************************************\
|* line routines
\*****************************************************************************/

// Draw a line in the current colour. No blending
- (int) lineAtX:(int)x1 y:(int)y1 toX:(int)x2 y:(int)y2
	{
	return [_renderer renderLineFromX:x1 y:y1 toX:x2 y:y2];
	}

- (int) lineAt:(NSPoint)xy1 to:(NSPoint)xy2
	{
	return [_renderer renderLineFromX:xy1.x y:xy1.y toX:xy2.x y:xy2.y];
	}


// Draw a line with blending enabled if a<255
- (int) lineAtX:(int)x1 y:(int)y1 toX:(int)x2 y:(int)y2 colour:(AZColour *)colr
	{
	return [self lineAtX:x1
					   y:y1
					 toX:x2
					   y:y2
				   withR:colr.R
					   g:colr.G
					   b:colr.B
					   a:colr.A];
	}

- (int) lineAt:(NSPoint)xy1 to:(NSPoint)xy2 colour:(AZColour *)colr
	{
	return [self lineAtX:xy1.x
					   y:xy1.y
					 toX:xy2.x
					   y:xy2.y
				   withR:colr.R
					   g:colr.G
					   b:colr.B
					   a:colr.A];
	}

// Draw a line with blending enabled if a<255, using r,g,b,a
- (int) lineAtX:(int)x1 y:(int)y1 toX:(int)x2 y:(int)y2
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	if (x1 == x2)
		return [self _vLineFromY1:y1 toY2:y2 atX:x1 withR:r g:g b:b a:a];
	if (y1 == y2)
		return [self _hLineFromX1:x1 toX2:x2 atY:y1 withR:r g:g b:b a:a];
	if (_usingAntiAliasing)
		return [self _aaLineAtX:x1 y:y1 toX:x2 y:y2 withR:r g:g b:b a:a];
	int result = 0;
	if (a != 255)
		result |= [_renderer setBlendMode:SDL_BLENDMODE_BLEND];
	result |= [_renderer setDrawColourToRed:r g:g b:b a:a];
	result |= [_renderer renderLineFromX:x1 y:y1 toX:x2 y:y2];
	return result;
	}

// MARK: Rectangle drawing routines

/*****************************************************************************\
|* Rectangle routines
\*****************************************************************************/
- (int) rectangleWithRect:(NSRect)r colour:(AZColour *)colour
	{
	return [self rectangleAtX:(int)r.origin.x
							y:(int)r.origin.y
							w:(int)r.size.width
							h:(int)r.size.height
						withR:colour.R
							g:colour.G
							b:colour.B
							a:colour.A];
	}

- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h colour:(AZColour *)colour;
	{
	return [self rectangleAtX:(int)x
							y:(int)y
							w:(int)w
							h:(int)h
						withR:colour.R
							g:colour.G
							b:colour.B
							a:colour.A];
	}

- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	// Test for special cases of straight lines or single point
	if (w == 0)
		{
		if (h == 0)
			return [self pixelAtX:x y:y withR:r g:g b:b a:a];
		return [self _vLineFromY1:y toY2:y+h atX:x withR:r g:g b:b a:a];
		}
	else if (h == 0)
		return [self _hLineFromX1:x toX2:x+w atY:y withR:r g:g b:b a:a];


	// Deal with negative width
	if (w < 0)
		{
		x = x + w;
		w = -w;
		}

	// Deal with negative height
	if (h < 0)
		{
		y = y + h;
		h = -h;
		}

	// Draw
	int result = 0;
	if (a != 255)
		result |= [_renderer setBlendMode:SDL_BLENDMODE_BLEND];
	result |= [_renderer setDrawColourToRed:r g:g b:b a:a];
	result |= [_renderer renderRect:NSMakeRect(x,y,w,h)];
	return result;
	}


// MARK: Edge effects

/*****************************************************************************\
|* Rectangle routines (edge effects) : bezel
\*****************************************************************************/
- (void) rectangleWithBezel:(NSRect)r withClip:(NSRect)clip
	{
	NSRect originalClip = self.renderer.clipRect;
	NSRect intersection	= NSIntersectionRect(originalClip, clip);
	[self.renderer setClip:intersection];

	[self rectangleWithRect:r colour:AZColour.white];

	NSRect r2 = r;
	r2.size.width -= 1;
	r2.size.height -= 1;
	[self rectangleWithRect:r2 colour:AZColour.grey75];

	r2 = r;
	r2.origin.x += 1;
	r2.origin.y += 1;
	r2.size.width -= 3;
	r2.size.height -= 3;
	[self rectangleWithRect:r2 colour:AZColour.black];

	r2 = r;
	r2.origin.x += 2;
	r2.origin.y += 2;
	r2.size.width -= 3;
	r2.size.height -= 3;
	[self rectangleWithRect:r2 colour:AZColour.control];

	[self.renderer setClip:originalClip];
	}

/*****************************************************************************\
|* Rectangle routines (edge effects) : groove
\*****************************************************************************/
- (void) rectangleWithGroove:(NSRect)r withClip:(NSRect)clip
	{
	NSRect originalClip = self.renderer.clipRect;
	NSRect intersection	= NSIntersectionRect(originalClip, clip);
	[self.renderer setClip:intersection];

	[self rectangleWithRect:r colour:AZColour.grey75];

	NSRect r2 = r;
	r2.size.width += 1;
	r2.size.height += 1;
	[self rectangleWithRect:r2 colour:AZColour.white];

	r2 = r;
	r2.origin.x += 2;
	r2.origin.y += 2;
	r2.size.width -= 3;
	r2.size.height -= 3;
	[self rectangleWithRect:r2 colour:AZColour.grey75];

	r2 = r;
	r2.origin.x += 2;
	r2.origin.y += 2;
	r2.size.width -= 4;
	r2.size.height -= 4;
	[self rectangleWithRect:r2 colour:AZColour.control];

	[self.renderer setClip:originalClip];
	}

/*****************************************************************************\
|* Rectangle routines (edge effects) : button
\*****************************************************************************/
- (void) rectangleWithButton:(NSRect)r withClip:(NSRect)clip
	{
	NSRect originalClip = self.renderer.clipRect;
	NSRect intersection	= NSIntersectionRect(originalClip, clip);
	[self.renderer setClip:intersection];

	NSRect r2 = r;
	r2.origin.y += r.size.height -1;
	r2.size.height = 1;
	[self rectangleWithRect:r2 colour:AZColour.black];

	r2 = r;
	r2.origin.x += r.size.width -1;
	r2.size.width = 1;
	[self rectangleWithRect:r2 colour:AZColour.black];

	r2 = r;
	r2.origin.x += 1;
	r2.size.width -= 2;
	r2.origin.y += r.size.height - 2;
	r2.size.height = 1;
	[self rectangleWithRect:r2 colour:AZColour.grey25];

	r2 = r;
	r2.origin.x += r.size.width -2;
	r2.size.width = 1;
	r2.origin.y += 1;
	r2.size.height -= 2;
	[self rectangleWithRect:r2 colour:AZColour.grey25];

	r2 = r;
	r2.size.width -= 1;
	r2.size.height = 1;
	[self rectangleWithRect:r2 colour:AZColour.white];

	r2 = r;
	r2.size.width = 1;
	r2.size.height -= 1;
	[self rectangleWithRect:r2 colour:AZColour.white];

	r2 = r;
	r2.origin.x += 1;
	r2.size.width -= 3;
	r2.origin.y += 1;
	r2.size.height -= 3;
	[self rectangleWithRect:r2 colour:AZColour.control];

	[self.renderer setClip:originalClip];
	}

/*****************************************************************************\
|* Draw a rectangle using a series of dashes to make up a line
\*****************************************************************************/
- (void) rectangleInRect:(NSRect)rect
					 num:(int)num
				  dashes:(int *)onOff
				inColour:(AZColour *)colour
				withClip:(NSRect)clip
	{
	NSRect originalClip = self.renderer.clipRect;
	NSRect intersection	= NSIntersectionRect(originalClip, clip);
	[self.renderer setClip:intersection];

	// Start at top-left and work our way around, plotting lines as we go
	float x 	= rect.origin.x;
	float ox	= x;
	float y 	= rect.origin.y;
	float oy	= y;
	float x2	= x + rect.size.width  - 1;
	float y2	= x + rect.size.height - 1;

	uint8_t r	= colour.R;
	uint8_t g	= colour.G;
	uint8_t b	= colour.B;
	uint8_t a  	= colour.A;

	int len		= onOff[0];
	int dash  	= 0;
	BOOL draw	= YES;

	// Start at top-left and work our way around, plotting lines as we go
	while (x < x2)
		{
		int nx = MIN(x2, x+len);
		if (draw)
			[self lineAtX:x y:y toX:nx y:y withR:r g:g b:b a:a];
		int dx = x + len - x2;
		x = nx;
		if (dx > 0)
			{
			if (draw)
				[self lineAtX:x y:y toX:x y:y+dx withR:r g:g b:b a:a];
			y += dx;
			}

		dash ++;
		if (dash >= num)
			dash = 0;
		len = onOff[dash];

		draw = !draw;
		}

	// Do the RHS
	while (y < y2)
		{
		int ny = MIN(y2, y+len);
		if (draw)
			[self lineAtX:x y:y toX:x y:ny withR:r g:g b:b a:a];
		int dy = y + len - y2;
		y = ny;
		if (dy > 0)
			{
			if (draw)
				[self lineAtX:x y:y toX:x-dy y:y withR:r g:g b:b a:a];
			x -= dy;
			}

		dash ++;
		if (dash >= num)
			dash = 0;
		len = onOff[dash];

		draw = !draw;
		}

	// Do the bottom
	while (x > ox)
		{
		int nx = MAX(ox, x-len);
		if (draw)
			[self lineAtX:x y:y toX:nx y:y withR:r g:g b:b a:a];
		int dx = (x - len) - ox;
		x = nx;
		if (dx < 0)
			{
			if (draw)
				[self lineAtX:x y:y toX:x y:y-dx withR:r g:g b:b a:a];
			y -= dx;
			}

		dash ++;
		if (dash >= num)
			dash = 0;
		len = onOff[dash];

		draw = !draw;
		}

	// Do the LHS
	while (y > oy)
		{
		int ny = MAX(oy, y-len);
		if (draw)
			[self lineAtX:x y:y toX:x y:ny withR:r g:g b:b a:a];
		int dy = (y - len) - oy;
		y = ny;
		if (dy < 0)
			break;

		dash ++;
		if (dash >= num)
			dash = 0;
		len = onOff[dash];

		draw = !draw;
		}


	[self.renderer setClip:originalClip];
	}


// MARK: Rounded Rectangle drawing routines

/*****************************************************************************\
|* Rounded rectangle routines (not filled)
\*****************************************************************************/

// Draw rounded-corner rectangle with blending if a<255
- (int) rectangleWithRect:(NSRect)rect radius:(int)r colour:(AZColour *)colour
	{
	return [self rectangleAtX:(int)rect.origin.x
							y:(int)rect.origin.y
							w:(int)rect.size.width
							h:(int)rect.size.height
					   radius:r
						withR:colour.R
							g:colour.G
							b:colour.B
							a:colour.A];
	}

- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h radius:(int)r
		colour:(AZColour *)colour
	{
	return [self rectangleAtX:x
							y:y
							w:w
							h:h
					   radius:r
						withR:colour.R
							g:colour.G
							b:colour.B
							a:colour.A];
	}


- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h radius:(int)radius
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	int result = 0;

	// Radius sanity check
	if (radius < 0)
		return -1;

	// Special case - no rounding
	if (radius <= 1)
		return [self rectangleAtX:x y:y w:w h:h withR:r g:g b:b a:a];

	// Special case - straight lines or single point
	if (w == 0)
		{
		if (h == 0)
			return [self pixelAtX:x y:y withR:r g:g b:b a:a];
		return [self _vLineFromY1:y toY2:y+h atX:x withR:r g:g b:b a:a];
		}
	else if (h == 0)
		return [self _hLineFromX1:x toX2:x+w atY:y withR:r g:g b:b a:a];

	// Deal with negative width
	if (w < 0)
		{
		x = x + w;
		w = -w;
		}

	// Deal with negative height
	if (h < 0)
		{
		y = y + h;
		h = -h;
		}

	// Shrink the radius if it's too large
	if (radius * 2 > w)
		radius = w/2;
	if (radius * 2 > h)
		radius = h/2;

	// Draw corners
	int xx1 = x     + radius;
	int xx2 = x + w - radius;
	int yy1 = y     + radius;
	int yy2 = y + h - radius;

	[self arcAtX:xx1 y:yy1 radius:radius start:180 end:270 withR:r g:g b:b a:a];
	[self arcAtX:xx2 y:yy1 radius:radius start:270 end:360 withR:r g:g b:b a:a];
	[self arcAtX:xx1 y:yy2 radius:radius start: 90 end:180 withR:r g:g b:b a:a];
	[self arcAtX:xx2 y:yy2 radius:radius start:  0 end: 90 withR:r g:g b:b a:a];

	// Draw lines
	if (xx1 <= xx2)
		{
		result |= [self _hLineFromX1:xx1 toX2:xx2 atY:y   withR:r g:g b:b a:a];
		result |= [self _hLineFromX1:xx1 toX2:xx2 atY:y+h withR:r g:g b:b a:a];
		}

	if (yy1 <= yy2)
		{
		result |= [self _vLineFromY1:yy1 toY2:yy2 atX:x   withR:r g:g b:b a:a];
		result |= [self _vLineFromY1:yy1 toY2:yy2 atX:x+w withR:r g:g b:b a:a];
		}

	return result;
	}

// MARK: Filled rectangle drawing routines

/*****************************************************************************\
|* Filled rectangle routines
\*****************************************************************************/
- (int) rectangleWithRect:(NSRect)rect
				   filled:(BOOL)yn
				    withR:(uint8_t)r
				        g:(uint8_t)g
				        b:(uint8_t)b
				        a:(uint8_t)a
	{
	return [self rectangleAtX:(int)rect.origin.x
							y:(int)rect.origin.y
							w:(int)rect.size.width
							h:(int)rect.size.height
					   filled:yn
						withR:r
							g:g
							b:b
							a:a];
	}

/*****************************************************************************\
|* Filled rectangle routines
\*****************************************************************************/
- (int) rectangleWithRect:(NSRect)r filled:(BOOL)yn colour:(AZColour *)colour
	{
	return [self rectangleAtX:(int)r.origin.x
							y:(int)r.origin.y
							w:(int)r.size.width
							h:(int)r.size.height
					   filled:yn
						withR:colour.R
							g:colour.G
							b:colour.B
							a:colour.A];
	}

- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h filled:(BOOL)yn
	    colour:(AZColour *)colour
	{
	return [self rectangleAtX:x
							y:y
							w:w
							h:h
					   filled:yn
						withR:colour.R
							g:colour.G
							b:colour.B
							a:colour.A];
	}

- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h filled:(BOOL)yn
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	// Special case - straight lines or single point
	if (w == 0)
		{
		if (h == 0)
			return [self pixelAtX:x y:y withR:r g:g b:b a:a];
		return [self _vLineFromY1:y toY2:y+h atX:x withR:r g:g b:b a:a];
		}
	else if (h == 0)
		return [self _hLineFromX1:x toX2:x+w atY:y withR:r g:g b:b a:a];

	// Deal with negative width
	if (w < 0)
		{
		x = x + w;
		w = -w;
		}

	// Deal with negative height
	if (h < 0)
		{
		y = y + h;
		h = -h;
		}

	// Draw
	int result = 0;
	if (a != 255)
		result |= [_renderer setBlendMode:SDL_BLENDMODE_BLEND];
	result |= [_renderer setDrawColourToRed:r g:g b:b a:a];
	if (yn)
		result |= [_renderer renderFilledRect:NSMakeRect(x, y, w, h)];
	else
		result |= [_renderer renderRect:NSMakeRect(x, y, w, h)];
	return result;
	}


// MARK: Rounded filled rectangle drawing routines

/*****************************************************************************\
|* Rounded filled rectangle routines
\*****************************************************************************/
- (int) rectangleWithRect:(NSRect)r radius:(int)cornerRadius
		filled:(BOOL)yn colour:(AZColour *)colour
	{
	return [self rectangleAtX:(int)r.origin.x
							y:(int)r.origin.y
							w:(int)r.size.width
							h:(int)r.size.height
					   radius:cornerRadius
					   filled:yn
						withR:colour.R
							g:colour.G
							b:colour.B
							a:colour.A];
	}

- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h
		radius:(int)radius filled:(BOOL)yn colour:(AZColour *)colour
	{
	return [self rectangleAtX:x
							y:y
							w:w
							h:h
					   radius:radius
					   filled:yn
						withR:colour.R
							g:colour.G
							b:colour.B
							a:colour.A];
	}

- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h radius:(int)radius
		filled:(BOOL)yn withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	int result;
	Sint16 cx = 0;
	Sint16 cy = radius;
	Sint16 ocx = (Sint16) 0xffff;
	Sint16 ocy = (Sint16) 0xffff;
	Sint16 df = 1 - radius;
	Sint16 d_e = 3;
	Sint16 d_se = -2 * radius + 5;
	Sint16 xpcx, xmcx, xpcy, xmcy;
	Sint16 ypcy, ymcy, ypcx, ymcx;
	Sint16 dx, dy;

	// Radius sanity check
	if (radius < 0)
		return -1;

	// Special case - no rounding
	if (radius <= 1)
		return [self rectangleAtX:x y:y w:w h:h filled:yn withR:r g:g b:b a:a];

	// Special case - straight lines or single point
	if (w == 0)
		{
		if (h == 0)
			return [self pixelAtX:x y:y withR:r g:g b:b a:a];
		return [self _vLineFromY1:y toY2:y+h atX:x withR:r g:g b:b a:a];
		}
	else if (h == 0)
		return [self _hLineFromX1:x toX2:x+w atY:y withR:r g:g b:b a:a];

	// Deal with negative width
	if (w < 0)
		{
		x = x + w;
		w = -w;
		}

	// Deal with negative height
	if (h < 0)
		{
		y = y + h;
		h = -h;
		}

	// Shrink the radius if it's too large
	if (radius * 2 > w)
		radius = w/2;
	if (radius * 2 > h)
		radius = h/2;

	// Set up filled circle drawing for corners
	int xx = x + radius;
	int yy = y + radius;
	dx = w - radius - radius;
	dy = h - radius - radius;

	// Set color
	result = 0;
	if (a != 255)
		result |= [_renderer setBlendMode:SDL_BLENDMODE_BLEND];
	result |= [_renderer setDrawColourToRed:r g:g b:b a:a];

	// Draw corners
	do
		{
		xpcx = xx + cx;
		xmcx = xx - cx;
		xpcy = xx + cy;
		xmcy = xx - cy;
		if (ocy != cy)
			{
			if (cy > 0)
				{
				ypcy = yy + cy;
				ymcy = yy - cy;
				result |= [self _hLineFromX1:xmcx toX2:xpcx+dx atY:ypcy+dy];
				result |= [self _hLineFromX1:xmcx toX2:xpcx+dx atY:ymcy];
				}
			else
				result |= [self _hLineFromX1:xmcx toX2:xpcx+dx atY:yy];
			ocy = cy;
			}

		if (ocx != cx)
			{
			if (cx != cy)
				{
				if (cx > 0)
					{
					ypcx = yy + cx;
					ymcx = yy - cx;
					result |= [self _hLineFromX1:xmcy toX2:xpcy+dx atY:ymcx];
					result |= [self _hLineFromX1:xmcy toX2:xpcy+dx atY:ypcx + dy];
					}
				else
					result |= [self _hLineFromX1:xmcy toX2:xpcy+dx atY:yy];
				}
			ocx = cx;
			}

		// Update the pixels
		if (df < 0)
			{
			df   += d_e;
			d_e  += 2;
			d_se += 2;
			}
		else
			{
			df   += d_se;
			d_e  += 2;
			d_se += 4;
			cy--;
			}
		cx++;
		}
	while (cx <= cy);

	// Fill Inside
	if (yn)
		{
		if (dx > 0 && dy > 0)
			result |= [self rectangleAtX:x
									   y:y+radius+1
									   w:w
									   h:h-radius*2
								  filled:yn
								   withR:r
									   g:g
									   b:b
									   a:a];
		}
	else
		{
		result |= [_renderer renderFilledRect:NSMakeRect(x,y,radius,h)];
		result |= [_renderer renderFilledRect:NSMakeRect(x+w-radius,y,radius,h)];
		}

	return (result);
	}


// MARK: Circular arc drawing routines

/*****************************************************************************\
|* arc-of-circle routines (not filled)
|* 0 degrees is the X axis, extents are measured clockwise
\*****************************************************************************/
// Draw arc-of-circle, with blending if a<255
- (int) arcAtX:(int)x y:(int)y radius:(int)r start:(int)start end:(int)end
		colour:(AZColour *)colour
	{
	return [self arcAtX:x
					  y:y
				 radius:r
				  start:start
					end:end
				  withR:colour.R
					  g:colour.G
					  b:colour.B
					  a:colour.A];
	}

- (int) arcAtX:(int)x y:(int)y radius:(int)radius start:(int)start end:(int)end
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	// Radius sanity check
	if (radius < 0)
		return -1;

	// Special case - draw single point if radius == 0
	if (radius == 0)
		return [self pixelAtX:x y:y withR:r g:g b:b a:a];

	/*************************************************************************\
	|*  Octant labelling
	|*
	|*   \ 5 | 6 /
	|*    \  |  /
	|*   4 \ | / 7
	|*      \|/
	|* ------+------ +x
	|*      /|\
	|*   3 / | \ 0
	|*    /  |  \
	|*   / 2 | 1 \
	|*       +y
	|*
	|*  Initially reset bitmask to 0x00000000
	|*  the set whether or not to keep drawing a given octant.
	|*  For example: 0x00111100 means we're drawing in octants 2-5
	\*************************************************************************/
	int drawOct = 0;

	// Fix up any angle problems
	start %= 360;
	end   %= 360;

	// make sure 0 <= start & end < 360
	// note that sometimes start > end - if so, arc goes back through 0
	while (start < 0)
		start += 360;
	while (end < 0)
		end += 360;
	start %= 360;
	end   %= 360;

	// now, we find which octants we're drawing in.
	int startOct 	= start / 45;
	int endOct 		= end / 45;
	int oct 		= startOct - 1;

	// stopValStart, stopValEnd; what values of cx to stop at.
	int stopValStart = 0;
	int stopValEnd   = 0;
	double temp		 = 0.;

	do
		{
		double dStart;
		double dEnd;

		oct = (oct + 1) % 8;

		if (oct == startOct)
			{
			// need to compute stopValStart for this octant.
			// Look at picture above if this is unclear
			dStart = (double)start;
			switch (oct)
				{
				case 0:
				case 3:
					temp = SDL_sin(dStart * M_PI / 180.);
					break;
				case 1:
				case 6:
					temp = SDL_cos(dStart * M_PI / 180.);
					break;
				case 2:
				case 5:
					temp = -SDL_cos(dStart * M_PI / 180.);
					break;
				case 4:
				case 7:
					temp = -SDL_sin(dStart * M_PI / 180.);
					break;
				}
			temp *= radius;
			stopValStart = (int)temp;


			// This isn't arbitrary, but requires graph paper to explain well.
			// The basic idea is that we're always changing drawoct after we
			// draw, so we stop immediately after we render the last sensible
			// pixel at x = ((int)temp).
			// and whether to draw in this octant initially

			if (oct % 2)
				// this is basically like saying drawOct[oct] = true, if drawOct
				// were a bool array
				drawOct |= (1 << oct);
			else
				// this is basically like saying drawoct[oct] = false
				drawOct &= 255 - (1 << oct);
			}

		if (oct == endOct)
			{
			// need to compute stopValEnd for this octant...
			dEnd = (double)end;
			switch (oct)
				{
				case 0:
				case 3:
					temp = SDL_sin(dEnd * M_PI / 180);
					break;
				case 1:
				case 6:
					temp = SDL_cos(dEnd * M_PI / 180);
					break;
				case 2:
				case 5:
					temp = -SDL_cos(dEnd * M_PI / 180);
					break;
				case 4:
				case 7:
					temp = -SDL_sin(dEnd * M_PI / 180);
					break;
				}
			temp *= radius;
			stopValEnd = (int)temp;

			// ... and whether to draw in this octant initially
			if (startOct == endOct)
				{
				// note:      we start drawing, stop, then start again in this
				//            case
				// otherwise: we only draw in this octant, so initialize it to
				//            false, it will get set back to true
				if (start > end)
					{
					// unfortunately, if we're in the same octant and need to
					// draw over the whole circle, we need to set the rest to
					// true, because the while loop will end at the bottom.
					drawOct = 255;
					}
				else
					drawOct &= 255 - (1 << oct);

				}
			else if (oct % 2)
				drawOct &= 255 - (1 << oct);
			else
				drawOct |= (1 << oct);
			}
		else if (oct != startOct)
			{
			// already verified that it's != endoct so draw the entire segment
			drawOct |= (1 << oct);
			}
		}
	while (oct != endOct);


	// so now we have what octants to draw and when to draw them. all that's
	// left is the actual raster code.


	// Set color
	int result = 0;
	if (a != 255)
		result |= [_renderer setBlendMode:SDL_BLENDMODE_BLEND];
	result |= [_renderer setDrawColourToRed:r g:g b:b a:a];

	// Set up state
	int cx = 0;
	int cy = radius;
	int df = 1 - radius;
	int d_e = 3;
	int d_se = -2 * radius + 5;

	// Draw arc
	do
		{
		int ypcy = y + cy;
		int ymcy = y - cy;
		if (cx > 0)
			{
			int xpcx = x + cx;
			int xmcx = x - cx;

			// always check if we're drawing a certain octant before adding
			// a pixel to that octant.
			if (drawOct & 4)  result |= [self pixelAtX:xmcx y:ypcy];
			if (drawOct & 2)  result |= [self pixelAtX:xpcx y:ypcy];
			if (drawOct & 32) result |= [self pixelAtX:xmcx y:ymcy];
			if (drawOct & 64) result |= [self pixelAtX:xpcx y:ymcy];
			}
		else
			{
			if (drawOct & 96) result |= [self pixelAtX:x y:ymcy];
			if (drawOct &  6) result |= [self pixelAtX:x y:ypcy];
			}

		int xpcy = x + cy;
		int xmcy = x - cy;
		if (cx > 0 && cx != cy)
			{
			int ypcx = y + cx;
			int ymcx = y - cx;

			if (drawOct & 8)   result |= [self pixelAtX:xmcy y:ypcx];
			if (drawOct & 1)   result |= [self pixelAtX:xpcy y:ypcx];
			if (drawOct & 16)  result |= [self pixelAtX:xmcy y:ymcx];
			if (drawOct & 128) result |= [self pixelAtX:xpcy y:ymcx];
			}
		else if (cx == 0)
			{
			if (drawOct & 24)  result |= [self pixelAtX:xmcy y:y];
			if (drawOct & 129) result |= [self pixelAtX:xpcy y:y];
			}

		// Update whether we're drawing an octant
		if (stopValStart == cx)
			{
			// works like an on-off switch.
			// This is just in case start & end are in the same octant.
			if (drawOct & (1 << startOct))
				drawOct &= 255 - (1 << startOct);
			else
				drawOct |= (1 << startOct);
			}

		if (stopValEnd == cx)
			{
			if (drawOct & (1 << endOct))
				drawOct &= 255 - (1 << endOct);
			else
				drawOct |= (1 << endOct);
			}

		// Update pixels
		if (df < 0)
			{
			df   += d_e;
			d_e  += 2;
			d_se += 2;
			}
		else
			{
			df   += d_se;
			d_e  += 2;
			d_se += 4;
			cy--;
			}

		cx++;
		}
	while (cx <= cy);

	return result;
	}

/*****************************************************************************\
|* Circular arc drawing routines (filled)
\*****************************************************************************/
- (int) pieAtX:(int)x y:(int)y radius:(int)radius start:(int)start end:(int)end
		filled:(BOOL)yn colour:(AZColour *)colour
	{
		return [self pieAtX:x
		                  y:y
					 radius:radius
					  start:start
					    end:end
					 filled:yn
					  withR:colour.R
						  g:colour.G
						  b:colour.B
						  a:colour.A];
	}

- (int) pieAtX:(int)x y:(int)y radius:(int)radius start:(int)start end:(int)end
		filled:(BOOL)yn withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	// Radius sanity check
	if (radius < 0)
		return -1;

	// Fix up any angle problems
	start %= 360;
	end   %= 360;

	// Special case for rad=0 - draw a point
	if (radius == 0)
		return [self pixelAtX:x y:y withR:r g:g b:b a:a];

	// Variable setup
	double dr 			= (double) radius;
	double deltaAngle 	= 3.0 / dr;
	double startAngle 	= (double) start *(2.0 * M_PI / 360.0);
	double endAngle 	= (double) end *(2.0 * M_PI / 360.0);
	if (start > end)
		endAngle += (2.0 * M_PI);

	// We will always have at least 2 points
	int numpoints = 2;

	// Count points (rather than calculating it)
	double angle = startAngle;
	while (angle < endAngle)
		{
		angle += deltaAngle;
		numpoints++;
		}

	// Allocate combined vertex array
	int *vx = (int *) malloc(2 * sizeof(int) * numpoints);
	if (vx == NULL)
		return (-1);
	int *vy = vx + numpoints;

	// Center
	vx[0] = x;
	vy[0] = y;

	// First vertex
	angle = startAngle;
	vx[1] = x + (int) (dr * SDL_cos(angle));
	vy[1] = y + (int) (dr * SDL_sin(angle));

	int result = 0;
	if (numpoints<3)
		result |= [self lineAtX:vx[0] y:vy[0] toX:vx[1] y:vy[1]
						  withR:r g:g b:b a:a];
	else
		{
		// Calculate other vertices
		int i = 2;
		angle = startAngle;
		while (angle < endAngle)
			{
			angle += deltaAngle;
			if (angle > endAngle)
				angle = endAngle;

			vx[i] = x + (int) (dr * SDL_cos(angle));
			vy[i] = y + (int) (dr * SDL_sin(angle));
			i++;
			}

		// Draw
		result = [self polygonWith:numpoints
								 x:vx
								 y:vy
							filled:yn
							 withR:r
								 g:g
								 b:b
								 a:a];

		}

	// Free combined vertex array
	free(vx);
	return result;
	}

// MARK: circle drawing routines

/*****************************************************************************\
|* circle routines (not filled)
\*****************************************************************************/
- (int) circleAtX:(int)x y:(int)y r:(int)rx colour:(AZColour *)colour
	{
	return [self ellipseAtX:x
						  y:y
						 rx:rx
						 ry:rx
					  withR:colour.R
						  g:colour.G
						  b:colour.B
						  a:colour.A];
	}

- (int) circleAtX:(int)x y:(int)y r:(int)rx
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	return [self ellipseAtX:x y:y rx:rx ry:rx withR:r g:g b:b a:a];
	}

/*****************************************************************************\
|* circle routines (filled)
\*****************************************************************************/
- (int) circleAtX:(int)x y:(int)y r:(int)rx filled:(BOOL)yn
	    colour:(AZColour *)colour
	{
	return [self ellipseAtX:x
						  y:y
						 rx:rx
						 ry:rx
					 filled:yn
					  withR:colour.R
						  g:colour.G
						  b:colour.B
						  a:colour.A];
	}

- (int) circleAtX:(int)x y:(int)y r:(int)rx filled:(BOOL)yn
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	return [self ellipseAtX:x y:y rx:rx ry:rx filled:yn withR:r g:g b:b a:a];
	}

// MARK: ellipse drawing routines

/*****************************************************************************\
|* ellipse routines (not filled)
\*****************************************************************************/
- (int) ellipseWithRect:(NSRect)r colour:(AZColour *)colour;
	{
	int xr = r.size.width/2;
	int yr = r.size.height/2;
	int xc = r.origin.x + xr;
	int yc = r.origin.x + yr;

	return [self ellipseAtX:xc
						  y:yc
						 rx:xr
						 ry:yr
					  withR:colour.R
					      g:colour.G
					      b:colour.B
					      a:colour.A];
	}

- (int) ellipseAtX:(int)x y:(int)y rx:(int)xr ry:(int)yr
		colour:(AZColour *)colour
	{
	return [self ellipseAtX:x
						  y:y
						 rx:xr
						 ry:yr
					  withR:colour.R
					      g:colour.G
					      b:colour.B
					      a:colour.A];
	}

- (int) ellipseAtX:(int)x y:(int)y rx:(int)rx ry:(int)ry
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	int h, i, j, k;
	int xmh, xph, ypk, ymk;
	int xmi, xpi, ymj, ypj;
	int xmj, xpj, ymi, ypi;
	int xmk, xpk, ymh, yph;

	// Sanity check radii
	if ((rx < 0) || (ry < 0))
		return (-1);

	// Special case for rx=0 - draw a vline
	if (rx == 0)
		return [self _vLineFromY1:y-ry toY2:y+ry atX:x withR:r g:g b:b a:a];

	// Special case for ry=0 - draw a hline
	if (ry == 0)
		return [self _hLineFromX1:x-rx toX2:x+rx atY:y withR:r g:g b:b a:a];

	// Check for anti-aliasing
	if (_usingAntiAliasing)
		return [self _aaEllipseAtX:x y:y rx:rx ry:ry withR:r g:g b:b a:a];

	// Set color
	int result = 0;
	if (a != 255)
		result |= [_renderer setBlendMode:SDL_BLENDMODE_BLEND];
	result |= [_renderer setDrawColourToRed:r g:g b:b a:a];

	// Init vars
	int oh = 0xffff;
	int oi = 0xffff;
	int oj = 0xffff;
	int ok = 0xffff;

	// Draw
	if (rx > ry)
		{
		int ix = 0;
		int iy = rx * 64;

		do
			{
			h = (ix + 32) >> 6;
			i = (iy + 32) >> 6;
			j = (h * ry) / rx;
			k = (i * ry) / rx;

			if (((ok != k) && (oj != k)) || ((oj != j) && (ok != j)) || (k != j))
				{
				xph = x + h;
				xmh = x - h;
				if (k > 0)
					{
					ypk = y + k;
					ymk = y - k;
					result |= [self pixelAtX:xmh y:ypk];
					result |= [self pixelAtX:xph y:ypk];
					result |= [self pixelAtX:xmh y:ymk];
					result |= [self pixelAtX:xph y:ymk];
					}
				else
					{
					result |= [self pixelAtX:xmh y:y];
					result |= [self pixelAtX:xph y:y];
					}
				ok = k;
				xpi = x + i;
				xmi = x - i;
				if (j > 0)
					{
					ypj = y + j;
					ymj = y - j;
					result |= [self pixelAtX:xmi y:ypj];
					result |= [self pixelAtX:xpi y:ypj];
					result |= [self pixelAtX:xmi y:ymj];
					result |= [self pixelAtX:xpi y:ymj];
					}
				else
					{
					result |= [self pixelAtX:xmi y:y];
					result |= [self pixelAtX:xpi y:y];
					}
				oj = j;
				}

			ix = ix + iy / rx;
			iy = iy - ix / rx;
			}
		while (i > h);
		}
	else
		{
		int ix = 0;
		int iy = ry * 64;

		do
			{
			h = (ix + 32) >> 6;
			i = (iy + 32) >> 6;
			j = (h * rx) / ry;
			k = (i * rx) / ry;

			if (((oi != i) && (oh != i)) || ((oh != h) && (oi != h) && (i != h)))
				{
				xmj = x - j;
				xpj = x + j;
				if (i > 0)
					{
					ypi = y + i;
					ymi = y - i;
					result |= [self pixelAtX:xmj y:ypi];
					result |= [self pixelAtX:xpj y:ypi];
					result |= [self pixelAtX:xmj y:ymi];
					result |= [self pixelAtX:xpj y:ymi];
					}
				else
					{
					result |= [self pixelAtX:xmj y:y];
					result |= [self pixelAtX:xpj y:y];
					}

				oi = i;
				xmk = x - k;
				xpk = x + k;
				if (h > 0)
					{
					yph = y + h;
					ymh = y - h;
					result |= [self pixelAtX:xmk y:yph];
					result |= [self pixelAtX:xpk y:yph];
					result |= [self pixelAtX:xmk y:ymh];
					result |= [self pixelAtX:xpk y:ymh];
					}
				else
					{
					result |= [self pixelAtX:xmk y:y];
					result |= [self pixelAtX:xpk y:y];
					}
				oh = h;
				}

			ix = ix + iy / ry;
			iy = iy - ix / ry;

			}
		while (i > h);
		}

	return result;
	}


/*****************************************************************************\
|* ellipse routines (filled)
\*****************************************************************************/
- (int) ellipseWithRect:(NSRect)r filled:(BOOL)yn colour:(AZColour *)colour
	{
	int xr = r.size.width/2;
	int yr = r.size.height/2;
	int xc = r.origin.x + xr;
	int yc = r.origin.x + yr;

	return [self ellipseAtX:xc
						  y:yc
						 rx:xr
						 ry:yr
					 filled:yn
					  withR:colour.R
					      g:colour.G
					      b:colour.B
					      a:colour.A];
	}

- (int) ellipseAtX:(int)x y:(int)y rx:(int)rx ry:(int)ry
		filled:(BOOL)yn colour:(AZColour *)colour
	{
	return [self ellipseAtX:x
						  y:y
						 rx:rx
						 ry:ry
					 filled:yn
					  withR:colour.R
					      g:colour.G
					      b:colour.B
					      a:colour.A];
	}

- (int) ellipseAtX:(int)x y:(int)y rx:(int)rx ry:(int)ry filled:(BOOL)yn
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	int ix, iy;
	int h, i, j, k;
	int xmh, xph;
	int xmi, xpi;
	int xmj, xpj;
	int xmk, xpk;

	// Check we're actually filling the ellipse
	if (!yn)
		return [self ellipseAtX:x y:y rx:rx ry:ry withR:r g:g b:b a:a];

	// Radius sanity check
	if ((rx < 0) || (ry < 0))
		return -1;

	// Special case for rx=0 - draw a vline
	if (rx == 0)
		return [self _vLineFromY1:y-ry toY2:y+ry atX:x withR:r g:g b:b a:a];

	// Special case for ry=0 - draw a hline
	if (ry == 0)
		return [self _hLineFromX1:x-rx toX2:x+rx atY:y withR:r g:g b:b a:a];

	// Set color
	int result = 0;
	if (a != 255)
		result |= [_renderer setBlendMode:SDL_BLENDMODE_BLEND];
	result |= [_renderer setDrawColourToRed:r g:g b:b a:a];

	// Init vars
	int oh = 0xffff;
	int oi = 0xffff;
	int oj = 0xffff;
	int ok = 0xffff;

	// Draw
	if (rx > ry)
		{
		ix = 0;
		iy = rx * 64;

		do
			{
			h = (ix + 32) >> 6;
			i = (iy + 32) >> 6;
			j = (h * ry) / rx;
			k = (i * ry) / rx;

			if ((ok != k) && (oj != k))
				{
				xph = x + h;
				xmh = x - h;
				if (k > 0)
					{
					result |= [self _hLineFromX1:xmh toX2:xph atY:y+k];
					result |= [self _hLineFromX1:xmh toX2:xph atY:y-k];
					}
				else
					result |= [self _hLineFromX1:xmh toX2:xph atY:y];
				ok = k;
				}

			if ((oj != j) && (ok != j) && (k != j))
				{
				xmi = x - i;
				xpi = x + i;
				if (j > 0)
					{
					result |= [self _hLineFromX1:xmi toX2:xpi atY:y+j];
					result |= [self _hLineFromX1:xmi toX2:xpi atY:y-j];
					}
				else
					result |= [self _hLineFromX1:xmi toX2:xpi atY:y];

				oj = j;
				}

			ix = ix + iy / rx;
			iy = iy - ix / rx;
			}
		while (i > h);
		}
	else
		{
		ix = 0;
		iy = ry * 64;

		do
			{
			h = (ix + 32) >> 6;
			i = (iy + 32) >> 6;
			j = (h * rx) / ry;
			k = (i * rx) / ry;

			if ((oi != i) && (oh != i))
				{
				xmj = x - j;
				xpj = x + j;
				if (i > 0)
					{
					result |= [self _hLineFromX1:xmj toX2:xpj atY:y+i];
					result |= [self _hLineFromX1:xmj toX2:xpj atY:y-i];
					}
				else
					result |= [self _hLineFromX1:xmj toX2:xpj atY:y];

				oi = i;
				}

			if ((oh != h) && (oi != h) && (i != h))
				{
				xmk = x - k;
				xpk = x + k;
				if (h > 0)
					{
					result |= [self _hLineFromX1:xmk toX2:xpk atY:y+h];
					result |= [self _hLineFromX1:xmk toX2:xpk atY:y-h];
					}
				else
					result |= [self _hLineFromX1:xmk toX2:xpk atY:y];

				oh = h;
				}

			ix = ix + iy / ry;
			iy = iy - ix / ry;
			}
		while (i > h);
		}

	return result;
	}


// MARK: Triangle drawing methods

/*****************************************************************************\
|* Draw a coloured triangle (not filled)
\*****************************************************************************/

- (int) triangleWithX:(int)x1 y:(int)y1 x:(int)x2 y:(int)y2 x:(int)x3 y:(int)y3
		colour:(AZColour *)colour
	{
	int xc[3] = {x1, x2, x3};
	int yc[3] = {y1, y2, y3};

	return [self polygonWith:3
						   x:xc
						   y:yc
					   withR:colour.R
						   g:colour.G
						   b:colour.B
						   a:colour.A];
	}

- (int) triangleWithX:(int)x1 y:(int)y1 x:(int)x2 y:(int)y2 x:(int)x3 y:(int)y3
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	int xc[3] = {x1, x2, x3};
	int yc[3] = {y1, y2, y3};

	// Anti-aliasing taken care of in the _polygonWith... call
	return [self polygonWith:3 x:xc y:yc withR:r g:g b:b a:a];
	}


/*****************************************************************************\
|* Draw a coloured triangle (filled)
\*****************************************************************************/
- (int) triangleWithX:(int)x1 y:(int)y1 x:(int)x2 y:(int)y2 x:(int)x3 y:(int)y3
		filled:(BOOL)yn colour:(AZColour *)colour
	{
	int xc[3] = {x1, x2, x3};
	int yc[3] = {y1, y2, y3};

	return [self polygonWith:3
						   x:xc
						   y:yc
					  filled:yn
					   withR:colour.R
						   g:colour.G
						   b:colour.B
						   a:colour.A];
	}

- (int) triangleWithX:(int)x1 y:(int)y1 x:(int)x2 y:(int)y2 x:(int)x3 y:(int)y3
		filled:(BOOL)yn withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	int xc[3] = {x1, x2, x3};
	int yc[3] = {y1, y2, y3};

	return [self polygonWith:3
						   x:xc
						   y:yc
					  filled:yn
					   withR:r
						   g:g
						   b:b
						   a:a];
	}


// MARK: Polygon drawing methods


/*****************************************************************************\
|* Provide a list of points to draw, non-alpha-blended, not anti-aliased
\*****************************************************************************/
- (int) polygonWith:(int)num points:(NSPoint*)pts
	{
	// Vertex array NULL check
	if (pts == NULL)
		return (-1);

	// Sanity check
	if (num < 3)
		return (-1);

	// Create array of points
	NSPoint points[num+1];
	int nn = num + 1;

	for (int i=0; i<num; i++)
		{
		points[i].x = pts[i].x;
		points[i].y = pts[i].y;
		}
	points[num].x = pts[0].x;
	points[num].y = pts[0].y;

	// Draw
	return [_renderer renderLines:points count:nn];
	}

- (int) polygonWith:(int)num x:(int *)vx y:(int *)vy
	{
	// Vertex array NULL check
	if (vx == NULL)
		return (-1);

	if (vy == NULL)
		return (-1);

	// Sanity check
	if (num < 3)
		return (-1);

	// Create array of points
	NSPoint points[num+1];
	int nn = num + 1;

	for (int i=0; i<num; i++)
		{
		points[i].x = vx[i];
		points[i].y = vy[i];
		}
	points[num].x = vx[0];
	points[num].y = vy[0];

	// Draw
	return [_renderer renderLines:points count:nn];
	}

/*****************************************************************************\
|* Provide a list of points to draw, alpha-blended
\*****************************************************************************/
- (int) polygonWith:(int)num x:(int *)vx y:(int *)vy
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	// Vertex array NULL check
	if (vx == NULL)
		return (-1);

	if (vy == NULL)
		return (-1);

	// Sanity check
	if (num < 3)
		return (-1);

	// Set color
	int result = 0;
	if (a != 255)
		result |= [_renderer setBlendMode:SDL_BLENDMODE_BLEND];
	result |= [_renderer setDrawColourToRed:r g:g b:b a:a];

	// Draw
	return [self _polygonWith:num vx:vx vy:vy withR:r g:g b:b a:a];
	}

/*****************************************************************************\
|* Filled polygon drawing.
\*****************************************************************************/
- (int) polygonWith:(int)num x:(int *)vx y:(int *)vy filled:(BOOL)yn
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	if (!yn)
		return [self polygonWith:num x:vx y:vy withR:r g:g b:b a:a];

	// Vertex array NULL check
	if (vx == NULL)
		return (-1);

	if (vy == NULL)
		return (-1);

	// Sanity check
	if (num < 3)
		return (-1);

	// Set up the polygon cache. Only grow the cache
	if (!_polyIntsSize)
		{
		_polyInts 		= (int *) malloc(sizeof(int) * num);
		_polyIntsSize 	= num;
		}
	else
		{
		if (_polyIntsSize < num)
			{
			int * polyIntsNew = (int *) realloc(_polyInts, sizeof(int) * num);
			if (!polyIntsNew)
				{
				if (_polyInts)
					{
					free(_polyInts);
					_polyInts = NULL;
					}
				_polyIntsSize = 0;
				}
			else
				{
				_polyInts = polyIntsNew;
				_polyIntsSize = num;
				}
			}
		}

	// Check temp array size
	if (_polyInts == NULL)
		_polyIntsSize = 0;

	// Sanity check
	if (_polyInts == NULL)
		return(-1);

	// Determine Y minima, maxima
	int miny = vy[0];
	int maxy = vy[0];
	for (int i = 1; (i < num); i++)
		if (vy[i] < miny)
			miny = vy[i];
		else if (vy[i] > maxy)
			maxy = vy[i];

	// Draw, scanning y
	int result = 0;
	for (int y = miny; (y <= maxy); y++)
		{
		int ints = 0;
		for (int i = 0; i < num; i++)
			{
			int ind1 = (!i) ? num-1 : i-1;
			int ind2 = (!i) ? 0     : i;
			int x1, x2;

			int y1 = vy[ind1];
			int y2 = vy[ind2];
			if (y1 < y2)
				{
				x1 = vx[ind1];
				x2 = vx[ind2];
				}
			else if (y1 > y2)
				{
				y2 = vy[ind1];
				y1 = vy[ind2];
				x2 = vx[ind1];
				x1 = vx[ind2];
				}
			else
				continue;

			if ( ((y >= y1) && (y < y2)) || ((y == maxy) && (y > y1) && (y <= y2)) )
				_polyInts[ints++] = ((65536 * (y - y1)) / (y2 - y1))
								   * (x2 - x1) + (65536 * x1);

			}

		qsort(_polyInts, ints, sizeof(int), _qsortInts);

		// Set color
		result = 0;
	    if (a != 255)
			result |= [_renderer setBlendMode:SDL_BLENDMODE_BLEND];
		result |= [_renderer setDrawColourToRed:r g:g b:b a:a];

		for (int i = 0; (i < ints); i += 2)
			{
			int xa 	= _polyInts[i] + 1;
			xa 		= (xa >> 16) + ((xa & 32768) >> 15);
			int xb 	= _polyInts[i+1] - 1;
			xb 		= (xb >> 16) + ((xb & 32768) >> 15);
			result |= [self _hLineFromX1:xa toX2:xb atY:y];
			}
		}

	return result;
	}


/*****************************************************************************\
|* Textured polygon drawing.
\*****************************************************************************/
- (int) texturedPolygonWith:(int)num x:(int *)vx y:(int *)vy
		texture:(SDL_Surface *)surface textureDx:(int)tdx textureDy:(int)tdy
	{
	int x1, y1;
	int x2, y2;
	int ints;

	// Vertex array NULL check
	if (vx == NULL)
		return (-1);

	if (vy == NULL)
		return (-1);

	// Sanity check
	if (num < 3)
		return (-1);

	// Set up the polygon cache. Only grow the cache
	if (!_polyIntsSize)
		{
		_polyInts 		= (int *) malloc(sizeof(int) * num);
		_polyIntsSize 	= num;
		}
	else
		{
		if (_polyIntsSize < num)
			{
			int * polyIntsNew = (int *) realloc(_polyInts, sizeof(int) * num);
			if (!polyIntsNew)
				{
				if (_polyInts)
					{
					free(_polyInts);
					_polyInts = NULL;
					}
				_polyIntsSize = 0;
				}
			else
				{
				_polyInts = polyIntsNew;
				_polyIntsSize = num;
				}
			}
		}

	// Check temp array size
	if (_polyInts == NULL)
		_polyIntsSize = 0;

	// Sanity check
	if (_polyInts == NULL)
		return(-1);

	// Determine Y minima, maxima
	int minx = vx[0];
	int maxx = vx[0];
	int miny = vy[0];
	int maxy = vy[0];
	for (int i = 1; (i < num); i++)
		{
		if (vy[i] < miny)
			miny = vy[i];
		else if (vy[i] > maxy)
			maxy = vy[i];
		if (vx[i] < minx)
			minx = vx[i];
		else if (vx[i] > maxx)
			maxx = vx[i];
		}

    // Create texture for drawing
	NSInteger texture = [_renderer createTextureWithSurface:surface];
	if (texture < 0)
		return -1;

	[_renderer setTexture:texture blendMode:SDL_BLENDMODE_BLEND];

	// Draw, scanning y

	int result = 0;
	for (int y = miny; y <= maxy; y++)
		{
		ints = 0;
		for (int i = 0; (i < num); i++)
			{
			int ind1 = (!i) ? num-1 : i-1;
			int ind2 = (!i) ? 0     : i;

			y1 = vy[ind1];
			y2 = vy[ind2];
			if (y1 < y2)
				{
				x1 = vx[ind1];
				x2 = vx[ind2];
				}
			else if (y1 > y2)
				{
				y2 = vy[ind1];
				y1 = vy[ind2];
				x2 = vx[ind1];
				x1 = vx[ind2];
				}
			else
				continue;

			if (((y >= y1) && (y < y2)) || ((y == maxy) && (y > y1) && (y <= y2)))
				_polyInts[ints++] = ((65536 * (y - y1)) / (y2 - y1))
								  * (x2 - x1) + (65536 * x1);
			}

		qsort(_polyInts, ints, sizeof(int), _qsortInts);

		for (int i = 0; (i < ints); i += 2)
			{
			int xa = _polyInts[i] + 1;
			    xa = (xa >> 16) + ((xa & 32768) >> 15);
			int xb = _polyInts[i+1] - 1;
			    xb = (xb >> 16) + ((xb & 32768) >> 15);
			result |= [self _texturedHLineAtX:xa
										  toX:xb
										  atY:y
									  texture:texture
									 textureW:surface->w
									 textureH:surface->h
									textureDx:tdx
									textureDy:tdy];
			}
		}

	[AZApp registerTextureForDisposal:@(texture)];

	return (result);
	}


// MARK: Bezier curves

/*****************************************************************************\
|* Bezier curve enumeration
\*****************************************************************************/
- (int) bezierWithPoints:(int)num x:(float *)xc y:(float *)yc steps:(int)steps
		colour:(AZColour *)colour
	{
	return [self bezierWithPoints:num
								x:xc
								y:yc
							steps:steps
							withR:colour.R
								g:colour.G
								b:colour.B
								a:colour.A];
	}

/*****************************************************************************\
|* Bezier curve line draw
\*****************************************************************************/
- (int) bezierWithPoints:(int)num x:(float *)vx y:(float *)vy steps:(int)steps
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	return [self bezierWithPoints:num x:vx y:vy steps:steps
							withR:r g:g b:b a:a filled:NO];
	}

/*****************************************************************************\
|* Bezier curve line draw or fill
\*****************************************************************************/
- (int) bezierWithPoints:(int)num x:(float *)vx y:(float *)vy steps:(int)steps
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
		filled:(BOOL)fill
	{
	float *x, *y;

	// Sanity check
	if (num < 3)
		return (-1);

	if (steps < 2)
		return (-1);

	// Variable setup
	float stepsize = 1.f/(float)steps;

	/* Transfer vertices into float arrays */
	if ((x=(float *)SDL_malloc(sizeof(float)*(num+1))) == NULL)
		return(-1);

	if ((y=(float *)SDL_malloc(sizeof(float)*(num+1))) == NULL)
		{
		SDL_free(x);
		return(-1);
		}

	for (int i=0; i < num; i++)
		{
		x[i] = vx[i];
		y[i] = vy[i];
		}

	x[num] = vx[0];
	y[num] = vy[0];

	// Set color
	int result = 0;
	if (a != 255)
		result |= [_renderer setBlendMode:SDL_BLENDMODE_BLEND];
	result |= [_renderer setDrawColourToRed:r g:g b:b a:a];

	// Draw
	int idx 	= 1;
	float t		= 0.f;
	int total 	= num * steps + 1;

	int px[total], py[total];
	px[0] = (int)SDL_round(_evaluateBezier(x,num+1,t));
	py[0] = (int)SDL_round(_evaluateBezier(y,num+1,t));

	for (int i = 0; i <= total; i++)
		{
		t += stepsize;
		px[idx] = (int)_evaluateBezier(x,num,t);
		py[idx] = (int)_evaluateBezier(y,num,t);
		idx ++;
		}

	if (fill)
		{
		[self polygonWith:idx x:px y:py filled:YES withR:r g:g b:b a:a];
		}
	else
		{
		for (int i=0; i<total; i++)
			[self lineAtX:px[i] y:py[i] toX:px[i+1] y:py[i+1]
				  withR:r g:g b:b a:a];
		}

	// Clean up temporary array
	SDL_free(x);
	SDL_free(y);

	return (result);
	}



// MARK: Text drawing

/*****************************************************************************\
|* Set the font to use
\*****************************************************************************/
- (void) setFont:(AZFont *)font
	{
	_textPainter.font = font;
	}


/*****************************************************************************\
|* Set text colour, separate from drawing colour
\*****************************************************************************/
- (void) setTextColour:(AZColour *)colour
	{
	_textPainter.colour = colour;
	}

- (void) setTextColourWithR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	AZColour *colour = [AZColour colourWithByteR:r g:g b:b a:a];
	_textPainter.colour = colour;
	}

/*****************************************************************************\
|* Set horizontal text alignment
\*****************************************************************************/
- (void) setTextAlignment:(AZTextAlignment)align
	{
	_textPainter.alignment = align;
	}

/*****************************************************************************\
|* Set text angle (cardinal angles only for now, 0, 90, 180, 270)
\*****************************************************************************/
- (void) setTextAngle:(int)degrees
	{
	_textPainter.angle = degrees;
	}

/*****************************************************************************\
|* Set text scale (for effects, use different sized fonts for "normal" use)
\*****************************************************************************/
- (void) setTextScale:(AZScale)scale
	{
	_textPainter.scale = scale;
	}

/*****************************************************************************\
|* Text drawing
\*****************************************************************************/
- (NSRect) textAtX:(float)x y:(float)y text:(NSString *)text
	{
	return [_textPainter drawAtX:x y:y text:text];
	}

- (NSRect) textAtX:(float)x y:(float)y format:(NSString *)fmt, ...
	{
	EXTRACT_VARARGS(text, fmt);
	return [_textPainter drawAtX:x y:y text:text];
	}

- (NSRect) textInBox:(NSRect)box text:(NSString *)text
	{
	return [_textPainter drawInBox:box text:text];
	}

- (NSRect) textInBox:(NSRect)box format:(NSString *)fmt, ...
	{
	EXTRACT_VARARGS(text, fmt);
	return [_textPainter drawInBox:box text:text];
	}

- (NSRect) textColumnsInBox:(NSRect)box text:(NSString *)text
	{
	return [_textPainter drawColumnsInBox:box text:text];
	}

- (NSRect) textColumnsInBox:(NSRect)box format:(NSString *)fmt, ...
	{
	EXTRACT_VARARGS(text, fmt);
	return [_textPainter drawColumnsInBox:box text:text];
	}


// MARK: Images

/*****************************************************************************\
|* Draw an image at a point
\*****************************************************************************/
- (void) image:(AZImage *)img at:(NSPoint)xy
	{
	id<AZRenderer> azr	= AZRenderer.renderer;
	if (img.handler != nil)
		[img draw];

	NSRect srcRect = img.srcRect;
	NSRect dstRect = srcRect;
	dstRect.origin = xy;

	[azr blitFrom:img.texture src:srcRect dst:dstRect];
	}

/*****************************************************************************\
|* Draw part of an image to a point
\*****************************************************************************/
- (void) image:(AZImage *)img from:(NSRect)srcRect at:(NSPoint)p
	{
	// Make sure we have a reasonable srcRect. The image srcRect is possibly
	// from an Atlas texture (else its origin will be at 0,0) so add in the
	// origin of the image srcRect to the requested srcRect before taking
	// the intersection
	srcRect.origin.x += NSMinX(img.srcRect);
	srcRect.origin.y += NSMinY(img.srcRect);
	NSRect clipped    = NSIntersectionRect(img.srcRect, srcRect);
	if ((NSWidth(clipped) == 0) || (NSHeight(clipped) == 0))
		return;

	NSRect dstRect = clipped;
	dstRect.origin = p;

	id<AZRenderer> azr	= AZRenderer.renderer;
	if (img.handler != nil)
		[img draw];
	[azr blitFrom:img.texture src:clipped dst:dstRect];
	}

/*****************************************************************************\
|* Draw an image into a rectangle
\*****************************************************************************/
- (void) image:(AZImage *)img to:(NSRect)dstRect
	{
	id<AZRenderer> azr	= AZRenderer.renderer;
	if (img.handler != nil)
		[img draw];
	NSRect srcRect = img.srcRect;
	[azr blitFrom:img.texture src:srcRect dst:dstRect];
	}

/*****************************************************************************\
|* Draw part of an image into a rectangle
\*****************************************************************************/
- (void) image:(AZImage *)img from:(NSRect)srcRect to:(NSRect)dstRect;
	{
	// Make sure we have a reasonable srcRect. The image srcRect is possibly
	// from an Atlas texture (else its origin will be at 0,0) so add in the
	// origin of the image srcRect to the requested srcRect before taking
	// the intersection
	srcRect.origin.x += NSMinX(img.srcRect);
	srcRect.origin.y += NSMinY(img.srcRect);
	NSRect clipped    = NSIntersectionRect(img.srcRect, srcRect);
	if ((NSWidth(clipped) == 0) || (NSHeight(clipped) == 0))
		return;

	id<AZRenderer> azr	= AZRenderer.renderer;
	if (img.handler != nil)
		[img draw];
	[azr blitFrom:img.texture src:clipped dst:dstRect];
	}

/*****************************************************************************\
|* Draw an image at a point with a rotation about a point, possibly flipped.
|* The point is specifed relative to the center of the image srcRect.
|* the flipMask is
\*****************************************************************************/
- (void) image:(AZImage *)img
			at:(NSPoint)xy
		 angle:(int)degrees
		 about:(NSPoint)center
		  flip:(AZFlipMode)flipMask
	{
	id<AZRenderer> azr	= AZRenderer.renderer;

	NSRect srcRect = img.srcRect;
	NSRect dstRect = srcRect;
	dstRect.origin = xy;

	NSPoint cxy		= NSMakePoint(center.x + srcRect.size.width / 2.f,
								  center.y + srcRect.size.height/ 2.f);

	if (img.handler != nil)
		[img draw];
	[azr blitFrom:img.texture
			  src:srcRect
			  dst:dstRect
			angle:degrees
		   center:cxy
		     flip:flipMask];
	}

/*****************************************************************************\
|* Draw a subset of an image with a rotation about a point, possibly flipped
|* The point is specifed relative to the center of the image srcRect.
\*****************************************************************************/
- (void) image:(AZImage *)img
		  from:(NSRect)srcRect
			at:(NSPoint)xy
		 angle:(int)degrees
		 about:(NSPoint)center
		  flip:(AZFlipMode)flipMask
	{
	id<AZRenderer> azr	= AZRenderer.renderer;

	// Make sure we have a reasonable srcRect. The image srcRect is possibly
	// from an Atlas texture (else its origin will be at 0,0) so add in the
	// origin of the image srcRect to the requested srcRect before taking
	// the intersection
	srcRect.origin.x += NSMinX(img.srcRect);
	srcRect.origin.y += NSMinY(img.srcRect);
	NSRect clipped    = NSIntersectionRect(img.srcRect, srcRect);
	if ((NSWidth(clipped) == 0) || (NSHeight(clipped) == 0))
		return;


	NSRect dstRect = clipped;
	dstRect.origin = xy;

	NSPoint cxy		= NSMakePoint(center.x + clipped.size.width / 2.f,
								  center.y + clipped.size.height / 2.f);

	if (img.handler != nil)
		[img draw];
	[azr blitFrom:img.texture
			  src:clipped
			  dst:dstRect
			angle:degrees
		   center:cxy
		     flip:flipMask];
	}



// MARK: Private methods

/*****************************************************************************\
|* Horizontal line as an optimisation over the generic version
\*****************************************************************************/

// Draw a hline in the current colour. No blending
- (int) _hLineFromX1:(int)x1 toX2:(int)x2 atY:(int)y
	{
	return [_renderer renderLineFromX:x1 y:y toX:x2 y:y];
	}

// Draw a hline with blending
- (int) _hLineFromX1:(int)x1 toX2:(int)x2 atY:(int)y colour:(AZColour *)colour
	{
	return [self _hLineFromX1:x1
						 toX2:x2
						  atY:y
						withR:colour.R
							g:colour.G
							b:colour.B
							a:colour.A];
	}

- (int) _hLineFromX1:(int)x1
				toX2:(int)x2
				 atY:(int)y
			   withR:(uint8_t)r
				   g:(uint8_t)g
				   b:(uint8_t)b
			       a:(uint8_t)a
	{
	int result = 0;
	if (a != 255)
		result |= [_renderer setBlendMode:SDL_BLENDMODE_BLEND];
	result |= [_renderer setDrawColourToRed:r g:g b:b a:a];
	result |= [_renderer renderLineFromX:x1 y:y toX:x2 y:y];
	return result;
	}



/*****************************************************************************\
|* Vertical line as an optimisation over the generic version
\*****************************************************************************/

// Draw a vline in the current colour. No blending
- (int) _vLineFromY1:(int)y1 toY2:(int)y2 atX:(int)x
	{
	return [_renderer renderLineFromX:x y:y1 toX:x y:y2];
	}

// Draw a vline with blending
- (int) _vLineFromY1:(int)y1 toY2:(int)y2 atX:(int)x colour:(AZColour *)colour
	{
	return [self _vLineFromY1:y1
						 toY2:y2
						  atX:x
						withR:colour.R
							g:colour.G
							b:colour.B
							a:colour.A];
	}

- (int) _vLineFromY1:(int)y1
				toY2:(int)y2
				 atX:(int)x
			   withR:(uint8_t)r
			       g:(uint8_t)g
				   b:(uint8_t)b
				   a:(uint8_t)a
	{
	int result = 0;
	if (a != 255)
		result |= [_renderer setBlendMode:SDL_BLENDMODE_BLEND];
	result |= [_renderer setDrawColourToRed:r g:g b:b a:a];
	result |= [_renderer renderLineFromX:x y:y1 toX:x y:y2];
	return result;
	}


/*****************************************************************************\
|* Anti-aliased line drawing.
\*****************************************************************************/
- (int) _aaLineAtX:(int)x1 y:(int)y1 toX:(int)x2 y:(int)y2
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	Sint32 xx0, yy0, xx1, yy1;
	Uint32 erradj;
	Uint32  wgt;
	int xdir;

	// Keep on working with 32bit numbers
	xx0 = x1;
	yy0 = y1;
	xx1 = x2;
	yy1 = y2;

	// Reorder points to make dy positive
	if (yy0 > yy1)
		{
		int tmp = yy0;
		yy0 = yy1;
		yy1 = tmp;

		tmp = xx0;
		xx0 = xx1;
		xx1 = tmp;
		}

	// Calculate distance
	int dx = xx1 - xx0;
	int dy = yy1 - yy0;

	// Adjust for negative dx and set xdir
	if (dx >= 0)
		xdir = 1;
	else
		{
		xdir = -1;
		dx = (-dx);
		}

	// Check for special cases
	if (dx == 0)
		{
		// Vertical line
		if (_drawAAEndpoint)
			return [self _vLineFromY1:y1 toY2:y2 atX:x1 withR:r g:g b:b a:a];
		else
			{
			if (dy > 0)
				return [self _vLineFromY1:yy0 toY2:yy0+dy atX:x1
									withR:r g:g b:b a:a];
			return [self pixelAtX:x1 y:y1 withR:r g:g b:b a:a];
			}
		}
	else if (dy == 0)
		{
		// Horizontal line
		if (_drawAAEndpoint)
			return [self _hLineFromX1:x1 toX2:x2 atY:y1 withR:r g:g b:b a:a];
		else
			{
			if (dx > 0)
				return [self _hLineFromX1:xx0 toX2:xx0+(xdir*dx) atY:y1
									withR:r g:g b:b a:a];
			return [self pixelAtX:x1 y:y1 withR:r g:g b:b a:a];
			}
		}
	else if ((dx == dy) && (_drawAAEndpoint))
		{
		// Diagonal line (with endpoint)
		return [self lineAtX:x1 y:y1 toX:x2 y:y2 withR:r g:g b:b a:a];
		}

	// Line is not horizontal, vertical or diagonal (with endpoint)
	int result = 0;

	// Zero accumulator
	uint32_t erracc = 0;

	// # of bits by which to shift erracc to get intensity level
	uint32_t intshift = 32 - AAbits;

	// Draw the initial pixel in the foreground color
	result |= [self pixelAtX:x1 y:y1 withR:r g:g b:b a:a];

	// x-major or y-major?
	if (dy > dx)
		{
		// y-major.  Calculate 16-bit fixed point fractional part of a pixel that
		// X advances every time Y advances 1 pixel, truncating the result so that
		// we won't overrun the endpoint along the X axis
		//
		// Not-so-portable version: erradj = ((Uint64)dx << 32) / (Uint64)dy;
		//
		erradj = ((dx << 16) / dy) << 16;

		// draw all pixels other than the first and last
		int x0pxdir = xx0 + xdir;
		while (--dy)
			{
			uint32_t erracctmp = erracc;
			erracc += erradj;
			if (erracc <= erracctmp)
				{
				// rollover in error accumulator, x coord advances
				xx0 = x0pxdir;
				x0pxdir += xdir;
				}
			yy0++;		// y-major so always advance Y

			// the AAbits most significant bits of erracc give us the intensity
			// weighting for this pixel, and the complement of the weighting for
			// the paired pixel.
			int wgt = (erracc >> intshift) & 255;
			result |= [self pixelAtX:xx0 y:yy0 alphaWeight:255-wgt
							   withR:r g:g b:b a:a];
			result |= [self pixelAtX:x0pxdir y:yy0 alphaWeight:wgt
							   withR:r g:g b:b a:a];
			}
		}
	else
		{
		// x-major line.  Calculate 16-bit fixed-point fractional part of a pixel
		// that Y advances each time X advances 1 pixel, truncating the result so
		// that we won't overrun the endpoint along the X axis.
		//
		// Not-so-portable version: erradj = ((Uint64)dy << 32) / (Uint64)dx;
		erradj = ((dy << 16) / dx) << 16;

		// draw all pixels other than the first and last
		int y0p1 = yy0 + 1;
		while (--dx)
			{
			uint32_t erracctmp = erracc;
			erracc += erradj;
			if (erracc <= erracctmp)
				{
				// Accumulator turned over, advance y
				yy0 = y0p1;
				y0p1++;
				}
			xx0 += xdir;	// x-major so always advance X

			// the AAbits most significant bits of erracc give us the intensity
			// weighting for this pixel, and the complement of the weighting for
			// the paired pixel.
			wgt = (erracc >> intshift) & 255;
			result |= [self pixelAtX:xx0 y:yy0 alphaWeight:255-wgt
							   withR:r g:g b:b a:a];
			result |= [self pixelAtX:xx0 y:y0p1 alphaWeight:wgt
							   withR:r g:g b:b a:a];
			}
		}

	// Check whether we're drawing the endpoint
	if (_drawAAEndpoint)
		{
		// Draw final pixel, always exactly intersected by the line and doesn't
		// need to be weighted.
		result |= [self pixelAtX:x2 y:y2 withR:r g:g b:b a:a];
		}
	return result;
	}


/*****************************************************************************\
|* Anti-aliased ellipse drawing.
\*****************************************************************************/
- (int) _aaEllipseAtX:(int)x y:(int)y rx:(int)rx ry:(int)ry
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	Sint16 xs, ys, dyt;
	float cp;

	/* Variable setup */
	int a2 		= rx * rx;
	int b2 		= ry * ry;

	int ds 		= 2 * a2;
	int dt 		= 2 * b2;

	Sint16 xc2 	= 2 * x;
	Sint16 yc2 	= 2 * y;

	// introduce some overdraw
	double sab 	= SDL_sqrt(a2 + b2);
	Sint16 od 	= (Sint16)SDL_round(sab*0.01) + 1;
	int dxt 	= (Sint16)SDL_round((double)a2 / sab) + od;

	int t = 0;
	int s = -2 * a2 * ry;
	int d = 0;

	Sint16 xp = x;
	Sint16 yp = y - ry;

	// Draw
	int result = 0;
	if (a != 255)
		result |= [_renderer setBlendMode:SDL_BLENDMODE_BLEND];

	// "End points"
	result |= [self pixelAtX:xp y:yp withR:r g:g b:b a:a];
	result |= [self pixelAtX:xc2 - xp y:yp withR:r g:g b:b a:a];
	result |= [self pixelAtX:xp y:yc2 - yp withR:r g:g b:b a:a];
	result |= [self pixelAtX:xc2 - xp y:yc2 - yp withR:r g:g b:b a:a];

	for (int i = 1; i <= dxt; i++)
		{
		xp--;
		d += t - b2;

		if (d >= 0)
			ys = yp - 1;
		else if ((d - s - a2) > 0)
			{
			if ((2 * d - s - a2) >= 0)
				ys = yp + 1;
			else
				{
				ys = yp;
				yp++;
				d -= s + a2;
				s += ds;
				}
			}
		else
			{
			yp++;
			ys = yp + 1;
			d -= s + a2;
			s += ds;
			}

		t -= dt;

		// Calculate alpha
		if (s != 0)
			{
			cp = (float) SDL_abs(d) / (float) SDL_abs(s);
			if (cp > 1.0)
				cp = 1.0;
			}
		else
			cp = 1.0;


		// Calculate weights
		Uint8 weight = (Uint8) (cp * 255);
		Uint8 iweight = 255 - weight;

		// Upper half
		Sint16 xx = xc2 - xp;
		result |= [self pixelAtX:xp y:yp alphaWeight:iweight withR:r g:g b:b a:a];
		result |= [self pixelAtX:xx y:yp alphaWeight:iweight withR:r g:g b:b a:a];

		result |= [self pixelAtX:xp y:ys alphaWeight:weight withR:r g:g b:b a:a];
		result |= [self pixelAtX:xx y:ys alphaWeight:weight withR:r g:g b:b a:a];

		// Lower half
		Sint16 yy = yc2 - yp;
		result |= [self pixelAtX:xp y:yy alphaWeight:iweight withR:r g:g b:b a:a];
		result |= [self pixelAtX:xx y:yy alphaWeight:iweight withR:r g:g b:b a:a];

		yy = yc2 - ys;
		result |= [self pixelAtX:xp y:yy alphaWeight:weight withR:r g:g b:b a:a];
		result |= [self pixelAtX:xx y:yy alphaWeight:weight withR:r g:g b:b a:a];
		}

	// Replaces original approximation code dyt = abs(yp - yc);
	dyt = (Sint16)SDL_round((double)b2 / sab ) + od;

	for (int i = 1; i <= dyt; i++)
		{
		yp++;
		d -= s + a2;

		if (d <= 0)
			xs = xp + 1;
		else if ((d + t - b2) < 0)
			{
			if ((2 * d + t - b2) <= 0)
				xs = xp - 1;
			else
				{
				xs = xp;
				xp--;
				d += t - b2;
				t -= dt;
				}
			}
		else
			{
			xp--;
			xs = xp - 1;
			d += t - b2;
			t -= dt;
			}

		s += ds;

		// Calculate alpha
		if (t != 0)
			{
			cp = (float) SDL_abs(d) / (float) SDL_abs(t);
			if (cp > 1.0)
				cp = 1.0;
			}
		else
			cp = 1.0;

		// Calculate weight
		Uint8 weight = (Uint8) (cp * 255);
		Uint8 iweight = 255 - weight;

		/* Left half */
		Sint16 xx = xc2 - xp;
		Sint16 yy = yc2 - yp;
		result |= [self pixelAtX:xp y:yp alphaWeight:iweight withR:r g:g b:b a:a];
		result |= [self pixelAtX:xx y:yp alphaWeight:iweight withR:r g:g b:b a:a];

		result |= [self pixelAtX:xp y:yy alphaWeight:iweight withR:r g:g b:b a:a];
		result |= [self pixelAtX:xx y:yy alphaWeight:iweight withR:r g:g b:b a:a];

		/* Right half */
		xx = xc2 - xs;
		result |= [self pixelAtX:xs y:yp alphaWeight:weight withR:r g:g b:b a:a];
		result |= [self pixelAtX:xx y:yp alphaWeight:weight withR:r g:g b:b a:a];

		result |= [self pixelAtX:xs y:yy alphaWeight:weight withR:r g:g b:b a:a];
		result |= [self pixelAtX:xx y:yy alphaWeight:weight withR:r g:g b:b a:a];
		}

	return result;
	}

/*****************************************************************************\
|* Anti-aliased (or not) polygon drawing.
\*****************************************************************************/
- (int) _polygonWith:(int)num vx:(int *)vx vy:(int *)vy
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	if (!_usingAntiAliasing)
		{
		// Create array of points
		NSPoint points[num+1];
		int nn = num + 1;

		for (int i=0; i<num; i++)
			{
			points[i].x = vx[i];
			points[i].y = vy[i];
			}
		points[num].x = vx[0];
		points[num].y = vy[0];

		return [_renderer renderLines:points count:nn];
		}

	// Pointer setup
	const int *x1 = vx;
	const int *x2 = vx; x2 ++;
	const int *y1 = vy;
	const int *y2 = vy; y2 ++;

	// Draw
	_drawAAEndpoint = NO;
	int result = 0;
	for (int i = 1; i < num; i++)
		{
		result |= [self _aaLineAtX:*x1 y:*y1 toX:*x2 y:*y2 withR:r g:g b:b a:a];

		x1 = x2;
		y1 = y2;
		x2++;
		y2++;
		}
	result |= [self _aaLineAtX:*x1 y:*y1 toX:*vx y:*vy withR:r g:g b:b a:a];

	return result;
	}


/*****************************************************************************\
|* Helper function for polygon qsort
|* Returns 0 if a==b, a negative number if a < b or a positive number if a > b.
\*****************************************************************************/
static int _qsortInts(const void *a, const void *b)
	{
	return (*(const int *) a) - (*(const int *) b);
	}


/*****************************************************************************\
|* Internal method to draw a textured horizontal line.
\*****************************************************************************/
- (int) _texturedHLineAtX:(int)x1
					  toX:(int)x2
					  atY:(int)y
				  texture:(NSInteger)texture
				 textureW:(int)textureW
				 textureH:(int)textureH
				textureDx:(int)textureDx
				textureDy:(int)textureDy
	{
	// Swap x1, x2 if required to ensure x1<=x2
	if (x1 > x2)
		{
		int xtmp = x1;
		x1 = x2;
		x2 = xtmp;
		}

	// Calculate width to draw
	int w = x2 - x1 + 1;

	// Determine where in the texture we start drawing
	int textureX =   (x1 - textureDx) % textureW;
	if (textureX < 0)
		textureX = textureW + textureX;

	int textureY = (y + textureDy) % textureH;
	if (textureY < 0)
		textureY = textureH + textureY;

	// set up the source rectangle; we are only drawing one horizontal line
	NSRect src;
	src.origin.y 	= textureY;
	src.origin.x 	= textureX;
	src.size.height = 1;

	// we will draw to the current y
	NSRect dst;
	dst.origin.y 	= y;
	dst.size.height = 1;

	// if there are enough pixels left in the current row of the texture
	// draw it all at once
	int result = 0;
	if (w <= textureW -textureX)
		{
		src.size.width = w;
		src.origin.x = textureX;
		dst.origin.x= x1;
		dst.size.width = src.size.width;
		[_renderer blitFrom:texture src:src dst:dst];
		}
	else
		{
		/* we need to draw multiple times */
		/* draw the first segment */
		int pixelsWritten = textureW  - textureX;
		src.size.width = pixelsWritten;
		src.origin.x = textureX;
		dst.origin.x = x1;
		dst.size.width = src.size.width;
		result |= ([_renderer blitFrom:texture src:src dst:dst] != 0);
		int writeWidth = textureW;

		// now draw the rest, set the source x to 0
		src.origin.x = 0;
		while (pixelsWritten < w)
			{
			if (writeWidth >= w - pixelsWritten)
				writeWidth =  w - pixelsWritten;

			src.size.width = writeWidth;
			dst.origin.x = x1 + pixelsWritten;
			dst.size.width = src.size.width;
			result |= ([_renderer blitFrom:texture src:src dst:dst] != 0);
			pixelsWritten += writeWidth;
			}
		}
	return result;
	}


/*****************************************************************************\
|* Internal function to calculate bezier interpolator of data array with ndata
|* values at position 't'.
\*****************************************************************************/
static double _evaluateBezier(float *data, int num, float t)
	{
	// Sanity check bounds
	if (t < 0.0)
		return data[0];

	if (t >= (double)num)
		return data[num-1];

	// Adjust t to the range 0.0 to 1.0
	double mu = t/(double)num;

	/* Calculate interpolate */
	int n 			= num-1;
	float result	= 0.f;
	float muk 		= 1.f;
	float munk 		= SDL_pow(1-mu,(float)n);

	for (int k=0; k <= n; k++)
		{
		int nn 			= n;
		int kn 			= k;
		int nkn 		= n - k;
		float blend 	= muk * munk;
		muk 		   *= mu;
		munk 		   /= (1-mu);
		while (nn >= 1)
			{
			blend *= nn;
			nn--;
			if (kn > 1)
				{
				blend /= (float)kn;
				kn--;
				}

			if (nkn > 1)
				{
				blend /= (float)nkn;
				nkn--;
				}
			}
		result += data[k] * blend;
		}

	return result;
	}

@end
