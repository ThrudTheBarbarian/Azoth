//
//  AZTextField.m
//  Azoth
//
//  Created by Simon Gornall on 12/16/24.
//

#import <SDL3/SDL.h>

#import "AZApplication.h"
#import "AZColour.h"
#import "AZEvent.h"
#import "AZFont.h"
#import "AZGlyphData.h"
#import "AZNotifications.h"
#import "AZPainter.h"
#import "AZRenderer.h"
#import "AZTextField.h"
#import "AZTextPainter.h"
#import "AZTypes.h"
#import "AZWindow.h"
#import "AZZib.h"

#define XOFF 		2
#define YOFF		(-2)
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

static NSRect	_bTL[STATE_NUM];
static NSRect	_bTM[STATE_NUM];
static NSRect	_bTR[STATE_NUM];
static NSRect	_bCL[STATE_NUM];
static NSRect	_bCM[STATE_NUM];
static NSRect	_bCR[STATE_NUM];
static NSRect	_bBL[STATE_NUM];
static NSRect	_bBM[STATE_NUM];
static NSRect	_bBR[STATE_NUM];

static int 				_lineHeight = 29;
static dispatch_once_t _onceToken;

// Offsets for different states
static float _dx[STATE_NUM];
static float _dy[STATE_NUM];
static float _dw[STATE_NUM];
static float _dh[STATE_NUM];

@interface AZTextField()

// Cursor support
@property(assign, nonatomic)	int						cursor;
@property(assign, nonatomic) 	int						cursorLength;
@property(assign, nonatomic)	uint64_t				lastCursorChange;
@property(assign, nonatomic)	BOOL					showCursor;
@property(assign, nonatomic)	NSRect					cursorRect;

// Highlight support
@property(assign, nonatomic)	BOOL					highlighting;
@property(assign, nonatomic)	int						highlightFrom;
@property(assign, nonatomic)	int						highlightTo;

// For window rendering
@property(assign, nonatomic) 	NSRect					editArea;
@property(assign, nonatomic) 	NSRect					origArea;

// Timer for blinking cursor
@property(strong, nonatomic) 	NSTimer *				blinkTimer;
@end

@implementation AZTextField

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	dispatch_once(&_onceToken,
		^{
		[self _fetchRects];

		// Cope with the highlighted and normal tiles having different
		// dimensions
		[self _initialiseRects];
		});

	frame.origin.x 		-= _dx[STATE_SN];
	frame.origin.y 		-= _dy[STATE_SN];
	frame.size.width 	+= _dx[STATE_SN];
	frame.size.height 	+= _dy[STATE_SN];

	if (self = [super initWithFrame:frame])
		{
		if (![self _commonTextFieldInit])
			self = nil;
		}
	return self;
	}

/*****************************************************************************\
|* Configuration via dictionary. This is called by the NIB loader, but is a
|* valid way to create the view
\*****************************************************************************/
- (instancetype) initWithDictionary:(NSDictionary *)info;
	{
	dispatch_once(&_onceToken,
		^{
		[self _fetchRects];

		// Cope with the highlighted and normal tiles having different
		// dimensions
		[self _initialiseRects];
	});

	if (self = [super initWithDictionary:info])
		{
		NSRect frame 		 = self.frame;
		frame.origin.x 		-= _dx[STATE_SN];
		frame.origin.y 		-= _dy[STATE_SN];
		frame.size.width 	+= _dw[STATE_SN];
		frame.size.height 	+= _dh[STATE_SN];
		self.frame 			 = frame;

		if (![self _commonTextFieldInit])
			self = nil;

		if ([info[kZibEditable] isEqualToString:@"YES"])
			self.enabled = YES;
		else
			self.enabled = NO;

		if ([info[kZibType] isEqualToString:kZibRound])
			self.type = TextFieldRounded;
		else
			self.type = TextFieldSquare;

		NSString *titleText = info[kZibTitle];
		if (titleText)
			self.stringValue = titleText;
		}
	return self;
	}

/*****************************************************************************\
|* Read in rectangles defining the backgrounds
\*****************************************************************************/
- (void) _initialiseRects
	{

	// Cope with the highlighted and normal tiles having different
	// dimensions
	for (int i=STATE_SN; i<=STATE_SD; i++)
		{
		_dx[i] 	= _bBL[STATE_SF].size.width  - _bBL[STATE_SN].size.width;
		_dy[i] 	= _bBL[STATE_SF].size.height - _bBL[STATE_SN].size.height;
		_dw[i]	= 2 * _dx[i];
		_dh[i]	= 2 * _dy[i];
		}

	for (int i=STATE_RN; i<=STATE_RD; i++)
		{
		_dx[i] 	= _bCL[STATE_RF].size.width  - _bCL[STATE_RN].size.width;
		_dh[i] 	= _bCL[STATE_RF].size.height - _bCL[STATE_RN].size.height;
		_dw[i]	= 2 * _dx[i];
		_dy[i]	= _dh[i]/2;
		}

	_dx[STATE_SF] = _dx[STATE_RF] = 0;
	_dy[STATE_SF] = _dy[STATE_RF] = 0;
	_dw[STATE_SF] = _dw[STATE_RF] = 0;
	_dh[STATE_SF] = _dh[STATE_RF] = 0;
	}

