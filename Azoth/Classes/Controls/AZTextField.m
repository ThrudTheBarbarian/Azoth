//
//  AZTextField.m
//  Azoth
//
//  Created by Simon Gornall on 12/16/24.
//

#import <SDL3/SDL.h>
#import <SDL3_ttf/SDL_ttf.h>

#import "AZApplication.h"
#import "AZColour.h"
#import "AZEvent.h"
#import "AZFont.h"
#import "AZNotifications.h"
#import "AZPainter.h"
#import "AZRenderer.h"
#import "AZTextField.h"
#import "AZTextPainter.h"
#import "AZTypes.h"
#import "AZWindow.h"
#import "AZZib.h"

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
@property(assign, nonatomic)	TTF_Text *				text;

// Cursor support
@property(assign, nonatomic)	int						cursor;
@property(assign, nonatomic) 	int						cursorLength;
@property(assign, nonatomic)	uint64_t				lastCursorChange;
@property(assign, nonatomic)	BOOL					showCursor;
@property(assign, nonatomic)	SDL_FRect				cursorRect;

// Highlight support
@property(assign, nonatomic)	BOOL					highlighting;
@property(assign, nonatomic)	int						highlightFrom;
@property(assign, nonatomic)	int						highlightTo;

// IME composition
@property(assign, nonatomic)	int						compositionStart;
@property(assign, nonatomic)	int						compositionLength;
@property(assign, nonatomic)	int						compositionCursor;
@property(assign, nonatomic)	int						compositionCursorLength;

// IME candidates
@property(assign, nonatomic)	TTF_Text *				candidates;
@property(assign, nonatomic)	int						selectedCandidateStart;
@property(assign, nonatomic)	int						selectedCandidateLength;

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
		self.backgroundColour		= [AZColour clearColour];
		self.stringValue 			= @"";
		self.textColour				= [AZColour blackColour];
		//NSRect r 					= NSInsetRect(self.bounds, 6, 0);
		//r.origin.y	  			   += 6;
		//self.editArea 				= r;
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
	if (self.enabled && (self.state == AZControlStateNormal))
		{
		self.state = AZControlStateHighlighted;
		SDL_StartTextInput(self.window.window);
		TTF_SetTextColor(_text, _textColour.red,
								_textColour.green,
								_textColour.blue,
								_textColour.alpha);

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
	if (self.state != AZControlStateNormal)
		{
		self.state = AZControlStateNormal;
		SDL_StopTextInput(self.window.window);
		[_blinkTimer invalidate];
		_blinkTimer = nil;
		self.showCursor = NO;
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
	if (_text)
		{
		[self _editSetCursorPosition:0];
		[self _editDeleteToEnd];
		[self _editInsert:stringValue.UTF8String];
		[self setNeedsDisplay:YES];
		}
	}

- (void) setObjectValue:(NSObject *)objectValue
	{
	return [self setStringValue:objectValue.description];
	}

/*****************************************************************************\
|* Likewise, return the string from the TTF_Text
\*****************************************************************************/
- (NSString *)stringValue
	{
	return [NSString stringWithUTF8String:_text->text];
	}

/*****************************************************************************\
|* Draw the textField
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[super drawInRect:dirtyRect withPainter:painter];

	TTF_SetTextColor(_text, _textColour.red,
							_textColour.green,
							_textColour.blue,
							_textColour.alpha);
	if (!self.enabled)
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

	AZRenderer *azr = AZRenderer.renderer;
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

	AZRenderer *azr = AZRenderer.renderer;
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


// MARK: Events

/*****************************************************************************\
|* Handle a mouse press
\*****************************************************************************/
- (BOOL) mouseDown:(AZEvent *)e
	{
	[self.window makeFirstResponder:self];
	NSPoint p = [self convertPoint:e.locationInWindow fromView:nil];

    // Set the cursor position
    TTF_SubString substring;
	int textX = (int)SDL_roundf(p.x - _editArea.origin.x);
    int textY = (int)SDL_roundf(p.y - _editArea.origin.y);

    if (!TTF_GetTextSubStringForPoint(_text, textX, textY, &substring))
		{
        SDL_Log("Couldn't get cursor location: %s\n", SDL_GetError());
        return false;
		}

 	TTF_Font *font = AZApp.controlFont.ttfFont;
	int index = [self _editGetCursorTextIndexFor:font at:textX in:&substring];
	[self _editSetCursorPosition:index];

    _highlighting 	= YES;
    _highlightFrom	= _cursor;
    _highlightTo 	= -1;

	return self.enabled;
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

	TTF_SubString substring;
	int textX = (int)SDL_roundf(p.x - _editArea.origin.x);
    int textY = (int)SDL_roundf(p.y - _editArea.origin.y);
    if (!TTF_GetTextSubStringForPoint(_text, textX, textY, &substring))
		{
        SDL_Log("Couldn't get cursor location: %s\n", SDL_GetError());
        return false;
		}

 	TTF_Font *font = AZApp.controlFont.ttfFont;
	int index = [self _editGetCursorTextIndexFor:font at:textX in:&substring];
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
		[self _editInsert:e->text];
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
		[self _editHandleComposition:e];
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
		[self _editClearCandidates];
		[self _editSaveCandidates:e];
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
		AZRenderer *azr = AZRenderer.renderer;
		[azr setBlendMode:SDL_BLENDMODE_BLEND];
		[azr setDrawColourToRed:0 g:0 b:0 a:0xff];
		[azr renderFilledRect:NS_RECT(_cursorRect)];
		}
	}

