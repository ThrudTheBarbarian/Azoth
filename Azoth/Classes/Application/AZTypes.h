//
//  AZTypes.h
//  Azoth
//
//  Created by Simon Gornall on 12/14/24.
//
#ifndef __AZTypes_header__
#define __AZTypes_header__

struct SDL_Color;

/*****************************************************************************\
|* Style definitions for font creation
\*****************************************************************************/
enum
	{
	AZFONT_STYLE_NORMAL 			= 0x00,
	AZFONT_STYLE_BOLD   			= 0x01,
	AZFONT_STYLE_ITALIC				= 0x02,
	AZFONT_STYLE_UNDERLINE			= 0x04,
	AZFONT_STYLE_STRIKETHROUGH		= 0x08,
	AZFONT_STYLE_OUTLINE			= 0x10
	};

/*****************************************************************************\
|* Structure that defines a font's look and feel. The 'stylebits' corresponds
|* to the enum above
\*****************************************************************************/
typedef struct AZFontStyle
	{
	NSString *path;				// Location on disk
	int size;					// In points
	uint8_t r,g,b,a;			// Default colour to paint with
	int stylebits;				// Collection of above enums
	} AZFontStyle;


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
|* Scale factor
\*****************************************************************************/
typedef struct
	{
	float x;	// X-scaling
	float y;	// Y-scaling
	} AZScale;

/*****************************************************************************\
|* Font effects
\*****************************************************************************/
typedef struct
	{
	AZFontHAlign hAlign;
	AZFontVAlign vAlign;
	uint8_t r, g, b, a;
	} AZFontEffect;

/*****************************************************************************\
|* Conversion macros
\*****************************************************************************/
#define SDL_RECT(nsrect)													\
	(SDL_Rect){nsrect.origin.x,												\
			   nsrect.origin.y,												\
			   nsrect.size.width,											\
			   nsrect.size.height}

#define NS_RECT(sdlrect)													\
	NSMakeRect(sdlrect.x, sdlrect.y, sdlrect.w, sdlrect.h)

#endif // ! __AZTypes_header__
