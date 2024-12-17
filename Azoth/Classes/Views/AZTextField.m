//
//  AZTextField.m
//  Azoth
//
//  Created by Simon Gornall on 12/16/24.
//

#import <SDL3/SDL.h>
#import <SDL3_ttf/SDL_ttf.h>

#import "AZApp.h"
#import "AZColour.h"
#import "AZFont.h"
#import "AZNotifications.h"
#import "AZPainter.h"
#import "AZTextField.h"
#import "AZTextPainter.h"
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

@interface AZTextField()
@property(assign, nonatomic)	TTF_Text *				text;
@property(assign, nonatomic)	BOOL 					hasFocus;

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

@property(strong, nonatomic) 	NSTimer *				blinkTimer;
@end

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
		self.stringValue 	= @"";
		_editArea 			= NSInsetRect(self.bounds, 6, 2);
		_editArea.origin.y += 1;

		if (![self _editCreate])
			self = nil;
		}
	return self;
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
	if (self.state == ControlStateNormal)
		{
		_hasFocus = YES;
		self.state = ControlStateHighlighted;
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
		_hasFocus = NO;
		self.state = ControlStateNormal;
		SDL_StopTextInput(self.window.window);
		[_blinkTimer invalidate];
		_blinkTimer = nil;
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

	[self _drawTextInRect:_editArea withPainter:p];
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


// MARK: Editing

/*****************************************************************************\
|* Key event handling
\*****************************************************************************/
- (BOOL) textInput:(struct SDL_TextInputEvent *)e
	{
	[self _editInsert:e->text];
	return YES;
	}

/*****************************************************************************\
|* Drawing
\*****************************************************************************/
- (void) _drawTextInRect:(NSRect)r withPainter:(AZPainter *)P
	{
		[self _editDraw];
	}

/*****************************************************************************\
|* Draw the editable contents
\*****************************************************************************/
- (void) _editDraw
	{
	AZApp *app 				= AZApp.sharedInstance;
	SDL_Renderer *renderer 	= app.window.renderer;
    float x 				= _editArea.origin.x;
    float y 				= _editArea.origin.y;

	// Draw any highlight
    int marker, length;
    if ([self _editGetHighlightExtentsFrom:&marker to:&length])
		{
        TTF_SubString **highlights =
					TTF_GetTextSubStringsForRange(_text, marker, length, NULL);
        if (highlights)
			{
            int i;
            SDL_SetRenderDrawColor(renderer, 0xEE, 0xEE, 0x00, 0xFF);
            for (i = 0; highlights[i]; ++i)
				{
                SDL_FRect rect;
                SDL_RectToFRect(&highlights[i]->rect, &rect);
                rect.x += x;
                rect.y += y;
                SDL_RenderFillRect(renderer, &rect);
				}
            SDL_free(highlights);
			}
		}

	[self _editDrawText:_text atX:x y:y];
	}

- (void) _editDrawText:(TTF_Text *)text atX:(float)x y:(float)y
	{
	SDL_Renderer * R = AZApp.sharedInstance.window.renderer;
	//SDL_SetRenderDrawBlendMode(R, SDL_BLENDMODE_ADD);
		TTF_SetTextColor(text, 0, 0, 0, 255);
    BOOL ok = TTF_DrawRendererText(text, x, y);
	}

/*****************************************************************************\
|* Creation of the editing state
\*****************************************************************************/
- (BOOL) _editCreate
	{
	AZApp *app 				= AZApp.sharedInstance;
	SDL_Renderer *renderer 	= app.window.renderer;

	_text	= TTF_CreateText(app.textEngine, app.controlFont.ttfFont, NULL, 0);
	if (_text == nil)
		{
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
				"Cannot create TTF text renderer!");
		return NO;
		}
	_highlightFrom = -1;
	_highlightTo = -1;
	_editArea = NSInsetRect(self.bounds, 4, 2);

    // Wrap the editbox text within the editbox area
	TTF_SetTextWrapWidth(_text, (int)SDL_floorf(_editArea.size.width));

    // Show whitespace when wrapping, so it can be edited
    TTF_SetTextWrapWhitespaceVisible(_text, true);

	// We support rendering the composition and candidates
    SDL_SetHint(SDL_HINT_IME_IMPLEMENTED_UI, "composition,candidates");

	return YES;
	}

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
    NSLog(@"insert text '%s' of length %lu", text, length);
    TTF_InsertTextString(_text, _cursor, text, length);
    [self _editSetCursorPosition:(int)(_cursor + length)];
	[self setNeedsDisplay:YES];
	}

