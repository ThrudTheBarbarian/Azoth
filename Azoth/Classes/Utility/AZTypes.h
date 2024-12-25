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
|* Types of splitview pane divider
\*****************************************************************************/
typedef enum
	{
    AZSplitViewDividerStyleThick = 1,
    AZSplitViewDividerStyleThin,
    AZSplitViewDividerStylePaneSplitter,
	} AZSplitViewDividerStyle;

/*****************************************************************************\
|* Alignment constants
\*****************************************************************************/
typedef enum
	{
	AZTextAlignmentLeft = 0,
	AZTextAlignmentRight,
	AZTextAlignmentCenter,

	// Not implemented below here
	AZTextAlignmentJustified,
	AZTextAlignmentNatural,

	AZTextAlignmentMax
	} AZTextAlignment;

/*****************************************************************************\
|* Ruler view types
\*****************************************************************************/
typedef enum
	{
	AZHorizontalRuler		= 1,
	AZVerticalRuler			= 2,
	} AZRulerOrientation;

/*****************************************************************************\
|* Scrollbar area types
\*****************************************************************************/
typedef enum
	{
	AZScrollerIncrementLine	= 1,
	AZScrollerDecrementLine,
	AZScrollerIncrementPage,
	AZScrollerDecrementPage,
	AZScrollerKnob
	} AZScrollerPart;

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
	AZTextAlignment alignment;
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
|* Border types within Azoth
\*****************************************************************************/
typedef enum
	{
	AZNoBorder	 	= 0,
	AZLineBorder	= 1,
	AZBezelBorder 	= 2,
	AZGrooveBorder	= 3
	} AZBorderType;


/*****************************************************************************\
|* Control states
\*****************************************************************************/
typedef enum
	{
	AZControlStateValueOff 	= 0,
	AZControlStateValueOn 	= 1,
	AZControlStateValueMixed 	= 2
	} AZControlStateValue;


/*****************************************************************************\
|* Orientation of text within buttons relative to an image
\*****************************************************************************/
typedef enum
	{
	AZNoImage				= 0,
	AZImageOnly	,
	AZImageLeading,
	AZImageTrailing,
	AZImageLeft,
	AZImageRight,
	AZImageAbove,
	AZImageBelow
	} AZCellImagePosition;

/*****************************************************************************\
|* Measurement of popup menus
\*****************************************************************************/
typedef struct
	{
	NSRect frame;					// Calculated width and height of frame
	NSInteger topHeight;			// Space for curved top
	NSInteger bottomHeight;			// Space for curved bottom
	int flagsUsed;					// For posterity
	int fontHeight;					// Size of the font used (bar height too)
	} AZMenuSize;

typedef enum
	{
	AZMENU_RENDER_TOP		= 1,
	AZMENU_RENDER_BOTTOM	= 2,
	AZMENU_SHOW_TITLE		= 4
	} AZMenuRenderFlag;


/*****************************************************************************\
|* Popup menu callback
\*****************************************************************************/
typedef void (^MenuDoneBlock)(BOOL menuClicked);

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