/*****************************************************************************\
|* Common initialisation between -withFrame and -withDictionary
\*****************************************************************************/
- (BOOL) _commonTextFieldInit
	{	;
	dispatch_once(&_onceToken,
		^{
		[self _fetchRects];
		});

	if (![self _editCreate])
		return NO;
	else
		{
		self.backgroundColour		= AZColour.clear;
		self.stringValue 			= @"";
		self.textColour				= AZColour.black;
		self.editable				= YES;
		}
	return YES;
	}

+ (AZTextField *) textfieldWithFrame:(NSRect)frame
	{
	return [[AZTextField alloc] initWithFrame:frame];
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
	if (self.enabled && self.editable && (self.state == AZControlStateNormal))
		{
		self.state = AZControlStateHighlighted;
		SDL_StartTextInput(self.window.window);

		_blinkTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
													  repeats:YES
														block:
			^(NSTimer * _Nonnull timer)
				{
				if (SDL_GetTicksNS() - self.lastCursorChange > 500)
					{
					self.lastCursorChange = SDL_GetTicksNS();
					self.showCursor 	  = !self.showCursor;
					[self setNeedsDisplay:YES];
					}
				}];
		[self setNeedsDisplay:YES];
		return YES;
		}
	return NO;
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
	if (self.editable)
		{
		SDL_StopTextInput(self.window.window);
		[_blinkTimer invalidate];
		_blinkTimer = nil;
		self.showCursor = NO;
		self.state = AZControlStateNormal;
		[self setNeedsDisplay:YES];
		}
	return YES;
	}

/*****************************************************************************\
|* If we change our text colour we want to redraw
\*****************************************************************************/
- (void) setTextColour:(AZColour *)textColour
	{
	_textColour = textColour;
	[self setNeedsDisplay:YES];
	}

// MARK: AZControl

/*****************************************************************************\
|* If we have a string set on us, update the TTF_Text
\*****************************************************************************/
- (void) setStringValue:(NSString *)stringValue
	{
	[super setStringValue:stringValue];
	[self setNeedsDisplay:YES];
	}

- (void) setObjectValue:(NSObject *)objectValue
	{
	return [self setStringValue:objectValue.description];
	}

