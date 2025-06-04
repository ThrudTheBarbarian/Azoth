//
//  AZFont.h
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <Foundation/Foundation.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

/*****************************************************************************\
|* Forward references
\*****************************************************************************/

struct SDL_Color;
struct TTF_Font;

@class AZColour;
@class AZGlyphData;
@class AZObject;

@interface AZFont : NSObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
+ (AZFont *) font;
+ (nullable AZFont *) fontWithStyle:(AZFontStyle)style;
+ (nullable AZFont *) fontWithName:(NSString *)name size:(int)points;
+ (nullable AZFont *) systemFontWithSize:(int)points;

/*****************************************************************************\
|* Load a font
\*****************************************************************************/
- (BOOL) load:(AZFontStyle)style;
- (BOOL) loadFont:(struct TTF_Font *)font;

/*****************************************************************************\
|* Set the default colour to use, for all the caches
\*****************************************************************************/
- (void) setColourForAllCaches:(AZColour *)colour;

/*****************************************************************************\
|* Get the data for a glyph
\*****************************************************************************/
- (nullable AZGlyphData *) glyphDataFor:(unichar)codepoint;

/*****************************************************************************\
|* Get the cache image for a given cache-id
\*****************************************************************************/
- (NSInteger) glyphsFor:(NSInteger)cacheId;

/*****************************************************************************\
|* Return the width of a text string in this font
\*****************************************************************************/
- (int) textWidthFor:(NSString *)text;

/*****************************************************************************\
|* Return the bounds of a text string in this font
\*****************************************************************************/
- (NSSize) boundsFor:(NSString *)text;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Which characters to cache by default
@property(strong, nonatomic) NSString *						loadingString;

// Number of spaces in \t
@property(assign, nonatomic) int							tabWidth;

// The underlying TrueType font this AZFont uses
@property(assign, nonatomic) struct TTF_Font *				ttfFont;

// Can we delete the TTF font, or does someone else own it
@property(assign, nonatomic) BOOL 							ownsTTF;

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
@property(strong, nonatomic) NSMutableArray<NSNumber *> *	textures;
@end

NS_ASSUME_NONNULL_END