/*****************************************************************************\
|* Draw the actual text itself
\*****************************************************************************/
- (void) _editDrawText:(TTF_Text *)text atX:(int)x y:(int)y
		   withPainter:(AZPainter *)P
	{
    TTF_DrawRendererText(text, x, y+1);
	}

/*****************************************************************************\
|* Draw the editable contents
\*****************************************************************************/
- (void) _editDrawTextWithPainter:(AZPainter *)P
	{
	AZRenderer *azr	= AZRenderer.renderer;
	[azr setBlendMode:SDL_BLENDMODE_BLEND];
	[azr setDrawColour:[AZColour blackColour]];

	TTF_Font *font	= AZApp.controlFont.ttfFont;
    float x 		= _editArea.origin.x;
    float y 		= _editArea.origin.y;

	//[P rectangleWithRect:_editArea colour:AZColour.redColour];

	NSRect existing 	= azr.clipRect;
	NSRect nsClip       = NSIntersectionRect(existing, _origArea);
	[azr setClip:nsClip];

	[self _editDrawText:_text atX:x y:y withPainter:P];

	if ((existing.size.width > 0) && (existing.size.height > 0))
		[azr setClip:existing];
	else
		[azr unsetClip];

	// Draw any highlight
    int marker, length;
    if ([self _editGetHighlightExtentsFrom:&marker withLength:&length])
		{
		[azr setBlendMode:SDL_BLENDMODE_BLEND_PREMULTIPLIED];
        TTF_SubString **highlights =
					TTF_GetTextSubStringsForRange(_text, marker, length, NULL);
        if (highlights)
			{
            int i;
			[azr setDrawColourToRed:0 g:0 b:0xff a:0x10];
            for (i = 0; highlights[i]; ++i)
				{
                SDL_FRect rect;
                SDL_RectToFRect(&highlights[i]->rect, &rect);
                rect.x += x;
                rect.y += y;
				rect.h += 2;
				
                int maxH  = self.bounds.size.height
						  - _bTM[0].size.height
						  - _bBM[0].size.height;
                rect.h    = (rect.h > maxH) ? maxH : rect.h;

				[azr renderFilledRect:NS_RECT(rect)];
				}
            SDL_free(highlights);
			}
		}


    // Calculate the cursor rect, used for positioning candidates
	TTF_SubString cursor;
	if (TTF_GetTextSubString(_text, _cursor, &cursor))
		{
		SDL_FRect cursor_rect;
		SDL_RectToFRect(&cursor.rect, &cursor_rect);

		if (TTF_GetFontDirection(font) == TTF_DIRECTION_RTL)
			cursor_rect.x += cursor.rect.w;

            cursor_rect.x += _editArea.origin.x;
            cursor_rect.y += _editArea.origin.y;
            cursor_rect.w = 1.f;

            SDL_copyp(&_cursorRect, &cursor_rect);

            [self _editUpdateTextInputArea];
        }

	if (_compositionLength > 0)
		[self _editDrawComposition];

	if (_candidates)
		[self _editDrawCandidatesWithPainter:P];

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
	AZApplication *app = AZApp;

	_text	= TTF_CreateText(app.textEngine, app.controlFont.ttfFont, NULL, 0);
	if (_text == nil)
		{
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
				"Cannot create TTF text renderer!");
		return NO;
		}
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

	// We support rendering the composition and candidates
    SDL_SetHint(SDL_HINT_IME_IMPLEMENTED_UI, "composition,candidates");

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
- (void) _editInsert:(const char *)text
	{
	if (!text)
		return;

	[self _editDeleteHighlight];

    if (_compositionLength > 0)
		{
        TTF_DeleteTextString(_text, _compositionStart, _compositionLength);
        _compositionLength = 0;
		}

    size_t length = SDL_strlen(text);
    TTF_InsertTextString(_text, _cursor, text, length);
    [self _editSetCursorPosition:(int)(_cursor + length)];
	[self _editEnsureCursorVisible];

	[self setNeedsDisplay:YES];
	}


