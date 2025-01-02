//
//  AZTypes.h
//  Azoth
//
//  Created by Simon Gornall on 12/14/24.
//
#ifndef __AZTypes_header__
#define __AZTypes_header__

#include <Foundation/Foundation.h>

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
|* Resizing types for table columns
\*****************************************************************************/
enum
	{
    AZTableColumnNoResizing 		= 0x00,
    AZTableColumnAutoresizingMask 	= 0x01,
    AZTableColumnUserResizingMask 	= 0x02,
	};

/*****************************************************************************\
|* Whether to draw table grid lines
\*****************************************************************************/
enum {
    AZTableViewGridNone						= 0,
    AZTableViewSolidVerticalGridLineMask	= 1,
    AZTableViewSolidHorizontalGridLineMask	= 2,
	AZTableViewSolidGridLineMask			= 1|2
	};

#define IS_GRID_STYLE(x, type) (((x) & (type)) == type)


/*****************************************************************************\
|* Drag and drop styles. NB: Drag and drop not yet supported. These are just
|* the constants
\*****************************************************************************/
typedef enum
	{
	AZDragOperationCopy 		= 1<<0,
	AZDragOperationLink			= 1<<1,
	AZDragOperationGeneric		= 1<<2,
	AZDragOperationPrivate		= 1<<3,
	AZDragOperationMove			= 1<<4,
	AZDragOperationDelete		= 1<<5,
	AZDragOperationEvery		= -1,
	AZDragOperationNone			= 0
	} NSDragOperation;

/*****************************************************************************\
|* Forms that highlighting can take
\*****************************************************************************/
enum {
    AZTableViewSelectionHighlightStyleNone 			= -1,
    AZTableViewSelectionHighlightStyleRegular 		= 0,
    AZTableViewSelectionHighlightStyleSourceList 	= 1,
};

/*****************************************************************************\
|* How drops work in tableviews
\*****************************************************************************/
typedef enum {
    AZTableViewDropOn,
    AZTableViewDropAbove
} AZTableViewDropOperation;


/*****************************************************************************\
|* AZEvent types
\*****************************************************************************/
typedef enum
	{
    AZLeftMouseDown 				= 1,
    AZLeftMouseUp 					= 2,
    AZRightMouseDown 				= 3,
    AZRightMouseUp 					= 4,
    AZMouseMoved 					= 5,
    AZLeftMouseDragged 				= 6,
    AZRightMouseDragged 			= 7,
    AZMouseEntered 					= 8,
    AZMouseExited 					= 9,
    AZKeyDown 						= 10,
    AZKeyUp 						= 11,
    AZFlagsChanged 					= 12,
    AZPeriodic 						= 13,
    AZCursorUpdate 					= 14,
    AZPlatformSpecific 				= 15,
    AZPlatformSpecificDisplayEvent 	= 16,
    AZAppKitSystem 					= 17,
    AZScrollWheel 					= 18,
    AZApplicationDefined 			= 19,
    AZAppKitDefined 				= 20
	} AZEventType;

/*****************************************************************************\
|* AZEvent button masks
\*****************************************************************************/
typedef enum
	{
	AZButtonLeft					= (1<<0),
	AZButtonMiddle					= (1<<1),
	AZButtonRight					= (1<<2),
	AZButton_X1						= (1<<3),
	AZButton_X2						= (1<<4)
	} AZButtonMask;

/*****************************************************************************\
|* AZEvent key modifier masks
\*****************************************************************************/
enum
	{
    AZAlphaShiftKeyMask 					= (0x0001u|0x0002u),
    AZShiftKeyMask 							= (0x0001u|0x0002u),
    AZControlKeyMask 						= (0x0040u|0x0080u),
    AZAlternateKeyMask 						= (0x0100u|0x0200u),
    AZCommandKeyMask 						= (0x0400u|0x0800u),
    AZDeviceIndependentModifierFlagsMask 	= 0xffff0000UL
	};

