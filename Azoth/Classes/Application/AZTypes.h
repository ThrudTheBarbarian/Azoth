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


#endif // ! __AZTypes_header__
