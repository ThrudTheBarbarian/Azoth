//
//  AZTextPainter.h
//  Azoth
//
//  Created by Simon Gornall on 12/14/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*****************************************************************************\
|* Type declarations
\*****************************************************************************/
@class AZColour;
@class AZFont;

struct SDL_Renderer;
struct SDL_Texture;

/*****************************************************************************\
|* Alignment constants
\*****************************************************************************/
typedef enum
	{
	AZFONT_VALIGN_BASE = 0,
	AZFONT_VALIGN_HALF,
	AZFONT_VALIGN_ASCENT,
	AZFONT_VALIGN_BOTTOM,
	AZFONT_VALIGN_DESCENT,
	AZFONT_VALIGN_TOP,
	AZFONT_VALIGN_MAX
	} AZFontVAlign; // Currently not implemented

typedef enum
	{
	AZFONT_HALIGN_LEFT = 0,
	AZFONT_HALIGN_CENTER,
	AZFONT_HALIGN_RIGHT,
	AZFONT_HALIGN_MAX
	} AZFontHAlign;

/*****************************************************************************\
|* Font effects
\*****************************************************************************/
typedef struct
	{
	AZFontHAlign hAlign;
	AZFontVAlign vAlign;
	float xScale;
	float yScale;
	uint8_t r, g, b, a;
	} AZFontEffect;

@interface AZTextPainter : NSObject
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithRenderer:(struct SDL_Renderer *)renderer;
+ (AZTextPainter *) painterWithRenderer:(struct SDL_Renderer *)renderer;

/*****************************************************************************\
|* Basic drawing routines
\*****************************************************************************/
- (NSRect) drawAtX:(float)x y:(float)y text:(NSString *)text;
- (NSRect) drawAtX:(float)x y:(float)y colour:(AZColour *)colour
		   format:(NSString *)fmt, ...;
- (NSRect) drawAtX:(float)x y:(float)y r:(uint8_t)r g:(uint8_t)g b:(uint8_t)b
		   a:(uint8_t)a format:(NSString *)fmt, ...;
- (NSRect) drawAtX:(float)x y:(float)y hAlign:(AZFontHAlign)hAlign
		   format:(NSString *)fmt, ...;
- (NSRect) drawAtX:(float)x y:(float)y hAlign:(AZFontHAlign)hAlign
		   colour:(AZColour *)colour format:(NSString *)fmt, ...;
- (NSRect) drawAtX:(float)x y:(float)y hAlign:(AZFontHAlign)hAlign
		   r:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
		   format:(NSString *)fmt, ...;

/*****************************************************************************\
|* Draw inside a clipping rectangle, moving words to make everything fit
\*****************************************************************************/
- (NSRect) drawInBox:(NSRect)box format:(NSString *)fmt, ...;
- (NSRect) drawInBox:(NSRect)box colour:(AZColour *)colour
		   format:(NSString *)fmt, ...;
- (NSRect) drawInBox:(NSRect)box r:(uint8_t)r g:(uint8_t)g b:(uint8_t)b
		   a:(uint8_t)a format:(NSString *)fmt, ...;
- (NSRect) drawInBox:(NSRect)box hAlign:(AZFontHAlign)hAlign
		   format:(NSString *)fmt, ...;
- (NSRect) drawInBox:(NSRect)box hAlign:(AZFontHAlign)hAlign
		   colour:(AZColour *)colour format:(NSString *)fmt, ...;
- (NSRect) drawInBox:(NSRect)box hAlign:(AZFontHAlign)hAlign
		   r:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
		   format:(NSString *)fmt, ...;

/*****************************************************************************\
|* Return the width, height of any text string in the current font
\*****************************************************************************/
- (int) textWidthFor:(NSString *)fmt, ...;
- (int) textHeightFor:(NSString *)fmt, ...;

/*****************************************************************************\
|* Rendering method
\*****************************************************************************/
- (NSRect) renderFrom:(NSRect)rect in:(struct SDL_Texture *)src
		   at:(NSPoint)p xscale:(float)xscale yscale:(float)yscale;


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
					    a:(uint8_t)a;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Renderer for drawing with
@property(assign, nonatomic) struct SDL_Renderer *			renderer;

// Font to use
@property(strong, nonatomic) AZFont *						font;

// Angle to draw at (0, 90, 180, 270)
@property(assign, nonatomic) int							angle;

@property(assign, nonatomic) struct SDL_FPoint				rotateAbout;
@end

NS_ASSUME_NONNULL_END