/*****************************************************************************\
|* Draw the textField
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[super drawInRect:dirtyRect withPainter:painter];

	AZColour *colour = _textColour;
	if ((!self.editable) && self.state == AZControlStateHighlighted)
		colour = AZColour.selectedControl;
	[painter setTextColour:colour];

	if (!self.editable)
		[self _drawAsLabelWithRect:dirtyRect andPainter:painter];
	else if (_type == TextFieldSquare)
		[self _drawSquareTextFieldWithRect:dirtyRect andPainter:painter];
	else
		[self _drawRoundTextFieldWithRect:dirtyRect andPainter:painter];
	}

- (void) _drawAsLabelWithRect:(NSRect)r andPainter:(AZPainter *)p
	{
	[self _drawTextInRect:_editArea withPainter:p];
	}

- (void) _drawRoundTextFieldWithRect:(NSRect)r andPainter:(AZPainter *)p
	{
	NSRect sCL	= _bCL[self.state + _type];
	NSRect sCM	= _bCM[self.state + _type];
	NSRect sCR	= _bCR[self.state + _type];

	float W		= self.bounds.size.width;
	float dx	= _dx[self.state + _type];
	float dy	= _dy[self.state + _type];
	float dw	= _dw[self.state + _type];

	NSRect dCL	= {dx,
				   dy,
				   sCL.size.width,
				   sCL.size.height};

	NSRect dCM	= {dx+sCL.size.width,
				   dy,
				   W-sCL.size.width-sCR.size.width-dw,
				   sCM.size.height};

	NSRect dCR	= {dx+W-sCR.size.width-dw,
				   dy,
				   sCR.size.width,
				   sCR.size.height};

	id<AZRenderer> azr	= AZRenderer.renderer;
	NSInteger ui	= [AZApp textureFor:kUiMap];

	[azr setBlendMode:SDL_BLENDMODE_ADD];

	[azr blitFrom:ui src:sCL dst:dCL];
	[azr tileFrom:ui src:sCM dst:dCM];
	[azr blitFrom:ui src:sCR dst:dCR];

	_editArea.origin.y = _origArea.origin.y;
	[self _drawTextInRect:_editArea withPainter:p];
	}

- (void) _drawSquareTextFieldWithRect:(NSRect)r andPainter:(AZPainter *)p
	{
	NSRect sTL	= _bTL[self.state + _type];
	NSRect sTM	= _bTM[self.state + _type];
	NSRect sTR	= _bTR[self.state + _type];

	NSRect sCL	= _bCL[self.state + _type];
	NSRect sCM	= _bCM[self.state + _type];
	NSRect sCR	= _bCR[self.state + _type];

	NSRect sBL	= _bBL[self.state + _type];
	NSRect sBM	= _bBM[self.state + _type];
	NSRect sBR	= _bBR[self.state + _type];

	float W		= self.bounds.size.width  - 1;
	float H		= self.bounds.size.height;
	float dx	= _dx[self.state + _type];
	float dy	= _dy[self.state + _type];
	float dw	= _dw[self.state + _type];
	float dh	= _dh[self.state + _type];

	NSRect dTL	= {dx,
				   H-sTL.size.height-dy,
				   sTL.size.width,
				   sTL.size.height};

	NSRect dTM	= {dx + sTL.size.width,
				   H-sTM.size.height - dy,
				   W-sTL.size.width-sTR.size.width - dw,
				   sTM.size.height};

	NSRect dTR	= {dx + W-sTR.size.width - dw,
				   H-sTR.size.height - dy,
				   sTR.size.width,
				   sTR.size.height};



	NSRect dCL	= {dx,
				   sBL.size.height+dy,
				   sCL.size.width,
				   H-sTL.size.height-sBL.size.height - dh};

	NSRect dCM	= {dx + dCL.size.width,
				   sTL.size.height+dy,
				   W-sCL.size.width-sCR.size.width - dw,
				   H-sTM.size.height-sBM.size.height - dh};

	NSRect dCR	= {dx + W-sCR.size.width - dw,
				   sTR.size.height+dy,
				   sCR.size.width,
				   H-sTR.size.height-sBR.size.height - dh};

	NSRect dBL	= {dx, dy, sBL.size.width, sBL.size.height};
	NSRect dBM	= {dx + sBL.size.width,
				   dy,
				   W-sBL.size.width-sBR.size.width - dw,
				   sBM.size.height};
	NSRect dBR	= {dx + W-sBR.size.width -dw,
				   dy,
				   sBR.size.width,
				   sBR.size.height};

	id<AZRenderer> azr	= AZRenderer.renderer;
	NSInteger ui	= [AZApp textureFor:kUiMap];

	[azr setBlendMode:SDL_BLENDMODE_ADD];

	[azr blitFrom:ui src:sTL dst:dTL];
	[azr tileFrom:ui src:sTM dst:dTM];
	[azr blitFrom:ui src:sTR dst:dTR];

	[azr tileFrom:ui src:sCL dst:dCL];
	[azr tileFrom:ui src:sCM dst:dCM];
	[azr tileFrom:ui src:sCR dst:dCR];

	[azr blitFrom:ui src:sBL dst:dBL];
	[azr tileFrom:ui src:sBM dst:dBM];
	[azr blitFrom:ui src:sBR dst:dBR];

	[self _drawTextInRect:_editArea withPainter:p];
	}


// MARK: Private methods

/*****************************************************************************\
|* Populate the rectangles from the UI texture atlas
\*****************************************************************************/
- (void) _fetchRects
	{

	_bBL[STATE_SN] = [AZApp srcRectFor:@"textfield-bezel-square-0" in:kUiMap];
	_bBM[STATE_SN] = [AZApp srcRectFor:@"textfield-bezel-square-1" in:kUiMap];
	_bBR[STATE_SN] = [AZApp srcRectFor:@"textfield-bezel-square-2" in:kUiMap];
	_bCL[STATE_SN] = [AZApp srcRectFor:@"textfield-bezel-square-3" in:kUiMap];
	_bCM[STATE_SN] = [AZApp srcRectFor:@"textfield-bezel-square-4" in:kUiMap];
	_bCR[STATE_SN] = [AZApp srcRectFor:@"textfield-bezel-square-5" in:kUiMap];
	_bTL[STATE_SN] = [AZApp srcRectFor:@"textfield-bezel-square-6" in:kUiMap];
	_bTM[STATE_SN] = [AZApp srcRectFor:@"textfield-bezel-square-7" in:kUiMap];
	_bTR[STATE_SN] = [AZApp srcRectFor:@"textfield-bezel-square-8" in:kUiMap];

	_bBL[STATE_SF] = [AZApp srcRectFor:@"textfield-bezel-square-focused-0" in:kUiMap];
	_bBM[STATE_SF] = [AZApp srcRectFor:@"textfield-bezel-square-focused-1" in:kUiMap];
	_bBR[STATE_SF] = [AZApp srcRectFor:@"textfield-bezel-square-focused-2" in:kUiMap];
	_bCL[STATE_SF] = [AZApp srcRectFor:@"textfield-bezel-square-focused-3" in:kUiMap];
	_bCM[STATE_SF] = [AZApp srcRectFor:@"textfield-bezel-square-focused-4" in:kUiMap];
	_bCR[STATE_SF] = [AZApp srcRectFor:@"textfield-bezel-square-focused-5" in:kUiMap];
	_bTL[STATE_SF] = [AZApp srcRectFor:@"textfield-bezel-square-focused-6" in:kUiMap];
	_bTM[STATE_SF] = [AZApp srcRectFor:@"textfield-bezel-square-focused-7" in:kUiMap];
	_bTR[STATE_SF] = [AZApp srcRectFor:@"textfield-bezel-square-focused-8" in:kUiMap];

	_bBL[STATE_SD] = [AZApp srcRectFor:@"textfield-bezel-square-disabled-0" in:kUiMap];
	_bBM[STATE_SD] = [AZApp srcRectFor:@"textfield-bezel-square-disabled-1" in:kUiMap];
	_bBR[STATE_SD] = [AZApp srcRectFor:@"textfield-bezel-square-disabled-2" in:kUiMap];
	_bCL[STATE_SD] = [AZApp srcRectFor:@"textfield-bezel-square-disabled-3" in:kUiMap];
	_bCM[STATE_SD] = [AZApp srcRectFor:@"textfield-bezel-square-disabled-4" in:kUiMap];
	_bCR[STATE_SD] = [AZApp srcRectFor:@"textfield-bezel-square-disabled-5" in:kUiMap];
	_bTL[STATE_SD] = [AZApp srcRectFor:@"textfield-bezel-square-disabled-6" in:kUiMap];
	_bTM[STATE_SD] = [AZApp srcRectFor:@"textfield-bezel-square-disabled-7" in:kUiMap];
	_bTR[STATE_SD] = [AZApp srcRectFor:@"textfield-bezel-square-disabled-8" in:kUiMap];

	_bCL[STATE_RN] = [AZApp srcRectFor:@"textfield-bezel-rounded-left" in:kUiMap];
	_bCM[STATE_RN] = [AZApp srcRectFor:@"textfield-bezel-rounded-center" in:kUiMap];
	_bCR[STATE_RN] = [AZApp srcRectFor:@"textfield-bezel-rounded-right" in:kUiMap];

	_bCL[STATE_RF] = [AZApp srcRectFor:@"textfield-bezel-rounded-focused-left" in:kUiMap];
	_bCM[STATE_RF] = [AZApp srcRectFor:@"textfield-bezel-rounded-focused-center" in:kUiMap];
	_bCR[STATE_RF] = [AZApp srcRectFor:@"textfield-bezel-rounded-focused-right" in:kUiMap];

	_bCL[STATE_RD] = [AZApp srcRectFor:@"textfield-bezel-rounded-disabled-left" in:kUiMap];
	_bCM[STATE_RD] = [AZApp srcRectFor:@"textfield-bezel-rounded-disabled-center" in:kUiMap];
	_bCR[STATE_RD] = [AZApp srcRectFor:@"textfield-bezel-rounded-disabled-right" in:kUiMap];

	for (int i=STATE_RN; i<=STATE_RD; i++)
		{
		_lineHeight = MAX(_bCL[i].size.height, _lineHeight);
		_lineHeight = MAX(_bCM[i].size.height, _lineHeight);
		_lineHeight = MAX(_bCR[i].size.height, _lineHeight);
		}
	}