/*****************************************************************************\
|* AZEvent type masks
\*****************************************************************************/
enum
	{
    AZLeftMouseDownMask 			= 1 << AZLeftMouseDown,
    AZLeftMouseUpMask 				= 1 << AZLeftMouseUp,
    AZRightMouseDownMask 			= 1 << AZRightMouseDown,
    AZRightMouseUpMask 				= 1 << AZRightMouseUp,
    AZMouseMovedMask 				= 1 << AZMouseMoved,
    AZLeftMouseDraggedMask 			= 1 << AZLeftMouseDragged,
    AZRightMouseDraggedMask 		= 1 << AZRightMouseDragged,
    AZMouseEnteredMask 				= 1 << AZMouseEntered,
    AZMouseExitedMask 				= 1 << AZMouseExited,
    AZKeyDownMask 					= 1 << AZKeyDown,
    AZKeyUpMask 					= 1 << AZKeyUp,
    AZFlagsChangedMask 				= 1 << AZFlagsChanged,
    AZPeriodicMask 					= 1 << AZPeriodic,
    AZCursorUpdateMask 				= 1 << AZCursorUpdate,
    AZScrollWheelMask 				= 1 << AZScrollWheel,
    AZApplicationDefinedMask 		= 1 << AZApplicationDefined,
    AZAppKitDefinedMask 			= 1 << AZAppKitDefined,
    AZAnyEventMask = 0xffffffff,

    AZPlatformSpecificDisplayMask 	= 1 << AZPlatformSpecificDisplayEvent,
	};

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
|* Text-movement constants
\*****************************************************************************/
typedef enum
	{
	AZIllegalTextMovement	= 0,
	AZReturnTextMovement	= 1,
	AZTabTextMovement		= 2,
	AZBacktabTextMovement	= 3,
	AZLeftTextMovement		= 4,
	AZRightTextMovement		= 5,
	AZUpTextMovement		= 6,
	AZDownTextMovement		= 7,
	AZCancelTextMovement	= 8,
	AZOtherTextMovement		= 9
	} AZTextMovement;

#define AZTextMovementUserInfoKey	@"TextMovementUserInfoKey"

/*****************************************************************************\
|* Ruler view types
\*****************************************************************************/
typedef enum
	{
	AZHorizontalRuler		= 1,
	AZVerticalRuler			= 2,
	} AZRulerOrientation;

/*****************************************************************************\
|* AZImageView alignment types etc
\*****************************************************************************/
typedef enum
	{
    AZImageAlignCenter 		= 0,
    AZImageAlignTop,
    AZImageAlignTopLeft,
    AZImageAlignTopRight,
    AZImageAlignLeft,
    AZImageAlignBottom,
    AZImageAlignBottomLeft,
    AZImageAlignBottomRight,
    AZImageAlignRight
	} AZImageAlignment;

typedef enum
	{
    AZImageFrameNone = 0,
    AZImageFramePhoto,
    AZImageFrameGrayBezel,
    AZImageFrameGroove,
    AZImageFrameButton
	} AZImageFrameStyle;

typedef enum
	{
	// Scale image down if it is too large for destination. Preserve aspect.
    AZImageScaleProportionallyDown = 0,

	// Scale each dimension to exactly fit destination. Do not preserve aspect.
    AZImageScaleAxesIndependently,

    // Do not scale.
    AZImageScaleNone,

    // Scale image to maximum possible dimensions while (1) staying within
    // destination area (2) preserving aspect ratio
    AZImageScaleProportionallyUpOrDown,
	} AZImageScaling;

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
|* Flip modes. Copied from the SDL ones, but duplicated to keep the framework
|*             modularisation process happy
\*****************************************************************************/
typedef enum
	{
    AZFlipNone, 	     	// Do not flip
    AZFlipHorizontal,    	// flip horizontally
    AZFlipVertical       	// flip vertically
	} AZFlipMode;

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
	AZControlStateNormal			= 0,
	AZControlStateHighlighted		= 1,
	AZControlStateDisabled			= 2
	} AZControlState;

typedef enum
	{
	AZControlStateValueOff 			= 0,
	AZControlStateValueOn 			= 1,
	AZControlStateValueMixed 		= 2
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
|* Helper structures for notification management
\*****************************************************************************/
typedef struct
	{
	NSString *name;
	SEL selector;
	} AZNotifyMap;

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

#define IS_ZERORECT(x)	NSEqualRects((x),NSZeroRect)

/*****************************************************************************\
|* Less typing :)
\*****************************************************************************/
#define SELECTOR(x)		NSSelectorFromString(x)

#define AZApp			AZApplication.sharedApplication

/*****************************************************************************\
|* Memory aids
\*****************************************************************************/
#define SAFELY_FREE(x) do													\
		{                                                       			\
		free((void *)x);                      								\
		x = NULL;     		                       							\
		}                                                       			\
	while (false)

/*****************************************************************************\
|* Markers for things that might need to be implemented
\*****************************************************************************/
extern void _AZInvalidAbstractInvocation(SEL selector,
										 id object,
										 const char *file,
										 int line);

extern void _AZUnimplementedMethod(SEL selector,
								   id object,
								   const char *file,
								   int line);
#define AZUnimplementedMethod() 											\
    _AZUnimplementedMethod(_cmd, self, __FILE__, __LINE__)

#define AZInvalidAbstractInvocation() \
    _AZInvalidAbstractInvocation(_cmd, self, __FILE__, __LINE__)


/*****************************************************************************\
|* Platform names
\*****************************************************************************/
#ifdef __APPLE__
#  define AZPlatformResourceNameSuffix ""
#elif defined(WINDOWS)
#  define AZPlatformResourceNameSuffix "windows"
#elif defined __linux__
#  define AZPlatformResourceNameSuffix "linux"
#else
#  warning "Unknown platform!"
#endif

#endif // ! __AZTypes_header__
