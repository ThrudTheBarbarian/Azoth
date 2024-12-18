//
//  AZButton.m
//  Azoth
//
//  Created by Simon Gornall on 12/15/24.
//

#import <SDL3/SDL.h>

#import "AZApp.h"
#import "AZButton.h"
#import "AZColour.h"
#import "AZFont.h"
#import "AZPainter.h"
#import "AZWindow.h"

#define BUTTON_HEIGHT 		25
#define BUTTON_LEADING   	12
#define BUTTON_TRAILING		12
enum
	{
	STATE_N	= 0,				// Normal
	STATE_H,					// Highlighted
	STATE_D,					// Disabled

	STATE_DN,					// Default, normal
	STATE_DH,					// Default, highlighted
	STATE_DD,					// Default, disabled

	STATE_RN,					// Rounded, normal
	STATE_RH,					// Rounded, highlighted
	STATE_RD,					// Rounded, disabled

	STATE_RDN,					// Roumded, default, normal
	STATE_RDH,					// Rounded, default, highlight
	STATE_RDD,					// Rounded, default, disabled

	STATE_NUM
	};

static SDL_FRect	_bLeft[STATE_NUM];
static SDL_FRect	_bCenter[STATE_NUM];
static SDL_FRect	_bRight[STATE_NUM];

@implementation AZButton

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
		_type		 		= ButtonTypePlain;
		}
	return self;
	}

+ (AZButton *) buttonWithFrame:(NSRect)frame
	{
	return [[AZButton alloc] initWithFrame:frame];
	}

+ (AZButton *) buttonWithText:(NSString *)text at:(NSPoint)p
	{
	AZApp *app 			= AZApp.sharedInstance;
	int width  			= [app.controlFont textWidthFor:text]
						+ BUTTON_LEADING + BUTTON_TRAILING;
	NSRect frame		= NSMakeRect(p.x, p.y, width, BUTTON_HEIGHT);
	AZButton *button	= [[AZButton alloc] initWithFrame:frame];
	button.stringValue	= text;
	return button;
	}

/*****************************************************************************\
|* Draw the button
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[super drawInRect:dirtyRect withPainter:painter];

	SDL_FRect srcL		= _bLeft[self.state + _type];
	SDL_FRect srcC		= _bCenter[self.state + _type];
	SDL_FRect srcR		= _bRight[self.state + _type];

	int stretch 		= self.bounds.size.width - srcL.w - srcR.w;
	SDL_FRect dstL		= {0, 0, srcL.w, srcL.h};
	SDL_FRect dstC  	= {srcL.w, 0, stretch, srcC.h};
	SDL_FRect dstR		= {srcL.w+stretch, 0, srcR.w, srcR.h};

	SDL_Texture *src	= AZApp.sharedInstance.ui;
	SDL_Renderer *rndr	= AZApp.sharedInstance.window.renderer;

	SDL_SetRenderDrawBlendMode(rndr, SDL_BLENDMODE_ADD);
	SDL_RenderTexture(rndr , src, &srcL, &dstL);
	SDL_RenderTextureTiled(rndr , src, &srcC, 1, &dstC);
	SDL_RenderTexture(rndr , src, &srcR, &dstR);

	[painter setTextAlignment:AZFONT_HALIGN_CENTER];

	switch (_type)
		{
		case ButtonTypeRoundedDefault:
		case ButtonTypeDefault:
			[painter setTextColour:[AZColour whiteColour]];
			break;
		default:
			[painter setTextColour:[AZColour blackColour]];
			break;
		}
	NSRect bounds = NSInsetRect(self.bounds, 0, 2);
	[painter drawInBox:bounds text:self.stringValue];
	}


/*****************************************************************************\
|* Handle a mouse press
\*****************************************************************************/
- (BOOL) mouseDown:(SDL_MouseButtonEvent *)e
	{
	if (self.state == ControlStateNormal)
		{
		self.state = ControlStateHighlighted;
		[self setNeedsDisplay:YES];
		if ((self.target != nil) && (self.action != nil))
			{
			IMP imp = [self.target methodForSelector:self.action];
			void (*func)(id, SEL, id) = (void *)imp;
			func(self.target, self.action, self);
			}
		}
	return YES;
	}


/*****************************************************************************\
|* Handle a mouse release
\*****************************************************************************/
- (BOOL) mouseUp:(struct SDL_MouseButtonEvent *)e
	{
	if (self.state == ControlStateHighlighted)
		{
		self.state = ControlStateNormal;
		[self setNeedsDisplay:YES];
		}
	return YES;
	}

// MARK: Private methods