/*****************************************************************************\
|* Find the character index of a point in the string, using the glyph sizes.
|* This currently only does x, since it's a textfield...
\*****************************************************************************/
- (int) textIndexForX:(int)x
	{
	if (x < 0)
		return 0;

	int index 			= -1;
	NSInteger numChars 	= self.stringValue.length;
	AZFont *font 		= AZApp.controlFont;
	int offset 			= 0;

	for (NSInteger i=0; i<numChars; i++)
		{
		unichar c 			= [self.stringValue characterAtIndex:i];
		AZGlyphData *info 	= [font glyphDataFor:c];
		if ((x >= offset) && (x <= offset + info.rect.size.width))
			{
			index = (int)i;
			break;
			}
		offset += info.rect.size.width;
		}
	if (index < 0)
		{
		if (x > offset)
			index = (int) numChars;
		}
	return index;
	}


/*****************************************************************************\
|* Find the rectangle that contains the characters from 'from' to 'to'
\*****************************************************************************/
- (NSRect) highlightedRectFrom:(int)from to:(int)to
	{
	NSRect rect	 = NSZeroRect;
	AZFont *font = AZApp.controlFont;
	int len		 = (int) self.stringValue.length;

	from = (from < 0) ? 0 : (from > len-1) ? len - 1 : from;
	to   = (to   < 0) ? 0 : (to   > len-1) ? len - 1 : to;

	for (int i=0; i<=to; i++)
		{
		unichar c 				= [self.stringValue characterAtIndex:i];
		AZGlyphData *info 		= [font glyphDataFor:c];
		if (i<from)
			rect.origin.x  	   += info.rect.size.width;
		else if (i<=to)
			rect.size.width    += info.rect.size.width;

		int h = info.rect.size.height;
		rect.size.height = (h > rect.size.height) ? h : rect.size.height;
		}
	rect.origin.x += _origArea.origin.x + XOFF;
	rect.origin.y += font.descent;
	return rect;
	}

