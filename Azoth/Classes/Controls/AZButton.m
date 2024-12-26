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
#import "AZNotifications.h"
#import "AZPainter.h"
#import "AZRenderer.h"
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

	STATE_CN,					// Checkbox normal
	STATE_CK,					// Checkbox checked
	STATE_CD,					// Checkbox disabled

	STATE_NR,					// Radio normal
	STATE_SR,					// Radio selected
	STATE_DR,					// Radio disabled

	STATE_NUM
	};

static NSRect	_bLeft[STATE_NUM];
static NSRect	_bCenter[STATE_NUM];
static NSRect	_bRight[STATE_NUM];

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

		self.backgroundColour 	= [AZColour clearColour];
		self.stringValue 		= @"Button";
		self.imagePosition		= AZImageLeft;		// Only used in checkbox
		self.type	 			= ButtonTypePlain;
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
|* Clean up
\*****************************************************************************/
- (void) dealloc
	{
	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
	[nc removeObserver:self];
	}

/*****************************************************************************\
|* If we set the type to be a radio button, listen for broadcasts of being set
\*****************************************************************************/
- (void) setType:(AZButtonType)type
	{
	_type = type;

	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
	if (_type == ButtonTypeRadio)
		[nc addObserver:self
			   selector:@selector(radioButtonPressed:)
				   name:AZRadioButtonPressedNotification
				 object:nil];
	else
		[nc removeObserver:self];
	}

/*****************************************************************************\
|* If we set the radio buttom group, send out a signal that we toggled, so at
|* least one entry in the radio group is always toggled on
\*****************************************************************************/
- (void) setRadioGroup:(NSString *)radioGroup
	{
	_radioGroup = radioGroup;
	[self _toggleButtonToggled];
	}

/*****************************************************************************\
|* Draw the button
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	if (self.type >= ButtonTypeCheckbox)
		return [self _drawCheckboxInRect:dirtyRect withPainter:painter];

	NSRect bounds	= self.bounds;
	[super drawInRect:dirtyRect withPainter:painter];

	NSRect srcL		= _bLeft[self.state + _type];
	NSRect srcC		= _bCenter[self.state + _type];
	NSRect srcR		= _bRight[self.state + _type];

	int stretch 	= bounds.size.width - srcL.size.width - srcR.size.width;
	NSRect dstL		= NSMakeRect(0, 0, srcL.size.width, srcL.size.height);
	NSRect dstC  	= NSMakeRect(srcL.size.width, 0, stretch, srcC.size.height);
	NSRect dstR		= NSMakeRect(srcL.size.width + stretch, 0,
								 srcR.size.width, srcR.size.height);

	AZRenderer *azr		= AZRenderer.renderer;
	NSInteger ui		= AZApp.sharedInstance.ui;

	[azr setBlendMode:SDL_BLENDMODE_ADD];
	[azr blitFrom:ui src:srcL dst:dstL];
	[azr tileFrom:ui src:srcC dst:dstC];
	[azr blitFrom:ui src:srcR dst:dstR];

	[painter setTextAlignment:AZTextAlignmentCenter];

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
	NSRect box = NSInsetRect(bounds, 0, 2);
	[painter drawInBox:box text:self.stringValue];
	}


/*****************************************************************************\
|* Draw a checkbox button
\*****************************************************************************/
- (void) _drawCheckboxInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[super drawInRect:dirtyRect withPainter:painter];

	NSRect b		= self.bounds;
	int W			= b.size.width;
	int H			= b.size.height;

	NSRect src		= _bCenter[self.state + _type];
	NSRect dst		= src;
	BOOL rhs		= (self.imagePosition == AZImageRight)
					| (self.imagePosition == AZImageTrailing);
	int by			= (H-NSHeight(src))/2;
	dst.origin  	= rhs ? NSMakePoint(W-NSWidth(src), by) : NSMakePoint(0, by);

	AZRenderer *azr	= AZRenderer.renderer;
	NSInteger ui	= AZApp.sharedInstance.ui;

	[azr setBlendMode:SDL_BLENDMODE_ADD];
	[azr blitFrom:ui src:src dst:dst];

	if (!self.enabled)
		[painter setTextColour:[AZColour grey75Colour]];
	else
		[painter setTextColour:[AZColour blackColour]];

	AZFont *font	= AZApp.sharedInstance.controlFont;
	int y			= H/2-font.baseline/2;
	int textW		= [font textWidthFor:self.stringValue];
	int x			= rhs ? NSMaxX(dst) - textW - 5 : NSMaxX(dst) + 5;

	[painter drawAtX:x y:y text:self.stringValue];
	}

/*****************************************************************************\
|* Handle a mouse press
\*****************************************************************************/
- (BOOL) mouseDown:(AZEvent *)e
	{
	if (self.state ==ControlStateDisabled)
		return NO;

	if (self.type >= ButtonTypeCheckbox)
		[self _toggleButtonToggled];

	else if (self.state == ControlStateNormal)
		{
		self.state = ControlStateHighlighted;
		[self setNeedsDisplay:YES];
		[self sendAction:self.action to:self.target];
		}
	return YES;
	}


/*****************************************************************************\
|* Handle a mouse release
\*****************************************************************************/
- (BOOL) mouseUp:(AZEvent *)e
	{
	if (self.state ==ControlStateDisabled)
		return NO;

	if (self.type < ButtonTypeCheckbox)
		if (self.state == ControlStateHighlighted)
			{
			self.state = ControlStateNormal;
			[self setNeedsDisplay:YES];
			}
	return YES;
	}