/*****************************************************************************\
|* Populate the rectangles from the UI texture atlas
\*****************************************************************************/
- (void) _fetchRects
	{
	AZApp *app 			 = AZApp.sharedInstance;
	_bLeft[STATE_N]   = SDL_FRECT([app srcRectFor:@"button-bezel-left"]);
	_bLeft[STATE_H]   = SDL_FRECT([app srcRectFor:@"button-bezel-highlighted-left"]);
	_bLeft[STATE_D]   = SDL_FRECT([app srcRectFor:@"button-bezel-disabled-left"]);

	_bLeft[STATE_RN]  = SDL_FRECT([app srcRectFor:@"button-bezel-rounded-left"]);
	_bLeft[STATE_RH]  = SDL_FRECT([app srcRectFor:@"button-bezel-rounded-highlighted-left"]);
	_bLeft[STATE_RD]  = SDL_FRECT([app srcRectFor:@"button-bezel-rounded-disabled-left"]);

	_bLeft[STATE_DN]  = SDL_FRECT([app srcRectFor:@"default-button-bezel-left"]);
	_bLeft[STATE_DH]  = SDL_FRECT([app srcRectFor:@"default-button-bezel-highlighted-left"]);
	_bLeft[STATE_DD]  = SDL_FRECT([app srcRectFor:@"default-button-bezel-disabled-left"]);

	_bLeft[STATE_RDN] = SDL_FRECT([app srcRectFor:@"default-button-bezel-rounded-left"]);
	_bLeft[STATE_RDH] = SDL_FRECT([app srcRectFor:@"default-button-bezel-rounded-highlighted-left"]);
	_bLeft[STATE_RDD] = SDL_FRECT([app srcRectFor:@"default-button-bezel-rounded-disabled-left"]);


	_bCenter[STATE_N]   = SDL_FRECT([app srcRectFor:@"button-bezel-center"]);
	_bCenter[STATE_H]   = SDL_FRECT([app srcRectFor:@"button-bezel-highlighted-center"]);
	_bCenter[STATE_D]   = SDL_FRECT([app srcRectFor:@"button-bezel-disabled-center"]);

	_bCenter[STATE_RN]  = SDL_FRECT([app srcRectFor:@"button-bezel-rounded-center"]);
	_bCenter[STATE_RH]  = SDL_FRECT([app srcRectFor:@"button-bezel-rounded-highlighted-center"]);
	_bCenter[STATE_RD]  = SDL_FRECT([app srcRectFor:@"button-bezel-rounded-disabled-center"]);

	_bCenter[STATE_DN]  = SDL_FRECT([app srcRectFor:@"default-button-bezel-center"]);
	_bCenter[STATE_DH]  = SDL_FRECT([app srcRectFor:@"default-button-bezel-highlighted-center"]);
	_bCenter[STATE_DD]  = SDL_FRECT([app srcRectFor:@"default-button-bezel-disabled-center"]);

	_bCenter[STATE_RDN] = SDL_FRECT([app srcRectFor:@"default-button-bezel-rounded-center"]);
	_bCenter[STATE_RDH] = SDL_FRECT([app srcRectFor:@"default-button-bezel-rounded-highlighted-center"]);
	_bCenter[STATE_RDD] = SDL_FRECT([app srcRectFor:@"default-button-bezel-rounded-disabled-center"]);


	_bRight[STATE_N]   = SDL_FRECT([app srcRectFor:@"button-bezel-right"]);
	_bRight[STATE_H]   = SDL_FRECT([app srcRectFor:@"button-bezel-highlighted-right"]);
	_bRight[STATE_D]   = SDL_FRECT([app srcRectFor:@"button-bezel-disabled-right"]);

	_bRight[STATE_RN]  = SDL_FRECT([app srcRectFor:@"button-bezel-rounded-right"]);
	_bRight[STATE_RH]  = SDL_FRECT([app srcRectFor:@"button-bezel-rounded-highlighted-right"]);
	_bRight[STATE_RD]  = SDL_FRECT([app srcRectFor:@"button-bezel-rounded-disabled-right"]);

	_bRight[STATE_DN]  = SDL_FRECT([app srcRectFor:@"default-button-bezel-right"]);
	_bRight[STATE_DH]  = SDL_FRECT([app srcRectFor:@"default-button-bezel-highlighted-right"]);
	_bRight[STATE_DD]  = SDL_FRECT([app srcRectFor:@"default-button-bezel-disabled-right"]);

	_bRight[STATE_RDN] = SDL_FRECT([app srcRectFor:@"default-button-bezel-rounded-right"]);
	_bRight[STATE_RDH] = SDL_FRECT([app srcRectFor:@"default-button-bezel-rounded-highlighted-right"]);
	_bRight[STATE_RDD] = SDL_FRECT([app srcRectFor:@"default-button-bezel-rounded-disabled-right"]);
	}
@end