- (BOOL) _editDeleteHighlight
	{
    if (!_text->text)
        return NO;

	int marker, length;
    if ([self _editGetHighlightExtentsFrom:&marker to:&length])
		{
        TTF_DeleteTextString(_text, marker, length);
        [self _editSetCursorPosition:marker];
        _highlightFrom 	= -1;
        _highlightTo 	= -1;
        return YES;
		}
    return NO;
	}

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
	}

- (BOOL) _editGetHighlightExtentsFrom:(int *)marker to:(int *)length
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

- (void) _editCancelComposition
	{
    [self _editResetComposition];
	SDL_ClearComposition(self.window.window);
	}

- (void) _editResetComposition
	{
    _compositionStart 			= 0;
    _compositionLength 			= 0;
    _compositionCursor 			= 0;
    _compositionCursorLength 	= 0;
	}


//#if 0
///*****************************************************************************\
//|* Key event handling
//\*****************************************************************************/
//- (BOOL) textInput:(struct SDL_TextInputEvent *)e
//	{
//	NSString *value = [NSString stringWithUTF8String:e->text];
//	NSString *pre	= [self.stringValue substringToIndex:_cursor];
//	NSString *post	= [self.stringValue substringFromIndex:_cursor];
//	NSString *newPre= [NSString stringWithFormat:@"%@%@", pre, value];
//	NSString *newVal= [NSString stringWithFormat:@"%@%@", newPre, post];
//
//	self.stringValue = newVal;
//	_cursor += value.length;
//	int cw = [AZApp.sharedInstance.controlFont textWidthFor:newPre];
//	int cx = _editArea.origin.x + cw;
//	_cursorRect = NSMakeRect(cx, 6, 1, _editArea.size.height - 10);
//
//	[self setNeedsDisplay:YES];
//	return YES;
//	}
//
//
//
///*****************************************************************************\
//|* Drawing
//\*****************************************************************************/
//- (void) _drawTextInRect:(NSRect)r withPainter:(AZPainter *)P
//	{
//	[P drawAtX:_editArea.origin.x y:_editArea.origin.y text:self.stringValue];
//	SDL_Renderer *R = AZApp.sharedInstance.window.renderer;
//	SDL_SetRenderDrawBlendMode(R, SDL_BLENDMODE_BLEND);
//	SDL_SetRenderDrawColor(R, 0, 0, 0, 255);
//
//	// Draw the cursor
//	if (_showCursor)
//		{
//		int x = _cursorRect.origin.x;
//		int y = _cursorRect.origin.y;
//		int h = _cursorRect.size.height;
//
//		[P lineAtX:x y:y toX:x y:y+h];
//		}
//	}
//
///*****************************************************************************\
//|* Calculate the displayed string from the real one
//\*****************************************************************************/
//- (void) _calculateDisplayedString
//	{
//	AZApp *app = AZApp.sharedInstance;
//
//	int totalLength = [app.controlFont textWidthFor:self.stringValue];
//	if (totalLength < _editArea.size.width)
//		{
//		_displayedText = self.stringValue;
//		return;
//		}
//
//	if (_cursor == self.stringValue.length)
//		{
//		// Pull from the start of the string to make it fit
//		}
//	}



@end
