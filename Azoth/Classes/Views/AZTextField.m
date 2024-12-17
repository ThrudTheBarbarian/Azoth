//
//  AZTextField.m
//  Azoth
//
//  Created by Simon Gornall on 12/16/24.
//

#import <SDL3/SDL.h>

#import "AZApp.h"
#import "AZColour.h"
#import "AZNotifications.h"
#import "AZTextField.h"
#import "AZTypes.h"
#import "AZWindow.h"

enum
	{
	STATE_SN = 0,				// Square bezel
	STATE_SF,					// Square bezel, focused
	STATE_SD,					// Square bezel, disabled

	STATE_RN,					// Rounded bezel
	STATE_RF,					// Rounded bezel, focusedd
	STATE_RD,					// Rounded bezel, disabled

	STATE_NUM
	};

static SDL_FRect	_bTL[STATE_NUM];
static SDL_FRect	_bTM[STATE_NUM];
static SDL_FRect	_bTR[STATE_NUM];
static SDL_FRect	_bCL[STATE_NUM];
static SDL_FRect	_bCM[STATE_NUM];
static SDL_FRect	_bCR[STATE_NUM];
static SDL_FRect	_bBL[STATE_NUM];
static SDL_FRect	_bBM[STATE_NUM];
static SDL_FRect	_bBR[STATE_NUM];

static int 			_lineHeight = 29;

@implementation AZTextField

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super initWithFrame:frame])
		{
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken,
			^{
			[self _fetchRects];
			});

		self.bgColour 		= [AZColour clearColour];
		self.stringValue 	= @"Button";
		}
	return self;
	}

+ (AZTextField *) textfieldWithFrame:(NSRect)frame
	{
	return [[AZTextField alloc] initWithFrame:frame];
	}


/*****************************************************************************\
|* A control was focussed - if it's not us, then make sure we're not in the
|* visibly-focused state
\*****************************************************************************/
- (void) controlFocused:(NSNotification *)n
	{
	if (n.object != self)
		if (self.state != ControlStateNormal)
			{
			self.state = ControlStateNormal;
			[self setNeedsDisplay:YES];
			}
	}

// MARK: Responder interactions

/*****************************************************************************\
|* indicates whether we accept first responder status
\*****************************************************************************/
- (BOOL) acceptsFirstResponder
	{
	return YES;
	}

/*****************************************************************************\
|* Return YES to accept becoming the first responder. Called from the AZWindow
|* makeFirstResponder method. Do not invoke directly
\*****************************************************************************/
- (BOOL) becomeFirstResponder
	{
	if (self.state == ControlStateNormal)
		{
		self.state = ControlStateHighlighted;
		[self setNeedsDisplay:YES];
		}
	return YES;
	}

/*****************************************************************************\
|* Return YES to accept un-becoming the first responder. Called from the
|* AZWindow makeFirstResponder method. Do not invoke directly. Subclasses can
|* override this method to update state or perform some action such as
|* unhighlighting the selection, or to return false, refusing to relinquish
|* first responder status
\*****************************************************************************/
- (BOOL) resignFirstResponder
	{
	if (self.state != ControlStateNormal)
		{
		self.state = ControlStateNormal;
		[self setNeedsDisplay:YES];
		}
	return YES;
	}


/*****************************************************************************\
|* Draw the textField
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[super drawInRect:dirtyRect withPainter:painter];

	if (_type == TextFieldSquare)
		[self _drawSquareTextFieldWithRect:dirtyRect andPainter:painter];
	else
		[self _drawRoundTextFieldWithRect:dirtyRect andPainter:painter];
	}

- (void) _drawRoundTextFieldWithRect:(NSRect)r andPainter:(AZPainter *)p
	{
	}

- (void) _drawSquareTextFieldWithRect:(NSRect)r andPainter:(AZPainter *)p
	{
	SDL_FRect sTL		= _bTL[self.state + _type];
	SDL_FRect sTM		= _bTM[self.state + _type];
	SDL_FRect sTR		= _bTR[self.state + _type];

	SDL_FRect sCL		= _bCL[self.state + _type];
	SDL_FRect sCM		= _bCM[self.state + _type];
	SDL_FRect sCR		= _bCR[self.state + _type];

	SDL_FRect sBL		= _bBL[self.state + _type];
	SDL_FRect sBM		= _bBM[self.state + _type];
	SDL_FRect sBR		= _bBR[self.state + _type];

	float W				= self.bounds.size.width  - 1;
	float H				= self.bounds.size.height - 1;

	SDL_FRect dTL		= {0, H-sTL.h, sTL.w, sTL.h};
	SDL_FRect dTM		= {sTL.w, H-sTM.h, W-sTL.w-sTR.w, sTM.h};
	SDL_FRect dTR		= {W-sTR.w, H-sTR.h, sTR.w, sTR.h};

	SDL_FRect dCL		= {0, sBL.h, sCL.w, H-sTL.h-sBL.h};
	SDL_FRect dCM		= {sCL.w, sCM.h, W-sCL.w-sCR.w, H-sTM.h-sBM.h};
	SDL_FRect dCR		= {W-sCR.w, sBR.h, sCR.w, H-sTR.h-sBR.h};

	SDL_FRect dBL		= {0, 0, sBL.w, sBL.h};
	SDL_FRect dBM		= {sBL.w, 0, W-sBL.w-sBR.w, sBM.h};
	SDL_FRect dBR		= {W-sBR.w, 0, sBR.w, sBR.h};

	SDL_Texture *src	= AZApp.sharedInstance.ui;
	SDL_Renderer *rndr	= AZApp.sharedInstance.window.renderer;

	SDL_SetRenderDrawBlendMode(rndr, SDL_BLENDMODE_ADD);

	SDL_RenderTexture	  (rndr, src, &sTL,    &dTL);
	SDL_RenderTextureTiled(rndr, src, &sTM, 1, &dTM);
	SDL_RenderTexture     (rndr, src, &sTR,    &dTR);

	SDL_RenderTextureTiled(rndr, src, &sCL, 1, &dCL);
	SDL_RenderTextureTiled(rndr, src, &sCM, 1, &dCM);
	SDL_RenderTextureTiled(rndr, src, &sCR, 1, &dCR);

	SDL_RenderTexture	  (rndr, src, &sBL,    &dBL);
	SDL_RenderTextureTiled(rndr, src, &sBM, 1, &dBM);
	SDL_RenderTexture     (rndr, src, &sBR,    &dBR);
	}


/*****************************************************************************\
|* Handle a mouse press
\*****************************************************************************/
- (BOOL) mouseDown:(SDL_MouseButtonEvent *)e
	{
	[self.window makeFirstResponder:self];
	return YES;
	}

