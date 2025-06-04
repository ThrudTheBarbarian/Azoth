//
//  AZTextPainter.m
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <SDL3/SDL.h>
#import <SDL3_ttf/SDL_ttf.h>

#import "AZApplication.h"
#import "AZColour.h"
#import "AZFont.h"
#import "AZGlyphData.h"
#import "AZRenderer.h"
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
- (instancetype) initWithRenderer:(id<AZRenderer>)renderer
	{
	if (self = [super init])
		{
		_renderer 		= renderer;
		_colour 		= AZColour.black;
		_alignment		= AZTextAlignmentLeft;
		_scale			= (AZScale){1.f, 1.f};
		_rotateAbout	= (NSPoint){0.f,0.f};

		}
	return self;
	}

+ (AZTextPainter *) painterWithRenderer:(id<AZRenderer>)renderer
	{
	return [[AZTextPainter alloc] initWithRenderer:renderer];
	}

/*****************************************************************************\
|* Utility method - return an initialised effect structure
\*****************************************************************************/
+ (AZFontEffect) mkEffect:(AZTextAlignment)alignment
					    r:(uint8_t)r
					    g:(uint8_t)g
					    b:(uint8_t)b
					    a:(uint8_t)a
	{
	AZFontEffect e =
		{
		.alignment 	= alignment,
		.r			= r,
		.g			= g,
		.b			= b,
		.a			= a
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
	return [_font textWidthFor:text];
	}

/*****************************************************************************\
|* Return the text height of (possibly) multi-line text
\*****************************************************************************/
- (int) textHeightFor:(NSString *)fmt, ...;
	{
	if ((_font == nil) || (fmt == nil))
		{
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
					"No font, or fmt=nil in -textHeightFor...");
		return 0;
		}

	EXTRACT_VARARGS(text, fmt);
	int numLines = 1;
	NSInteger length = text.length;
	for (NSInteger i=0; i<length; i++)
		{
		unichar c = [text characterAtIndex:i];
		if (c == '\n')
			numLines ++;
		}
	return numLines * _font.height;
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
	switch (_alignment)
		{
		case AZTextAlignmentLeft:
			result = [self _renderLeftAtX:x y:y msg:text];
			break;
		case AZTextAlignmentCenter:
			result = [self _renderCenterAtX:x y:y msg:text];
			break;
		case AZTextAlignmentRight:
			result = [self _renderRightAtX:x y:y msg:text];
			break;
		default:
			break;
		}
	return result;
	}

/*****************************************************************************\
|* Center vertically in a box, respecting alignment
\*****************************************************************************/
- (NSRect) drawInBox:(NSRect)box text:(NSString *)text
	{
	int Y = NSMidY(box) - _font.height/2 -1;

	switch (_alignment)
		{
		case AZTextAlignmentLeft:
			return [self drawAtX:NSMinX(box) y:Y text:text];
		case AZTextAlignmentCenter:
			return [self drawAtX:NSMidX(box) y:Y text:text];
		case AZTextAlignmentRight:
			return [self drawAtX:NSMaxX(box) y:Y text:text];
		default:
			return NSZeroRect;
		}
	}

/*****************************************************************************\
|* Draw text within a limiting box, making words wrap appropriately
|* - with colour
|* - with horizontal alignment
|* - with scale
\*****************************************************************************/
- (NSRect) drawColumnsInBox:(NSRect)box text:(NSString *)text
	{
	BOOL useClip = [_renderer clipEnabled];

	NSRect oldClip = NSZeroRect;		// Keep clang happy
	NSRect newClip;
    if (useClip)
		{
		oldClip = _renderer.clipRect;
		newClip	= NSIntersectionRect(oldClip, box);
		}
    else
        newClip = box;

	[_renderer setClip:newClip];

	[_font setColourForAllCaches:_colour];
	[self _drawColumnFor:text inBox:box];

    if (useClip)
		[_renderer setClip:oldClip];
    else
		[_renderer unsetClip];

    return box;
	}

/*****************************************************************************\
|* Renderer method - override in a subclass to change how it's rendered
\*****************************************************************************/
- (NSRect) renderFrom:(NSRect)srcRect in:(NSInteger)textureId at:(NSPoint)p
	{
	// Take a local copy since we modify it here
	AZScale scale = _scale;

    NSRect result;

	AZFlipMode flip = AZFlipNone;
	if (scale.x < 0)
		{
		scale.x = -scale.x;
		flip =  (flip | AZFlipHorizontal);
		}
	if (scale.y < 0)
		{
		scale.y = -scale.y;
		flip = (flip | AZFlipVertical);
		}

	float dstW		= scale.x * srcRect.size.width;
	float dstH		= scale.y * srcRect.size.height;
	NSRect dstRect 	= NSMakeRect(p.x, p.y, dstW, dstH);
	[_renderer blitFrom:textureId
					src:srcRect
					dst:dstRect
				  angle:_angle
				 center:_rotateAbout
				   flip:flip];

	result.origin 		= p;
	result.size.width 	= srcRect.size.width  * scale.x;
	result.size.height 	= srcRect.size.height * scale.y;
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
	switch (_alignment)
		{
		case AZTextAlignmentCenter:
			x += box.size.width/2;
			break;
		case AZTextAlignmentRight:
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
	NSArray *linebroken				  = [text componentsSeparatedByString:@"\n"];
	NSMutableArray *words			  = [NSMutableArray new];
	for (NSString *txt in linebroken)
		{
		NSArray<NSString *> *txtWords   = [txt componentsSeparatedByString:@" "];
		[words addObjectsFromArray:txtWords];
		if (keep)
			[words addObject:@"\n"];
		}

	int spaceWidth					  = [self textWidthFor:@" "];

	for (NSString *word in words)
		{
		int wordWidth 		= [self textWidthFor:word];

		if ([word isEqualToString:@"\n"])
			{
			[lines addObject:[line copy]];
			[line setString:@""];
			w = 0;
			}
		else if (w == 0)
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
			y       += _scale.y * _font.baseline;
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

    if (_font.textures.count == 0)
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
