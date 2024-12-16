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
|* to the enum above. The name should not include the .ttf extension
|*
|* The font will be searched for in the framework resources directory, the
|* app-delegate's resource directory, and in the user's Library/Fonts folder
|* unless it starts with a / and then it has to be an absolute path.
\*****************************************************************************/
typedef struct AZFontStyle
	{
	NSString *name;				// Font name
	int size;					// In points
	int style;					// Collection of above enums
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
|* Autoresizing mask
\*****************************************************************************/
enum AZAutoresizingMaskOptions
	{
	AZViewNotSizable	= 0x00,	// No changes to be made to the frame
	AZViewMinXMargin	= 0x01,	// Left margin is flexible
	AZViewWidthSizable	= 0x02,	// The width is flexible
	AZViewMaxXMargin	= 0x04,	// Right margin is flexible
	AZViewMinYMargin	= 0x08,	// Bottom margin is flexible
	AZViewHeightSizable	= 0x10,	// The height is flexible
	AZViewMaxYMargin	= 0x20	// Top margin is flexible
	};

/*****************************************************************************\
|* Conversion macros
\*****************************************************************************/
#define SDL_RECT(nsrect)													\
	(SDL_Rect){nsrect.origin.x,												\
			   nsrect.origin.y,												\
			   nsrect.size.width,											\
			   nsrect.size.height}

#define SDL_FRECT(nsrect)													\
	(SDL_FRect){nsrect.origin.x,											\
			    nsrect.origin.y,											\
			    nsrect.size.width,											\
			    nsrect.size.height}

#define NS_RECT(sdlrect)													\
	NSMakeRect(sdlrect.x, sdlrect.y, sdlrect.w, sdlrect.h)

#endif // ! __AZTypes_header__