// MARK: Private methods

/*****************************************************************************\
|* Populate the rectangles from the UI texture atlas
\*****************************************************************************/
- (void) _fetchRects
	{
	AZApp *app 			 = AZApp.sharedInstance;

	_bBL[STATE_SN] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-0"]);
	_bBM[STATE_SN] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-1"]);
	_bBR[STATE_SN] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-2"]);
	_bCL[STATE_SN] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-3"]);
	_bCM[STATE_SN] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-4"]);
	_bCR[STATE_SN] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-5"]);
	_bTL[STATE_SN] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-6"]);
	_bTM[STATE_SN] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-7"]);
	_bTR[STATE_SN] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-8"]);

	_bBL[STATE_SF] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-focused-0"]);
	_bBM[STATE_SF] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-focused-1"]);
	_bBR[STATE_SF] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-focused-2"]);
	_bCL[STATE_SF] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-focused-3"]);
	_bCM[STATE_SF] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-focused-4"]);
	_bCR[STATE_SF] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-focused-5"]);
	_bTL[STATE_SF] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-focused-6"]);
	_bTM[STATE_SF] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-focused-7"]);
	_bTR[STATE_SF] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-focused-8"]);

	_bBL[STATE_SD] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-disabled-0"]);
	_bBM[STATE_SD] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-disabled-1"]);
	_bBR[STATE_SD] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-disabled-2"]);
	_bCL[STATE_SD] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-disabled-3"]);
	_bCM[STATE_SD] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-disabled-4"]);
	_bCR[STATE_SD] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-disabled-5"]);
	_bTL[STATE_SD] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-disabled-6"]);
	_bTM[STATE_SD] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-disabled-7"]);
	_bTR[STATE_SD] = SDL_FRECT([app srcRectFor:@"textfield-bezel-square-disabled-8"]);

	_bCL[STATE_RN] = SDL_FRECT([app srcRectFor:@"textfield-bezel-rounded-left"]);
	_bCM[STATE_RN] = SDL_FRECT([app srcRectFor:@"textfield-bezel-rounded-center"]);
	_bCR[STATE_RN] = SDL_FRECT([app srcRectFor:@"textfield-bezel-rounded-right"]);

	_bCL[STATE_RF] = SDL_FRECT([app srcRectFor:@"textfield-bezel-rounded-focused-left"]);
	_bCM[STATE_RF] = SDL_FRECT([app srcRectFor:@"textfield-bezel-rounded-focused-center"]);
	_bCR[STATE_RF] = SDL_FRECT([app srcRectFor:@"textfield-bezel-rounded-focused-right"]);

	_bCL[STATE_RD] = SDL_FRECT([app srcRectFor:@"textfield-bezel-rounded-disabled-left"]);
	_bCM[STATE_RD] = SDL_FRECT([app srcRectFor:@"textfield-bezel-rounded-disabled-center"]);
	_bCR[STATE_RD] = SDL_FRECT([app srcRectFor:@"textfield-bezel-rounded-disabled-right"]);

	for (int i=STATE_RN; i<=STATE_RD; i++)
		{
		_lineHeight = MAX(_bCL[i].h, _lineHeight);
		_lineHeight = MAX(_bCM[i].h, _lineHeight);
		_lineHeight = MAX(_bCR[i].h, _lineHeight);
		}
	}
@end