/*****************************************************************************\
|* Find the rectangle that contains the character at 'index'
\*****************************************************************************/
- (NSRect) rectAt:(int)index of:(NSString *)text
	{
	int max = (int) [self.stringValue length] -1;
	if (max < 0)
		return NSZeroRect;

	int to  = index+1 < max ? index+1 : max;
	return [self highlightedRectFrom:index to:to];
	}

// MARK: Events

/*****************************************************************************\
|* Handle a mouse press
\*****************************************************************************/
- (BOOL) mouseDown:(AZEvent *)e
	{
	[self.window makeFirstResponder:self];
	NSPoint p = [self convertPoint:e.locationInWindow fromView:nil];

    // Set the cursor position
	int textX = (int)SDL_roundf(p.x - _editArea.origin.x);
	int index = [self textIndexForX:textX];
	[self _editSetCursorPosition:index];

    _highlighting 	= YES;
    _highlightFrom	= _cursor;
    _highlightTo 	= -1;

	return self.editable;
	}

/*****************************************************************************\
|* Handle a mouse drag
\*****************************************************************************/
- (BOOL) mouseDragged:(AZEvent *)e
	{
	if (!_highlighting)
		return NO;

    // Set the highlight position
	NSPoint p = [self convertPoint:e.locationInWindow fromView:nil];

	int textX = (int)SDL_roundf(p.x - _editArea.origin.x);
    int index = [self textIndexForX:textX];
	[self _editSetCursorPosition:index];
	[self _editEnsureCursorVisible];

    _highlightTo = _cursor;
	[self setNeedsDisplay:YES];
    return YES;
	}

/*****************************************************************************\
|* Mouse-button-up event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseUp:(AZEvent *)e
	{
	if (!_highlighting)
		return NO;

    _highlighting 	= NO;
	[self setNeedsDisplay:YES];
	return YES;
	}

/*****************************************************************************\
|* Key event handling. These are basically modifiers, the actual text
|* processing uses the -textInput method
\*****************************************************************************/
- (BOOL) keyDown:(SDL_KeyboardEvent *)e
	{
	BOOL handled = NO;
	switch (e->key)
		{
         case SDLK_A:
            if (e->mod & (SDL_KMOD_CTRL | SDL_KMOD_GUI))
                [self _editSelectAll];
			handled = YES;
            break;

        case SDLK_C:
            if (e->mod & (SDL_KMOD_CTRL | SDL_KMOD_GUI))
                [self _editCopy];
			handled = YES;
            break;
		}

	if (self.enabled)
		{
		switch(e->key)
			{
			case SDLK_V:
				if (e->mod & (SDL_KMOD_CTRL | SDL_KMOD_GUI))
					[self _editPaste];
				handled = YES;
				break;

			case SDLK_X:
				if (e->mod & (SDL_KMOD_CTRL | SDL_KMOD_GUI))
					[self _editCut];
				handled = YES;
				break;

			case SDLK_LEFT:
				if (e->mod & (SDL_KMOD_CTRL | SDL_KMOD_GUI))
					[self _moveCursorToStartOfLine];
				else
					[self _moveCursorLeft];
				handled = YES;
				break;

			case SDLK_RIGHT:
				if (e->mod & (SDL_KMOD_CTRL | SDL_KMOD_GUI))
					[self _moveCursorToEndOfLine];
				else
					[self _moveCursorRight];
				handled = YES;
				break;

			case SDLK_END:
			case SDLK_DOWN:
				if (e->mod & (SDL_KMOD_CTRL | SDL_KMOD_GUI))
					[self _moveCursorToEndOfLine];
				handled = YES;
				break;

			case SDLK_HOME:
			case SDLK_UP:
				if (e->mod & (SDL_KMOD_CTRL | SDL_KMOD_GUI))
					[self _moveCursorToStartOfLine];
				handled = YES;
				break;

		   case SDLK_BACKSPACE:
				if (e->mod & SDL_KMOD_CTRL)
					[self _editBackspaceToBeginning];
				else
					[self _editBackspace];
				handled = YES;
				break;

		   case SDLK_DELETE:
				if (e->mod & SDL_KMOD_CTRL)
					[self _editDeleteToEnd];
				else
					[self _editDelete];
				handled = YES;
				break;

			case SDLK_TAB:
			case SDLK_RETURN:
				[self _editAction:e->key];
				handled = YES;
				break;
			}

		[self _editEnsureCursorVisible];
		}

	if (handled)
		[self setNeedsDisplay:YES];
	return handled;
	}

