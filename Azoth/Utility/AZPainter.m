//
//  AZPainter.m
//  Azoth
//
//  Created by Simon Gornall on 12/12/24.
//

#import <SDL3/SDL.h>

#import "AZApp.h"
#import "AZColour.h"
#import "AZGeometry.h"
#import "AZPainter.h"
#import "AZView.h"

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
|* "Private" properties
\*****************************************************************************/
@interface AZPainter()
@property(assign, nonatomic) SDL_Renderer *						renderer;
@property(strong, nonatomic) AZView * 							view;
@end

@implementation AZPainter

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithView:(AZView *)view
	{
	if (self = [super init])
		{
		_view = view;
		}
	return self;
	}

+ (AZPainter *) painterForView:(AZView *)view
	{
	return [[AZPainter alloc] initWithView:view];
	}

/*****************************************************************************\
|* Set up the context to draw, and call the view's method with ourselves as a
|* parameter
\*****************************************************************************/
- (BOOL) execute
	{
	_renderer 		= [AZApp sharedInstance].renderer;
	if (_renderer == NULL)
		{
		SDL_LogError(SDL_LOG_CATEGORY_GPU, "Cannot get window renderer");
		return NO;
		}

	SDL_Rect bounds	= SDLRectFromNSRect(_view.dirty);

	SDL_SetRenderTarget(_renderer, _view.bg);
	SDL_SetRenderClipRect(_renderer, &bounds);

	[_view drawInRect:_view.dirty withPainter:self];
	_view.dirty = NSZeroRect;

	SDL_SetRenderClipRect(_renderer, NULL);
	SDL_SetRenderTarget(_renderer, NULL);
	return YES;
	}

// MARK: Pixel Drawing routines

/*****************************************************************************\
|* Pixel routines
\*****************************************************************************/

// Draw a single pixel in the current colour
- (int) pixelAtX:(int)x y:(int)y
	{
	return SDL_RenderPoint(_renderer, x, y);
	}

// Draw pixel with blending enabled if a<255
- (int) pixelAtX:(int)x y:(int)y colour:(AZColour *)colour
	{
	return [self pixelAtX:x
						y:y
				    withR:colour.red
						g:colour.green
						b:colour.blue
						a:colour.alpha];
	}

// Draw pixel with blending enabled if a<255, using r,g,b,a
- (int) pixelAtX:(int)x y:(int)y
		 withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	int result = 0;
	if (a != 255)
		result |= SDL_SetRenderDrawBlendMode(_renderer, SDL_BLENDMODE_BLEND);
	result |= SDL_SetRenderDrawColor(_renderer, r,g,b,a);
	result |= SDL_RenderPoint(_renderer, x, y);
	return result;
	}

// Draw pixel with blending enabled if a<255, and weight 'alpha' by 0..255
- (int) pixelAtX:(int)x y:(int)y colour:(AZColour *)colour weight:(int)weight
	{
	return [self pixelAtX:x
						y:y
			  alphaWeight:weight
					withR:colour.red
						g:colour.green
						b:colour.blue
						a:colour.alpha];
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
	return SDL_RenderLine(_renderer, x1, y1, x2, y2);
	}


// Draw a line with blending enabled if a<255
- (int) lineAtX:(int)x1 y:(int)y1 toX:(int)x2 y:(int)y2 colour:(AZColour *)colr
	{
	return [self lineAtX:x1
					   y:y1
					 toX:x2
					   y:y2
				   withR:colr.red
					   g:colr.green
					   b:colr.blue
					   a:colr.alpha];
	}

// Draw a line with blending enabled if a<255, using r,g,b,a
- (int) lineAtX:(int)x1 y:(int)y1 toX:(int)x2 y:(int)y2
		withR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	int result = 0;
	if (a != 255)
		result |= SDL_SetRenderDrawBlendMode(_renderer, SDL_BLENDMODE_BLEND);
	result |= SDL_SetRenderDrawColor(_renderer, r, g, b, a);
	result |= SDL_RenderLine(_renderer, x1, y1, x2, y2);
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
						withR:colour.red
							g:colour.green
							b:colour.blue
							a:colour.alpha];
	}

- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h colour:(AZColour *)colour;
	{
	return [self rectangleAtX:(int)x
							y:(int)y
							w:(int)w
							h:(int)h
						withR:colour.red
							g:colour.green
							b:colour.blue
							a:colour.alpha];
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

	// Create destination rect
	SDL_FRect rect = {x, y, w, h};

	// Draw
	int result = 0;
	if (a != 255)
		result |= SDL_SetRenderDrawBlendMode(_renderer, SDL_BLENDMODE_BLEND);
	result |= SDL_SetRenderDrawColor(_renderer, r, g, b, a);
	result |= SDL_RenderRect(_renderer, &rect);
	return result;
	}

// MARK: Rounded Rectangle Drawing routines

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
						withR:colour.red
							g:colour.green
							b:colour.blue
							a:colour.alpha];
	}

- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h radius:(int)r
		colour:(AZColour *)colour
	{
	return [self rectangleAtX:x
							y:y
							w:w
							h:h
					   radius:r
						withR:colour.red
							g:colour.green
							b:colour.blue
							a:colour.alpha];
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

// MARK: Filled rectangle Drawing routines
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
						withR:colour.red
							g:colour.green
							b:colour.blue
							a:colour.alpha];
	}

- (int) rectangleAtX:(int)x y:(int)y w:(int)w h:(int)h filled:(BOOL)yn
	    colour:(AZColour *)colour
	{
	return [self rectangleAtX:x
							y:y
							w:w
							h:h
					   filled:yn
						withR:colour.red
							g:colour.green
							b:colour.blue
							a:colour.alpha];
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

	// Create destination rect
	SDL_FRect rect = {x, y, w+1, h+1};

	// Draw
	int result = 0;
	if (a != 255)
		result |= SDL_SetRenderDrawBlendMode(_renderer, SDL_BLENDMODE_BLEND);
	result |= SDL_SetRenderDrawColor(_renderer, r, g, b, a);
	result |= SDL_RenderFillRect(_renderer, &rect);
	return result;
	}


// MARK: Rounded filled rectangle Drawing routines
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
						withR:colour.red
							g:colour.green
							b:colour.blue
							a:colour.alpha];
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
						withR:colour.red
							g:colour.green
							b:colour.blue
							a:colour.alpha];
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
		result |= SDL_SetRenderDrawBlendMode(_renderer, SDL_BLENDMODE_BLEND);
	result |= SDL_SetRenderDrawColor(_renderer, r, g, b, a);

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
	return (result);
	}


// MARK: Circular arc Drawing routines

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
				  withR:colour.red
					  g:colour.green
					  b:colour.blue
					  a:colour.a];
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
		result |= SDL_SetRenderDrawBlendMode(_renderer, SDL_BLENDMODE_BLEND);
	result |= SDL_SetRenderDrawColor(_renderer, r, g, b, a);

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


// MARK: Private methods


/*****************************************************************************\
|* Horizontal line as an optimisation over the generic version
\*****************************************************************************/

// Draw a hline in the current colour. No blending
- (int) _hLineFromX1:(int)x1 toX2:(int)x2 atY:(int)y
	{
	return SDL_RenderLine(_renderer, x1, y, x2, y);
	}

// Draw a hline with blending
- (int) _hLineFromX1:(int)x1 toX2:(int)x2 atY:(int)y colour:(AZColour *)colour
	{
	return [self _hLineFromX1:x1
						 toX2:x2
						  atY:y
						withR:colour.red
							g:colour.green
							b:colour.blue
							a:colour.alpha];
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
		result |= SDL_SetRenderDrawBlendMode(_renderer, SDL_BLENDMODE_BLEND);
	result |= SDL_SetRenderDrawColor(_renderer, r, g, b, a);
	result |= SDL_RenderLine(_renderer, x1, y, x2, y);
	return result;
	}



/*****************************************************************************\
|* Vertical line as an optimisation over the generic version
\*****************************************************************************/

// Draw a vline in the current colour. No blending
- (int) _vLineFromY1:(int)y1 toY2:(int)y2 atX:(int)x
	{
	return SDL_RenderLine(_renderer, x, y1, x, y2);
	}

// Draw a vline with blending
- (int) _vLineFromY1:(int)y1 toY2:(int)y2 atX:(int)x colour:(AZColour *)colour
	{
	return [self _vLineFromY1:y1
						 toY2:y2
						  atX:x
						withR:colour.red
							g:colour.green
							b:colour.blue
							a:colour.alpha];
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
		result |= SDL_SetRenderDrawBlendMode(_renderer, SDL_BLENDMODE_BLEND);
	result |= SDL_SetRenderDrawColor(_renderer, r, g, b, a);
	result |= SDL_RenderLine(_renderer, x, y1, x, y2);
	return result;
	}


@end
