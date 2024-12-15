//
//  AZTextPainter.m
//  Azoth
//
//  Created by Simon Gornall on 12/14/24.
//

#import <SDL3/SDL.h>
#import <SDL3_ttf/SDL_ttf.h>

#import "AZApp.h"
#import "AZColour.h"
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
		_renderer 	= renderer;
		_colour 	= [AZColour colourWithR:0.f g:0.f b:0.f a:1.f];
		_hAlign		= AZFONT_HALIGN_LEFT;
		_scale		= (AZScale){1.f, 1.f};
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
					    r:(uint8_t)r
					    g:(uint8_t)g
					    b:(uint8_t)b
					    a:(uint8_t)a
	{
	AZFontEffect e =
		{
		.hAlign = hAlign,
		.vAlign = vAlign,
		.r		= r,
		.g		= g,
		.b		= b,
		.a		= a
		};
	return e;
	}

/*****************************************************************************\
|* Return the text width of (possibly) multi-line text
\*****************************************************************************/
- (int) textWidthFor:(NSString *)fmt, ...
	{
	if ((_font == nil) || (fmt == nil))
		{
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
					"No font, or fmt=nil in -textWidthFor...");
		return 0;
		}

	EXTRACT_VARARGS(text, fmt);
	int width 		= 0;
	int lineWidth	= 0;
	NSInteger len	= text.length;

	for (NSInteger i=0; i<len; i++)
		{
		unichar c = [text characterAtIndex:i];

		if (c == '\n')
			{
			lineWidth = (lineWidth > width) ? lineWidth : width;
			width = 0;
			continue;
			}
		AZGlyphData *glyph = [_font glyphDataFor:c];
		if (glyph)
			width += glyph.rect.size.width;
		else
			{
			glyph = [_font glyphDataFor:' '];
			width += glyph.rect.size.width;
			}
		}
	lineWidth = (lineWidth > width) ? lineWidth : width;
	return lineWidth;
	}

/*****************************************************************************\
|* Basic drawing routines
|* @(x,y)
\*****************************************************************************/
- (NSRect) drawAtX:(float)x y:(float)y text:(NSString *)text
	{
	if ((_font == nil) || (text == nil))
		return NSZeroRect;
	[_font setColourForAllCaches:_colour];

	NSRect result = NSZeroRect;
	switch (_hAlign)
		{
		case AZFONT_HALIGN_LEFT:
			result = [self _renderLeftAtX:x y:y msg:text];
			break;
		case AZFONT_HALIGN_CENTER:
			result = [self _renderCenterAtX:x y:y msg:text];
			break;
		case AZFONT_HALIGN_RIGHT:
			result = [self _renderRightAtX:x y:y msg:text];
			break;
		default:
			break;
		}
	return result;
	}

/*****************************************************************************\
|* Draw text within a limiting box, making words wrap appropriately
|* - with colour
|* - with horizontal alignment
|* - with scale
\*****************************************************************************/
- (NSRect) drawInBox:(NSRect)box text:(NSString *)text
	{
	bool useClip = SDL_RenderClipEnabled(_renderer);

    SDL_Rect oldclip, newclip;
    if (useClip)
		{
		SDL_GetRenderClipRect(_renderer, &oldclip);
		NSRect oldNS 		= NS_RECT(oldclip);
		NSRect intersect	= NSIntersectionRect(oldNS, box);
        newclip 			= SDL_RECT(intersect);
		}
    else
        newclip = SDL_RECT(box);

    SDL_SetRenderClipRect(_renderer, &newclip);
	[_font setColourForAllCaches:_colour];
	[self _drawColumnFor:text inBox:box];

    if (useClip)
        SDL_SetRenderClipRect(_renderer, &oldclip);
    else
        SDL_SetRenderClipRect(_renderer, NULL);

    return box;
	}

/*****************************************************************************\
|* Renderer method - override in a subclass to change how it's rendered
\*****************************************************************************/
- (NSRect) renderFrom:(NSRect)srcRect in:(SDL_Texture *)src at:(NSPoint)p
	{
	// Take a local copy since we modify it here
	AZScale scale = _scale;

    float w = srcRect.size.width * scale.x;
    float h = srcRect.size.height * scale.y;
    NSRect result;

	SDL_FlipMode flip = SDL_FLIP_NONE;
	if (scale.x < 0)
		{
		scale.x = -scale.x;
		flip = (SDL_FlipMode) ((int)flip | (int)SDL_FLIP_HORIZONTAL);
		}
	if (scale.y < 0)
		{
		scale.y = -scale.y;
		flip = (SDL_FlipMode) ((int)flip | (int)SDL_FLIP_VERTICAL);
		}

	SDL_FRect r = {
				  srcRect.origin.x,
				  srcRect.origin.y,
				  srcRect.size.width,
				  srcRect.size.height
				  };

	SDL_FRect dr = {p.x, p.y, (int)(scale.x * r.w), (int)(scale.y * r.h)};
	SDL_RenderTextureRotated(_renderer, src, &r, &dr, _angle, &_rotateAbout, flip);

	result.origin = p;
	result.size.width = w;
	result.size.height = h;
    return result;
	}