/*****************************************************************************\
|* Text event handling. This is the source of characters entering the buffer
\*****************************************************************************/
- (BOOL) textInput:(SDL_TextInputEvent *)e
	{
	if (self.enabled)
		{
		[self _editInsert:[NSString stringWithUTF8String:e->text]];
		return YES;
		}
	return NO;
	}

/*****************************************************************************\
|* Text compositional editing for non-keyboard symbols
\*****************************************************************************/
- (BOOL) textEditing:(SDL_TextEditingEvent *)e
	{
	if (self.enabled)
		{
		return YES;
		}
	return NO;
	}

/*****************************************************************************\
|* Handle the candidates for composition
\*****************************************************************************/
- (BOOL) textEditingCandidates:(SDL_Event *)e
	{
	if (self.enabled)
		{
		return YES;
		}
	return NO;
	}

// MARK: Drawing routines

/*****************************************************************************\
|* Drawing
\*****************************************************************************/
- (void) _drawTextInRect:(NSRect)r withPainter:(AZPainter *)P
	{
	[self _editDrawTextWithPainter:P];
	if (self.enabled)
		[self _editDrawCursor];
	}

/*****************************************************************************\
|* Draw the cursor
\*****************************************************************************/
- (void) _editDrawCursor
	{
	if (_showCursor)
		{
		id<AZRenderer> azr	= AZRenderer.renderer;
		[azr setBlendMode:SDL_BLENDMODE_BLEND];
		[azr setDrawColourToRed:0 g:0 b:0 a:0xff];
		[azr renderFilledRect:_cursorRect];
		}
	}

/*****************************************************************************\
|* Draw the actual text itself
\*****************************************************************************/
- (void) _editDrawText:(NSString *)text atX:(int)x y:(int)y
		   withPainter:(AZPainter *)P
	{
	[P textAtX:x+XOFF y:y+YOFF text:text];
	if ((!self.editable) && self.state != AZControlStateNormal)
		{
		[P textAtX:x+2 y:y-2 text:text];
		[P textAtX:x+2 y:y-2 text:text];
		}
	}

/*****************************************************************************\
|* Draw the editable contents
\*****************************************************************************/
- (void) _editDrawTextWithPainter:(AZPainter *)P
	{
	id<AZRenderer> azr	= AZRenderer.renderer;
	[azr setBlendMode:SDL_BLENDMODE_BLEND];
	[azr setDrawColour:AZColour.black];

    float x 		= _editArea.origin.x;
    float y 		= _editArea.origin.y;

	NSRect existing 	= azr.clipRect;
	NSRect nsClip       = NSIntersectionRect(existing, _origArea);
	[azr setClip:nsClip];

	[self _editDrawText:self.stringValue atX:x y:y withPainter:P];

	if ((existing.size.width > 0) && (existing.size.height > 0))
		[azr setClip:existing];
	else
		[azr unsetClip];

	// Draw any highlight
    int marker, length;
    if ([self _editGetHighlightExtentsFrom:&marker withLength:&length])
		{
		[azr setBlendMode:SDL_BLENDMODE_BLEND_PREMULTIPLIED];
		NSRect toDraw = [self highlightedRectFrom:marker to:marker+length];
        if (toDraw.size.width > 0)
			{
			[azr setDrawColourToRed:0 g:0 b:0xff a:0x10];
			[azr renderFilledRect:toDraw];
			}
		}


    // Calculate the cursor rect
	NSString *sub 	= [self.stringValue substringToIndex:_cursor];
	int cx			= [AZApp.controlFont textWidthFor:sub]
					+ _editArea.origin.x;
	_cursorRect 	= NSMakeRect(cx, _editArea.origin.y-1,
								 1, _editArea.size.height);
	}

// MARK: Selection

/*****************************************************************************\
|* Programmatically select everything
\*****************************************************************************/
- (void) selectAll
	{
	[self _editSelectAll];
	}

