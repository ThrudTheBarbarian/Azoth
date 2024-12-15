//
//  AZTextPainter.m
//  Azoth
//
//  Created by Simon Gornall on 12/14/24.
//

#import <SDL3/SDL.h>
#import <SDL3_ttf/SDL_ttf.h>

#import "AZApp.h"
#import "AZFont.h"
#import "AZGlyphData.h"
#import "AZTextPainter.h"
#import "AZObject.h"

#ifndef EXTRACT_VARARGS
#  define EXTRACT_VARARGS(string, fmt)		 								\
    va_list lst; 															\
    va_start(lst, fmt); 													\
    NSString *string = [[NSString alloc] initWithFormat:fmt arguments:lst];	\
    va_end(lst)
#endif

@implementation AZTextPainter

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithRenderer:(struct SDL_Renderer *)renderer
	{
	if (self = [super init])
		{
		_renderer = renderer;
		}
	return self;
	}

+ (AZTextPainter *) painterWithRenderer:(struct SDL_Renderer *)renderer
	{
	return [[AZTextPainter alloc] initWithRenderer:renderer];
	}

/*****************************************************************************\
|* Utility method - return an initialised effect structure
\*****************************************************************************/
+ (AZFontEffect) mkEffect:(AZFontHAlign)hAlign
				   vAlign:(AZFontVAlign)vAlign
				   scaleX:(float)sx
				   scaleY:(float)sy
					    r:(uint8_t)r
					    g:(uint8_t)g
					    b:(uint8_t)b
					    a:(uint8_t)a
	{
	AZFontEffect e =
		{
		.hAlign = hAlign,
		.vAlign = vAlign,
		.xScale = sx,
		.yScale = sy,
		.r		= r,
		.g		= g,
		.b		= b,
		.a		= a
		};
	return e;
	}

/*****************************************************************************\
|* Basic drawing routines
\*****************************************************************************/
- (NSRect) drawAtX:(float)x y:(float)y text:(NSString *)text
	{
	if (_font == nil)
		return NSZeroRect;

	SDL_Color c = _font.defaultColour;
	return [self _drawAtX:x
						y:y
				   colour:c
				   hAlign:AZFONT_HALIGN_LEFT
				   scaleX:1.f
				   scaleY:1.f
				      msg:text];
	}


/*****************************************************************************\
|* Renderer method - override in a subclass to change how it's rendered
\*****************************************************************************/
- (NSRect) renderFrom:(NSRect)srcRect
				   in:(SDL_Texture *)src
				   at:(NSPoint)p
			   xscale:(float)xscale
			   yscale:(float)yscale
	{
    float w = srcRect.size.width * xscale;
    float h = srcRect.size.height * yscale;
    NSRect result;

	SDL_FlipMode flip = SDL_FLIP_NONE;
	if (xscale < 0)
		{
		xscale = -xscale;
		flip = (SDL_FlipMode) ((int)flip | (int)SDL_FLIP_HORIZONTAL);
		}
	if (yscale < 0)
		{
		yscale = -yscale;
		flip = (SDL_FlipMode) ((int)flip | (int)SDL_FLIP_VERTICAL);
		}

	SDL_FRect r = {
				  srcRect.origin.x,
				  srcRect.origin.y,
				  srcRect.size.width,
				  srcRect.size.height
				  };

	SDL_FRect dr = {p.x, p.y, (int)(xscale * r.w), (int)(yscale * r.h)};
	SDL_RenderTextureRotated(_renderer, src, &r, &dr, _angle, &_rotateAbout, flip);

	result.origin = p;
	result.size.width = w;
	result.size.height = h;
    return result;
	}

// Private Methods
/*****************************************************************************\
|* Simple drawing breakout
|* - with colour
|* - with horizontal alignment
|* - with scale
\*****************************************************************************/
- (NSRect) _drawAtX:(float)x y:(float)y colour:(SDL_Color)colour
		   hAlign:(AZFontHAlign)hAlign scaleX:(float)sx scaleY:(float)sy
		   msg:(NSString *)text
	{
	if (_font == nil)
		return NSZeroRect;
	[_font setColourForAllCaches:colour];

	NSRect result = NSZeroRect;
	switch (hAlign)
		{
		case AZFONT_HALIGN_LEFT:
			result = [self _renderLeftAtX:x y:y scaleX:sx scaleY:sy msg:text];
			break;
		case AZFONT_HALIGN_CENTER:
			//result = [self _renderCenterAtX:x y:y scaleX:sx scaleY:sy msg:text];
			break;
		case AZFONT_HALIGN_RIGHT:
			//result = [self _renderRightAtX:x y:y scaleX:sx scaleY:sy msg:text];
			break;
		default:
			break;
		}
	return result;
	}

/*****************************************************************************\
|* Render left-justified text
\*****************************************************************************/
- (NSRect) _renderLeftAtX:(float)x y:(float)y scaleX:(float)sx scaleY:(float)sy
		   msg:(NSString *)text
	{
	NSRect dirtyRect 	= NSMakeRect(x, y, 0, 0);
    if (_font == NULL)
        return dirtyRect;

    if (_font.glyphs.count == 0)
        return dirtyRect;

    float destX 			= x;
    float destY 			= y;
    float destH				= _font.height * sy;
    float destLetterSpacing	= ((_angle == 90) || (_angle == 270))
							? _font.letterSpacing * sy
							: _font.letterSpacing * sx;
    int newlineX 			= x;
    int newlineY 			= y;
	NSInteger length		= text.length;

    for (NSInteger i = 0; i<length; i++)
		{
		unichar c = [text characterAtIndex:i];
        if (c == '\n')
			{
			switch (_angle)
				{
				case 90:
					destY = newlineY;
					destX -= (destH + _font.lineSpacing * sx);
					break;
				case 180:
					destX = newlineX;
					destY -= (destH + _font.lineSpacing * sy);
					break;
					
				case 270:
					destY = newlineY;
					destX += destH + _font.lineSpacing * sx;
					break;
				
				case 0:
				default:
					destX = newlineX;
					destY += destH + _font.lineSpacing * sy;
					break;
				}
            continue;
			}

		AZGlyphData *glyphData = [_font glyphDataFor:c];
        if (!glyphData)
			{
            c = ' ';
            glyphData = [_font glyphDataFor:c];
			if (!glyphData)
                continue;  // Skip bad characters
			}

        NSRect srcRect = glyphData.rect;
		NSRect dstRect = [self renderFrom:srcRect
										 in:[_font glyphsFor:glyphData.cacheId]
										 at:NSMakePoint(destX, destY)
									 xscale:sx
									 yscale:sy];


        if (dirtyRect.size.width == 0 || dirtyRect.size.height == 0)
            dirtyRect = dstRect;
        else
			dirtyRect = NSUnionRect(dirtyRect, dstRect);

		float width = glyphData.rect.size.width;
		switch (_angle)
			{
			case 90:
				destY += width * sy + destLetterSpacing;
				break;
				
			case 180:
				destX -= (width * sx + destLetterSpacing);
				break;

			case 270:
				destY -= (width * sy + destLetterSpacing);
				break;

			case 0:
			default:
				destX += width * sx + destLetterSpacing;
				break;
			}
		}

    return dirtyRect;
	}

@end