/*****************************************************************************\
|* Make sure the cursor is visible by manipulating the textbox area
\*****************************************************************************/
- (void) _editEnsureCursorVisible
	{
	TTF_SubString cursor;
	if (_text->text != NULL)
		{
		if (TTF_GetTextSubString(_text, _cursor, &cursor))
			{
			// If the cursor would go off the screen to the right, push the
			// editArea off to the left to compensate
			int cx = cursor.rect.w + cursor.rect.x;
			int cumulativeWidth = 0;
			int maxX = _origArea.size.width
					- _bCL[0].size.width
					- _bCR[0].size.width;
			TTF_SubString prefix, next;
			TTF_GetTextSubString(_text, 0, &prefix);
			while (cx - cumulativeWidth > maxX)
				{
				cumulativeWidth += prefix.rect.w;
				TTF_GetNextTextSubString(_text, &prefix, &next);
				prefix = next;
				}
			_editArea.origin.x = _origArea.origin.x - cumulativeWidth;
			}
		}
	}

/*****************************************************************************\
|* Get rid of any highlight
\*****************************************************************************/
- (BOOL) _editDeleteHighlight
	{
    if (!_text->text)
        return NO;

	int marker, length;
    if ([self _editGetHighlightExtentsFrom:&marker withLength:&length])
		{
        TTF_DeleteTextString(_text, marker, length);
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
    if (_compositionLength > 0)
		{
        // Don't let the cursor be moved into the composition
        if (position >= _compositionStart
        &&  position <= (_compositionStart + _compositionLength))
            return;

        [self _editCancelComposition];
		}

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
|* Cancel the composition
\*****************************************************************************/
- (void) _editCancelComposition
	{
    [self _editResetComposition];
	SDL_ClearComposition(self.window.window);
	}


/*****************************************************************************\
|* Reset the composition
\*****************************************************************************/
- (void) _editResetComposition
	{
    _compositionStart 			= 0;
    _compositionLength 			= 0;
    _compositionCursor 			= 0;
    _compositionCursorLength 	= 0;
	}

/*****************************************************************************\
|* Backspace to the beginning of the textfield
\*****************************************************************************/
- (void) _editBackspaceToBeginning
	{
    // Delete to the beginning of the string
    TTF_DeleteTextString(_text, 0, _cursor);
	[self _editSetCursorPosition:0];
	}

/*****************************************************************************\
|* Backspace a single character
\*****************************************************************************/
- (void) _editBackspace
	{
    if (!_text->text)
        return;

	if ([self _editDeleteHighlight])
		return;

    if (_cursor > 0)
		{
        const char *start 	= &(_text->text[_cursor]);
        const char *next 	= start;
        SDL_StepBackUTF8(_text->text, &next);
        int length = (int)(uintptr_t)(start - next);
        TTF_DeleteTextString(_text, _cursor - length, length);
        _cursor -= length;
		[self _editEnsureCursorVisible];
		}
	}

/*****************************************************************************\
|* Convert the text input area and cursor into window coordinates
\*****************************************************************************/
- (void) _editUpdateTextInputArea
	{
	AZRenderer *azr = AZRenderer.renderer;

    SDL_FPoint window_edit_rect_min;
    SDL_FPoint window_edit_rect_max;
    SDL_FPoint window_cursor;

	if (![azr convertRx:_editArea.origin.x
					 ry:_editArea.origin.y
					 to:&window_edit_rect_min.x
					 wy:&window_edit_rect_min.y]
	||  ![azr convertRx:_editArea.origin.x + _editArea.size.width
					 ry:_editArea.origin.y + _editArea.size.height
					 to:&window_edit_rect_max.x
					 wy:&window_edit_rect_max.y]
	||  ![azr convertRx:_cursorRect.x
					 ry:_cursorRect.y
					 to:&window_cursor.x
					 wy:&window_cursor.y])
		return;

    SDL_Rect rect;
    rect.x = (int)SDL_roundf(window_edit_rect_min.x);
    rect.y = (int)SDL_roundf(window_edit_rect_min.y);
    rect.w = (int)SDL_roundf(window_edit_rect_max.x - window_edit_rect_min.x);
    rect.h = (int)SDL_roundf(window_edit_rect_max.y - window_edit_rect_min.y);
    int cursor_offset = (int)SDL_roundf(window_cursor.x - window_edit_rect_min.x);
	SDL_SetTextInputArea((__bridge SDL_Window *)(self.window), &rect, cursor_offset);
	}

/*****************************************************************************\
|* Select all the text
\*****************************************************************************/
- (void) _editSelectAll
	{
    if (_text->text == NULL)
        return;

	_highlightFrom = 0;
	_highlightTo = (int)SDL_strlen(_text->text);
	}

/*****************************************************************************\
|* Copy to the clipboard
\*****************************************************************************/
- (void) _editCopy
	{
    if (_text->text == NULL)
        return;

    int marker, length;
	if ([self _editGetHighlightExtentsFrom:&marker withLength:&length])
        {
        char *temp = (char *)SDL_malloc(length + 1);
        if (temp)
			{
            SDL_memcpy(temp, &(_text->text[marker]), length);
            temp[length] = '\0';
            SDL_SetClipboardText(temp);
            SDL_free(temp);
			}
		}
	else
        SDL_SetClipboardText(_text->text);
	}

/*****************************************************************************\
|* Paste from the clipboard
\*****************************************************************************/
- (void) _editPaste
	{
    const char *text = SDL_GetClipboardText();
	[self _editInsert:text];
	}

/*****************************************************************************\
|* Cut the selection/text
\*****************************************************************************/
- (void) _editCut
	{
    if (_text->text == NULL)
        return;

    int marker, length;
	if ([self _editGetHighlightExtentsFrom:&marker withLength:&length])
        {
        char *temp = (char *)SDL_malloc(length + 1);
        if (temp)
			{
            SDL_memcpy(temp, &(_text->text[marker]), length);
            temp[length] = '\0';
            SDL_SetClipboardText(temp);
            SDL_free(temp);
			}
        TTF_DeleteTextString(_text, marker, length);
		[self _editSetCursorPosition:marker];
        _highlightFrom 	= -1;
        _highlightTo 	= -1;
		}
	else
        {
        SDL_SetClipboardText(_text->text);
        TTF_DeleteTextString(_text, 0, -1);
        }
	}

/*****************************************************************************\
|* Move the cursor to the start of the line
\*****************************************************************************/
- (void) _moveCursorToStartOfLine
	{
    TTF_SubString substring;
    if (TTF_GetTextSubString(_text, _cursor, &substring)
    &&  TTF_GetTextSubStringForLine(_text, substring.line_index, &substring))
		{
		[self _editSetCursorPosition:substring.offset];
		}
	}

/*****************************************************************************\
|* Move the cursor one character left
\*****************************************************************************/
- (void) _moveCursorLeft
	{
	TTF_Font *font = AZApp.controlFont.ttfFont;
    if (TTF_GetFontDirection(font) == TTF_DIRECTION_RTL)
		[self _moveCursorIndex:1];
    else
		[self _moveCursorIndex:-1];
	}

/*****************************************************************************\
|* Move the cursor one character right
\*****************************************************************************/
- (void) _moveCursorRight
	{
	TTF_Font *font = AZApp.controlFont.ttfFont;
    if (TTF_GetFontDirection(font) == TTF_DIRECTION_RTL)
		[self _moveCursorIndex:-1];
    else
		[self _moveCursorIndex:1];
    }

/*****************************************************************************\
|* Actually do the one-character cursor move
\*****************************************************************************/
- (void) _moveCursorIndex:(int)direction
	{
    TTF_SubString substring;

    if (direction < 0)
		{
        if (TTF_GetTextSubString(_text, _cursor - 1, &substring))
			[self _editSetCursorPosition:substring.offset];
		}
	else
		{
        if (TTF_GetTextSubString(_text,
								 _cursor,
								 &substring)
        &&  TTF_GetTextSubString(_text,
								 substring.offset + SDL_max(substring.length, 1),
								 &substring))
			[self _editSetCursorPosition:substring.offset];
		}
	}

/*****************************************************************************\
|* Move the cursor all the way to the end of the line
\*****************************************************************************/
- (void) _moveCursorToEndOfLine
	{
    TTF_SubString substring;
    if (TTF_GetTextSubString(_text, _cursor, &substring)
	&&  TTF_GetTextSubStringForLine(_text, substring.line_index, &substring))
		[self _editSetCursorPosition:substring.offset + substring.length];
	}

/*****************************************************************************\
|* Delete from the cursor to the end of the line
\*****************************************************************************/
- (void) _editDeleteToEnd
	{
    TTF_DeleteTextString(_text, _cursor, -1);
	}


/*****************************************************************************\
|* Delete a single character
\*****************************************************************************/
- (void) _editDelete
	{
    if (_text->text == NULL)
        return;

	if ([self _editDeleteHighlight])
        return;

    const char *start 	= &(_text->text[_cursor]);
    const char *next 	= start;
    size_t length 		= SDL_strlen(next);
    SDL_StepUTF8(&next, &length);
    length = (next - start);
    TTF_DeleteTextString(_text, _cursor, (int)length);
	}

/*****************************************************************************\
|* Return the byte count for a UTF8 string
\*****************************************************************************/
static int UTF8ByteLength(const char *text, int num_codepoints)
	{
    const char *start = text;
    while (num_codepoints > 0)
		{
        Uint32 ch = SDL_StepUTF8(&text, NULL);
        if (ch == 0)
            break;

        --num_codepoints;
		}
    return (int)(uintptr_t)(text - start);
	}

/*****************************************************************************\
|* Handle compositional text
\*****************************************************************************/
- (void) _editHandleComposition:(SDL_TextEditingEvent *)e
	{
	[self _editDeleteHighlight];

    if (_compositionLength > 0)
		{
        TTF_DeleteTextString(_text, _compositionStart, _compositionLength);
		[self _editResetComposition];
		}

	int length = (int)SDL_strlen(e->text);
    if (length > 0)
		{
        _compositionStart 	= _cursor;
        _compositionLength 	= length;
        TTF_InsertTextString(_text, _compositionStart, e->text, _compositionLength);
        if (e->start > 0 || e->length > 0)
			{
            _compositionCursor = UTF8ByteLength(
								&(_text->text[_compositionStart]), e->start);
            _compositionCursorLength = UTF8ByteLength(
					&(_text->text[_compositionStart + _compositionCursor]),
					e->length);
			}
		else
			{
            _compositionCursor = length;
            _compositionCursorLength = 0;
			}
		}
	}

/*****************************************************************************\
|* Clear the compositional candidates
\*****************************************************************************/
- (void) _editClearCandidates
	{
    if (_candidates)
		{
        TTF_DestroyText(_candidates);
        _candidates = NULL;
		}
    _selectedCandidateStart 	= 0;
    _selectedCandidateLength 	= 0;
	}

/*****************************************************************************\
|* Save the compositional candidates for display/selection
\*****************************************************************************/
- (void) _editSaveCandidates:(SDL_Event *)e
	{
	[self _editClearCandidates];

    BOOL horizontal 		= e->edit_candidates.horizontal;
    int numCandidates 		= e->edit_candidates.num_candidates;
    int selectedCandidate 	= e->edit_candidates.selected_candidate;

    // Calculate the length of the candidates text
    size_t length = 0;
    for (int i = 0; i < numCandidates; ++i)
		{
        if (horizontal)
			{
            if (i > 0)
                ++length;
			}

        length += SDL_strlen(e->edit_candidates.candidates[i]);

        if (!horizontal)
            length ++;
		}
    if (length == 0)
        return;

    ++length; // For null terminator

    char *candidateText = (char *)SDL_malloc(length);
    if (!candidateText)
        return;


    char *dst = candidateText;
    for (int i = 0; i < numCandidates; ++i)
		{
        if (horizontal)
			{
            if (i > 0)
                *dst++ = ' ';
			}

        int length = (int)SDL_strlen(e->edit_candidates.candidates[i]);
        if (i == selectedCandidate)
			{
            _selectedCandidateStart  = (int)(uintptr_t)(dst - candidateText);
            _selectedCandidateLength = length;
			}
        SDL_memcpy(dst, e->edit_candidates.candidates[i], length);
        dst += length;

        if (!horizontal)
            *dst++ = '\n';
		}
    *dst = '\0';

	TTF_Font *font = AZApp.controlFont.ttfFont;
    _candidates = TTF_CreateText(TTF_GetTextEngine(_text), font, candidateText, 0);
    SDL_free(candidateText);

    if (_candidates)
		{
        float r, g, b, a;
        TTF_GetTextColorFloat(_text, &r, &g, &b, &a);
        TTF_SetTextColorFloat(_candidates, r, g, b, a);
		}
	else
		[self _editClearCandidates];
	}

/*****************************************************************************\
|* Draw the composition
\*****************************************************************************/
- (void) _editDrawComposition
	{
    // Draw an underline under the composed text
	AZRenderer *azr				= AZRenderer.renderer;
	TTF_Font *font 				= AZApp.controlFont.ttfFont;
	TTF_SubString **substrings	= NULL;

    int fontHeight = TTF_GetFontHeight(font);
    substrings = TTF_GetTextSubStringsForRange(_text, _compositionStart,
											   _compositionLength, NULL);
    if (substrings)
		{
        for (int i = 0; substrings[i]; ++i)
			{
            SDL_FRect rect;
            SDL_RectToFRect(&substrings[i]->rect, &rect);
			rect.x += _editArea.origin.x;
            rect.y += _editArea.origin.y + fontHeight;
            rect.h  = 1.0f;
			[azr renderFilledRect:NS_RECT(rect)];
			}
        SDL_free(substrings);
		}

    // Thicken the underline under the active clause in the composed text
    if (_compositionCursorLength > 0)
		{
        substrings = TTF_GetTextSubStringsForRange(
							_text,
							_compositionStart + _compositionCursor,
							_compositionCursorLength,
							NULL);
        if (substrings)
			{
            for (int i = 0; substrings[i]; ++i)
				{
                SDL_FRect rect;
                SDL_RectToFRect(&substrings[i]->rect, &rect);
                rect.x += _editArea.origin.x;
				rect.y += _editArea.origin.y + fontHeight -1;
                rect.h = 1.0f;
				[azr renderFilledRect:NS_RECT(rect)];
				}
            SDL_free(substrings);
			}
		}
	}

/*****************************************************************************\
|* Draw the composition candidates
\*****************************************************************************/
- (void) _editDrawCandidatesWithPainter:(AZPainter *)P
	{
	AZRenderer *azr	= AZRenderer.renderer;
 	TTF_Font *font 	= AZApp.controlFont.ttfFont;

   SDL_Rect safe_rect;
    SDL_FRect candidates_rect;
    int candidates_w;
    int candidates_h;
    float x, y;

    // Position the candidate window
    TTF_SubString cursor;
    int offset = _compositionStart;
    if (_compositionCursorLength > 0)
        // Place the candidates at the active clause
        offset += _compositionCursor;

    if (!TTF_GetTextSubString(_text, offset, &cursor))
        return;

	safe_rect = SDL_RECT(azr.safeAreaForRendering);
    TTF_GetTextSize(_candidates, &candidates_w, &candidates_h);
    candidates_rect.x = _editArea.origin.x + cursor.rect.x;
    candidates_rect.y = _editArea.origin.y + cursor.rect.y + cursor.rect.h + 2.0f;
    candidates_rect.w = 1.0f + 2.0f + candidates_w + 2.0f + 1.0f;
    candidates_rect.h = 1.0f + 2.0f + candidates_h + 2.0f + 1.0f;
    if ((candidates_rect.x + candidates_rect.w) > safe_rect.w)
		{
        candidates_rect.x = (safe_rect.w - candidates_rect.w);
        if (candidates_rect.x < 0.0f)
            candidates_rect.x = 0.0f;
		}

    // Draw the candidate background
	[azr setDrawColourToRed:0xaa g:0xaa b:0xaa a:0xff];
	[azr renderFilledRect:NS_RECT(candidates_rect)];
	[azr setDrawColourToRed:0x00 g:0x00 b:0x00 a:0xff];
	[azr renderRect:NS_RECT(candidates_rect)];

    // Draw the candidates
    x = candidates_rect.x + 3.0f;
    y = candidates_rect.y + 3.0f;
	[self _editDrawText:_candidates atX:x y:y withPainter:P];

    // Underline the selected candidate
    if (_selectedCandidateLength > 0)
		{
		TTF_SubString **substrings	= NULL;
		int fontHeight 				= TTF_GetFontHeight(font);

        substrings = TTF_GetTextSubStringsForRange(_candidates,
												   _selectedCandidateStart,
												   _selectedCandidateLength,
												   NULL);
        if (substrings)
			{
            for (int i = 0; substrings[i]; ++i)
				{
                SDL_FRect rect;
                SDL_RectToFRect(&substrings[i]->rect, &rect);
                rect.x += x;
                rect.y += (y + fontHeight);
                rect.h = 1.0f;
				[azr renderFilledRect:NS_RECT(rect)];
				}
            SDL_free(substrings);
			}
		}
	}

/*****************************************************************************\
|* Find the text position for a given mouse position
\*****************************************************************************/
- (int) _editGetCursorTextIndexFor:(TTF_Font *)font
								at:(int)x
								in:(TTF_SubString *)substring
	{
    if (substring->flags & (TTF_SUBSTRING_LINE_END | TTF_SUBSTRING_TEXT_END))
        return substring->offset;

    bool roundDown;
    if (TTF_GetFontDirection(font) == TTF_DIRECTION_RTL)
        roundDown = (x > (substring->rect.x + substring->rect.w / 2));
    else
        roundDown = (x < (substring->rect.x + substring->rect.w / 2));

    if (roundDown)
        // Start the cursor before the selected text
        return substring->offset;
	else
        // Place the cursor after the selected text
        return substring->offset + substring->length;
    }


@end