// MARK: Editing methods


/*****************************************************************************\
|* Send an action to the target if we have both
\*****************************************************************************/
- (void) _editAction:(NSInteger)key
	{
	// Send a notification that we have finished editing, in case anyone is
	// listening
	NSInteger movement 		 = (key == SDLK_TAB)   ? AZTabTextMovement
							 : (key == SDLK_RETURN)? AZReturnTextMovement
							 : AZOtherTextMovement;

	NSDictionary *userInfo	 =
		@{
		AZTextMovementUserInfoKey : @(movement)
		};

	self.objectValue = self.stringValue;
	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
	[nc postNotificationName:AZTextDidEndEditingNotification
					  object:self
					userInfo:userInfo];
	[self sendAction:self.action to:self.target];
	}

/*****************************************************************************\
|* Creation of the editing state
\*****************************************************************************/
- (BOOL) _editCreate
	{
	_highlightFrom = -1;
	_highlightTo = -1;

	int X = _bCL[0].size.width + 3;
	int Y = _bTM[0].size.height + 2;
	int W = self.bounds.size.width
		  - _bCL[0].size.width
		  - _bCR[0].size.width - 6;
	int H = self.bounds.size.height - 4
		  - _bBM[0].size.height
		  - _bTM[0].size.height;

	_editArea = NSMakeRect(X,Y,W,H);
		 //NSInsetRect(self.bounds, 4, 2);
	_origArea = _editArea;

	return YES;
	}


/*****************************************************************************\
|* Called on a view when it resizes
\*****************************************************************************/
//- (void) didResizeFrom:(NSRect)oldFrame
//	{
//	NSLog(@"did resize from %@ to %@", NSStringFromRect(oldFrame),
//		NSStringFromRect(self.frame));
//	}

/*****************************************************************************\
|* Insert text
\*****************************************************************************/
- (void) _editInsert:(NSString *)text
	{
	if (!text)
		return;

	[self _editDeleteHighlight];

	NSString *pre = [self.stringValue substringToIndex:_cursor];
	NSString *pst = [self.stringValue substringFromIndex:_cursor];
	self.stringValue = [NSString stringWithFormat:@"%@%@%@", pre, text, pst];

	[self _editSetCursorPosition:(int)(_cursor + text.length)];
	[self _editEnsureCursorVisible];

	[self setNeedsDisplay:YES];
	}


/*****************************************************************************\
|* Make sure the cursor is visible by manipulating the textbox area
\*****************************************************************************/
- (void) _editEnsureCursorVisible
	{
	if (_origArea.size.width == 0)
		return;

	NSString *copy = self.stringValue.copy;
	NSRect fromCursor = [self rectAt:_cursor of:copy];

	// If the cursor would go off the screen to the right, push the
	// editArea off to the left to compensate
	int cx = fromCursor.size.width + fromCursor.origin.x;
	int cumulativeWidth = 0;
	int maxX = _origArea.size.width
			- _bCL[0].size.width
			- _bCR[0].size.width;

	while (cx - cumulativeWidth > maxX)
		{
		NSRect first = [self rectAt:0 of:copy];
		if (first.size.width == 0)
			break;
		cumulativeWidth += first.size.width;
		copy = [copy substringFromIndex:1];
		}
	_editArea.origin.x = _origArea.origin.x - cumulativeWidth;
	}

/*****************************************************************************\
|* Get rid of any highlight
\*****************************************************************************/
- (BOOL) _editDeleteHighlight
	{
	int marker, length;
    if ([self _editGetHighlightExtentsFrom:&marker withLength:&length])
		{
		NSString *pre = [self.stringValue substringToIndex:marker];
		NSString *pst = [self.stringValue substringFromIndex:marker+length];
		self.stringValue = [NSString stringWithFormat:@"%@%@", pre, pst];
        [self _editSetCursorPosition:marker];
        _highlightFrom 	= -1;
        _highlightTo 	= -1;
        return YES;
		}
    return NO;
	}


/*****************************************************************************\
|* Set the cursor position
\*****************************************************************************/
- (void) _editSetCursorPosition:(int)position
	{
    _cursor = position;
	[self _editEnsureCursorVisible];
	}


/*****************************************************************************\
|* Find out where the highlights extend to
\*****************************************************************************/
- (BOOL) _editGetHighlightExtentsFrom:(int *)marker withLength:(int *)length
	{
	if (_highlightFrom >= 0 && _highlightTo >= 0)
		{
		int marker1 = SDL_min(_highlightFrom, _highlightTo);
		int marker2 = SDL_max(_highlightFrom, _highlightTo);
		if (marker2 > marker1)
			{
			*marker = marker1;
			*length = marker2 - marker1;
			return YES;
			}
		}
    return NO;
	}