// MARK: Notifications

- (void) radioButtonPressed:(NSNotification *)n
	{
	if (self == n.object)
		return;

	if (![n.userInfo[@"group"] isEqualToString:_radioGroup])
		return;

	[self setState:ControlStateNormal];
	[self setNeedsDisplay:YES];
	}

// MARK: Private methods

/*****************************************************************************\
|* Process a click on a radio button
\*****************************************************************************/
- (void) _toggleButtonToggled
	{
	self.state  = (self.state == ControlStateNormal)
				? ControlStateHighlighted
				: ControlStateNormal;
	[self sendAction:self.action to:self.target];
	[self setNeedsDisplay:YES];
	if (self.type == ButtonTypeRadio)
		{
		NSDictionary *info =
			@{
			@"group" : self.radioGroup
			};

		NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
		[nc postNotificationName:AZRadioButtonPressedNotification
						  object:self userInfo:info];
		}
	}

/*****************************************************************************\
|* Populate the rectangles from the UI texture atlas
\*****************************************************************************/
- (void) _fetchRects
	{
	AZApp *app 		  = AZApp.sharedInstance;
	_bLeft[STATE_N]   = [app srcRectFor:@"button-bezel-left"];
	_bLeft[STATE_H]   = [app srcRectFor:@"button-bezel-highlighted-left"];
	_bLeft[STATE_D]   = [app srcRectFor:@"button-bezel-disabled-left"];

	_bLeft[STATE_RN]  = [app srcRectFor:@"button-bezel-rounded-left"];
	_bLeft[STATE_RH]  = [app srcRectFor:@"button-bezel-rounded-highlighted-left"];
	_bLeft[STATE_RD]  = [app srcRectFor:@"button-bezel-rounded-disabled-left"];

	_bLeft[STATE_DN]  = [app srcRectFor:@"default-button-bezel-left"];
	_bLeft[STATE_DH]  = [app srcRectFor:@"default-button-bezel-highlighted-left"];
	_bLeft[STATE_DD]  = [app srcRectFor:@"default-button-bezel-disabled-left"];

	_bLeft[STATE_RDN] = [app srcRectFor:@"default-button-bezel-rounded-left"];
	_bLeft[STATE_RDH] = [app srcRectFor:@"default-button-bezel-rounded-highlighted-left"];
	_bLeft[STATE_RDD] = [app srcRectFor:@"default-button-bezel-rounded-disabled-left"];


	_bCenter[STATE_N]   = [app srcRectFor:@"button-bezel-center"];
	_bCenter[STATE_H]   = [app srcRectFor:@"button-bezel-highlighted-center"];
	_bCenter[STATE_D]   = [app srcRectFor:@"button-bezel-disabled-center"];

	_bCenter[STATE_RN]  = [app srcRectFor:@"button-bezel-rounded-center"];
	_bCenter[STATE_RH]  = [app srcRectFor:@"button-bezel-rounded-highlighted-center"];
	_bCenter[STATE_RD]  = [app srcRectFor:@"button-bezel-rounded-disabled-center"];

	_bCenter[STATE_DN]  = [app srcRectFor:@"default-button-bezel-center"];
	_bCenter[STATE_DH]  = [app srcRectFor:@"default-button-bezel-highlighted-center"];
	_bCenter[STATE_DD]  = [app srcRectFor:@"default-button-bezel-disabled-center"];

	_bCenter[STATE_RDN] = [app srcRectFor:@"default-button-bezel-rounded-center"];
	_bCenter[STATE_RDH] = [app srcRectFor:@"default-button-bezel-rounded-highlighted-center"];
	_bCenter[STATE_RDD] = [app srcRectFor:@"default-button-bezel-rounded-disabled-center"];

	_bCenter[STATE_CN]	= [app srcRectFor:@"check-box-image"];
	_bCenter[STATE_CK]	= [app srcRectFor:@"check-box-image-selected"];
	_bCenter[STATE_CD]	= [app srcRectFor:@"check-box-image"];

	_bCenter[STATE_NR]	= [app srcRectFor:@"radio-image"];
	_bCenter[STATE_SR]	= [app srcRectFor:@"radio-image-selected"];
	_bCenter[STATE_DR]	= [app srcRectFor:@"radio-image"];

	_bRight[STATE_N]   = [app srcRectFor:@"button-bezel-right"];
	_bRight[STATE_H]   = [app srcRectFor:@"button-bezel-highlighted-right"];
	_bRight[STATE_D]   = [app srcRectFor:@"button-bezel-disabled-right"];

	_bRight[STATE_RN]  = [app srcRectFor:@"button-bezel-rounded-right"];
	_bRight[STATE_RH]  = [app srcRectFor:@"button-bezel-rounded-highlighted-right"];
	_bRight[STATE_RD]  = [app srcRectFor:@"button-bezel-rounded-disabled-right"];

	_bRight[STATE_DN]  = [app srcRectFor:@"default-button-bezel-right"];
	_bRight[STATE_DH]  = [app srcRectFor:@"default-button-bezel-highlighted-right"];
	_bRight[STATE_DD]  = [app srcRectFor:@"default-button-bezel-disabled-right"];

	_bRight[STATE_RDN] = [app srcRectFor:@"default-button-bezel-rounded-right"];
	_bRight[STATE_RDH] = [app srcRectFor:@"default-button-bezel-rounded-highlighted-right"];
	_bRight[STATE_RDD] = [app srcRectFor:@"default-button-bezel-rounded-disabled-right"];
	}
@end