// Private Methods

/*****************************************************************************\
|* Draw column-based text which fits words into a horizontal space
\*****************************************************************************/
- (NSInteger) _drawColumnFor:(NSString *)text inBox:(NSRect)box
	{
    int y = box.origin.y;
	int x = box.origin.x;
	switch (_hAlign)
		{
		case AZFONT_HALIGN_CENTER:
			x += box.size.width/2;
			break;
		case AZFONT_HALIGN_RIGHT:
			x += box.size.width;
			break;
		default:
			break;
		}
	NSArray<NSString *> *list = [self _fitText:text
									   toWidth:box.size.width
								  keepNewlines:NO];
	for (NSString *line in list)
		{
		[self drawAtX:x y:y text:line];
		y += _font.height * _scale.y;
		}


    return y - box.origin.y;
	}

/*****************************************************************************\
|* Fit words into lines so that they don't go over a limit
\*****************************************************************************/
- (NSArray<NSString *> *) _fitText:(NSString *)text
						   toWidth:(int)width
					  keepNewlines:(BOOL)keep
	{
	int w 							  = 0;
	NSMutableArray<NSString *> *lines = [NSMutableArray new];
	NSMutableString *line 			  = [NSMutableString new];
	NSArray<NSString *> *words 		  = [text componentsSeparatedByString:@" "];
	int spaceWidth					  = [self textWidthFor:@" "];

	for (NSString *word in words)
		{
		int wordWidth 		= [self textWidthFor:word];

		if (w == 0)
			{
			[line appendString:word];
			w += wordWidth;
			}
		else if (w + wordWidth + spaceWidth < width)
			{
			[line appendString:@" "];
			[line appendString:word];
			w += wordWidth + spaceWidth;
			}
		else
			{
			[lines addObject:[line copy]];
			[line setString:word];
			w = wordWidth;
			if (keep)
				[lines addObject:@""];
			}
		}
	if (line.length > 0)
		[lines addObject:line];

	return lines;
	}

/*****************************************************************************\
|* Render center-justified text
\*****************************************************************************/
- (NSRect) _renderCenterAtX:(float)x y:(float)y msg:(NSString *)text
	{
    NSRect result 	= {x, y, 0, 0};
	NSArray *split 	= [text componentsSeparatedByString:@"\n"];

	for (NSString *string in split)
		{
		int w 	 = x - _scale.x * [self textWidthFor:string]/2.f;
		NSRect r = [self _renderLeftAtX:w y:y msg:string];
		result 	 = NSUnionRect(result, r);
		y       += _scale.y * _font.height;
		}

    return result;
	}

/*****************************************************************************\
|* Render right-justified text
\*****************************************************************************/
- (NSRect) _renderRightAtX:(float)x y:(float)y msg:(NSString *)text
	{
    NSRect result 	= {x, y, 0, 0};
	NSArray *split 	= [text componentsSeparatedByString:@"\n"];
	for (NSString *string in split)
		{
		int w 	 = x - _scale.x * [self textWidthFor:string];
		NSRect r = [self _renderLeftAtX:w y:y msg:string];
		result 	 = NSUnionRect(result, r);
		y       += _scale.y * _font.height;
		}

    return result;
	}

/*****************************************************************************\
|* Render left-justified text
\*****************************************************************************/
- (NSRect) _renderLeftAtX:(float)x y:(float)y msg:(NSString *)text
	{
	NSRect dirtyRect 	= NSMakeRect(x, y, 0, 0);
    if (_font == NULL)
        return dirtyRect;

    if (_font.glyphs.count == 0)
        return dirtyRect;

    float destX 			= x;
    float destY 			= y;
    float destH				= _font.height * _scale.y;
    float destLetterSpacing	= ((_angle == 90) || (_angle == 270))
							? _font.letterSpacing * _scale.y
							: _font.letterSpacing * _scale.x;
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
					destX -= (destH + _font.lineSpacing * _scale.x);
					break;
				case 180:
					destX = newlineX;
					destY -= (destH + _font.lineSpacing * _scale.y);
					break;
					
				case 270:
					destY = newlineY;
					destX += destH + _font.lineSpacing * _scale.x;
					break;
				
				case 0:
				default:
					destX = newlineX;
					destY += destH + _font.lineSpacing * _scale.y;
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
										 at:NSMakePoint(destX, destY)];


        if (dirtyRect.size.width == 0 || dirtyRect.size.height == 0)
            dirtyRect = dstRect;
        else
			dirtyRect = NSUnionRect(dirtyRect, dstRect);

		float width = glyphData.rect.size.width;
		switch (_angle)
			{
			case 90:
				destY += width * _scale.y + destLetterSpacing;
				break;
				
			case 180:
				destX -= (width * _scale.x + destLetterSpacing);
				break;

			case 270:
				destY -= (width * _scale.y + destLetterSpacing);
				break;

			case 0:
			default:
				destX += width * _scale.x + destLetterSpacing;
				break;
			}
		}

    return dirtyRect;
	}

@end