/*****************************************************************************\
|* Backspace to the beginning of the textfield
\*****************************************************************************/
- (void) _editBackspaceToBeginning
	{
    // Delete to the beginning of the string
	self.stringValue = @"";
	[self _editSetCursorPosition:0];
	}

/*****************************************************************************\
|* Backspace a single character
\*****************************************************************************/
- (void) _editBackspace
	{
	if ([self _editDeleteHighlight])
		return;

    if (_cursor > 0)
		{
		NSString *pre = [self.stringValue substringToIndex:_cursor-1];
		NSString *pst = [self.stringValue substringFromIndex:_cursor];
		self.stringValue = [NSString stringWithFormat:@"%@%@", pre, pst];
        _cursor --;
		[self _editEnsureCursorVisible];
		}
	}

/*****************************************************************************\
|* Select all the text
\*****************************************************************************/
- (void) _editSelectAll
	{
	_highlightFrom = 0;
	_highlightTo = (int)[self.stringValue length] -1;
	}

/*****************************************************************************\
|* Copy to the clipboard
\*****************************************************************************/
- (void) _editCopy
	{
    int marker, length;
	if ([self _editGetHighlightExtentsFrom:&marker withLength:&length])
        {
		NSRange where = NSMakeRange(marker, length);
		NSString *sub = [self.stringValue substringWithRange:where];
		SDL_SetClipboardText(sub.UTF8String);
		}
	else
		SDL_SetClipboardText(self.stringValue.UTF8String);
	}

/*****************************************************************************\
|* Paste from the clipboard
\*****************************************************************************/
- (void) _editPaste
	{
    const char *text = SDL_GetClipboardText();
	[self _editInsert:[NSString stringWithUTF8String:text]];
	}

/*****************************************************************************\
|* Cut the selection/text
\*****************************************************************************/
- (void) _editCut
	{
    int marker, length;
	if ([self _editGetHighlightExtentsFrom:&marker withLength:&length])
        {
		NSRange where 	= NSMakeRange(marker, length);
		NSString *what 	= [self.stringValue substringWithRange:where];
		NSString *pre 	= [self.stringValue substringToIndex:marker];
		NSString *pst 	= [self.stringValue substringFromIndex:marker+length];

		self.stringValue = [NSString stringWithFormat:@"%@%@", pre,pst];
        SDL_SetClipboardText(what.UTF8String);

		[self _editSetCursorPosition:marker];
        _highlightFrom 	= -1;
        _highlightTo 	= -1;
		}
	else
        {
        SDL_SetClipboardText(self.stringValue.UTF8String);
		self.stringValue = @"";
		[self _editSetCursorPosition:0];
        }
	}

/*****************************************************************************\
|* Move the cursor to the start of the line
\*****************************************************************************/
- (void) _moveCursorToStartOfLine
	{
	[self _editSetCursorPosition:0];
	}

/*****************************************************************************\
|* Move the cursor one character left
\*****************************************************************************/
- (void) _moveCursorLeft
	{
	[self _moveCursorIndex:-1];
	}

/*****************************************************************************\
|* Move the cursor one character right
\*****************************************************************************/
- (void) _moveCursorRight
	{
	[self _moveCursorIndex:1];
    }

/*****************************************************************************\
|* Actually do the one-character cursor move
\*****************************************************************************/
- (void) _moveCursorIndex:(int)direction
	{
    if (direction < 0)
		{
		if (_cursor > 0)
			[self _editSetCursorPosition:_cursor - 1];
		}
	else
		{
		if (_cursor < self.stringValue.length)
			[self _editSetCursorPosition:_cursor + 1];
		}
	}

/*****************************************************************************\
|* Move the cursor all the way to the end of the line
\*****************************************************************************/
- (void) _moveCursorToEndOfLine
	{
	[self _editSetCursorPosition:(int)self.stringValue.length -1];
	}

/*****************************************************************************\
|* Delete from the cursor to the end of the line
\*****************************************************************************/
- (void) _editDeleteToEnd
	{
	if (_cursor > 0)
		{
		NSString *pre 		= [self.stringValue substringToIndex:_cursor];
		self.stringValue 	= pre;
		}
	else
		self.stringValue = @"";
	}


/*****************************************************************************\
|* Delete a single character
\*****************************************************************************/
- (void) _editDelete
	{
	if ([self _editDeleteHighlight])
        return;
	if (_cursor == (int)self.stringValue.length)
		return;

	NSString *pre = [self.stringValue substringToIndex:_cursor];
	NSString *pst = [self.stringValue substringFromIndex:_cursor+1];
	self.stringValue = [NSString stringWithFormat:@"%@%@", pre, pst];
	}


@end
