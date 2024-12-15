//
//  AZFont.h
//  Azoth
//
//  Created by Simon Gornall on 12/14/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*****************************************************************************\
|* Forward references
\*****************************************************************************/

struct SDL_Renderer;
struct SDL_Color;

@class AZGlyphData;
@class AZObject;

/*****************************************************************************\
|* Style definitions for font creation
\*****************************************************************************/
enum
	{
	STYLE_NORMAL 			= TTF_STYLE_NORMAL,
	STYLE_BOLD   			= TTF_STYLE_BOLD,
	STYLE_ITALIC			= TTF_STYLE_ITALIC,
	STYLE_UNDERLINE			= TTF_STYLE_UNDERLINE,
	STYLE_STRIKETHROUGH		= TTF_STYLE_STRIKETHROUGH,
	STYLE_OUTLINE			= 16
	};

/*****************************************************************************\
|* Structure that defines a font's look and feel. The 'stylebits' corresponds
|* to the enum above
\*****************************************************************************/
typedef struct AZFontStyle
	{
	NSString *path;				// Location on disk
	int size;					// In points
	struct SDL_Color colour;	// Default colour to paint with
	int stylebits;				// Collection of above enums
	} AZFontStyle;

@interface AZFont : NSObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithRenderer:(struct SDL_Renderer *)renderer;
+ (AZFont *) fontWithRenderer:(struct SDL_Renderer *)renderer;

/*****************************************************************************\
|* Load a font
\*****************************************************************************/
- (BOOL) load:(AZFontStyle)style;
- (BOOL) load:(struct TTF_Font *)font colour:(struct SDL_Color)colour;

/*****************************************************************************\
|* Set the default colour to use, for all the caches
\*****************************************************************************/
- (void) setColourForAllCaches:(struct SDL_Color)colour;

/*****************************************************************************\
|* Get the data for a glyph
\*****************************************************************************/
- (nullable AZGlyphData *) glyphDataFor:(unichar)codepoint;

/*****************************************************************************\
|* Get the cache image for a given cache-id
\*****************************************************************************/
- (nullable struct SDL_Texture *) glyphsFor:(NSInteger)cacheId;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Which characters to cache by default
@property(strong, nonatomic) NSString *						loadingString;

// Number of spaces in \t
@property(assign, nonatomic) int							tabWidth;

// Renderer for drawing with
@property(assign, nonatomic) struct SDL_Renderer *			renderer;

// The underlying TrueType font this AZFont uses
@property(assign, nonatomic) struct TTF_Font *				ttfFont;

// Can we delete the TTF font, or does someone else own it
@property(assign, nonatomic) BOOL 							ownsTTF;

// Default drawing colour
@property(assign, nonatomic) struct SDL_Color				defaultColour;

// Height of font in points
@property(assign, nonatomic) int							height;

// Max width of any char
@property(assign, nonatomic) int							maxWidth;

// Baseline position
@property(assign, nonatomic) int							baseline;

// Ascent of the font
@property(assign, nonatomic) int							ascent;

// Descent of the font
@property(assign, nonatomic) int							descent;

// Line-spacing for \n
@property(assign, nonatomic) int							lineSpacing;

// Letter-spacing between glyphs
@property(assign, nonatomic) int							letterSpacing;

// Can render to the target ?
@property(assign, nonatomic) BOOL							renderToTarget;

// Actual glyph data map
@property(strong, nonatomic) NSMutableArray<AZObject *> *	glyphs;
@end

NS_ASSUME_NONNULL_END
