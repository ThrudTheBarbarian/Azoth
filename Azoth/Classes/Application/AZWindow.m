//
//  AZWindow.m
//  Azoth
//
//  Created by Simon Gornall on 12/16/24.
//

#import <SDL3/SDL.h>
#import <SDL3_image/SDL_image.h>
#import <SDL3_ttf/SDL_ttf.h>

#import <AZApplication.h>
#import "AZView.h"
#import "AZView+Internal.h"
#import "AZWindow.h"
#import "AZWindowContentView.h"

@interface AZWindow()
// The list of responders in the window
@property(retain, nonatomic) NSMutableArray<AZResponder *>* responders;
@end

/*****************************************************************************\
|* Store the top-level content-views for each window we know about
\*****************************************************************************/
static NSMutableDictionary<NSNumber*,AZWindowContentView*>* _contentViews = nil;

/*****************************************************************************\
|* Store the top-level windows for each SDLwindow we know about
\*****************************************************************************/
static NSMutableDictionary<NSNumber *, AZWindow *> * _windows = nil;

@implementation AZWindow

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithWindow:(struct SDL_Window *)window
	{
	if (self = [super init])
		{
		/*********************************************************************\
		|* Set up the responder state storage and content-view map
		\*********************************************************************/
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken,
			^{
			self.responders 	= [NSMutableArray new];
			self.firstResponder = nil;

			_contentViews 		= [NSMutableDictionary new];
			_windows			= [NSMutableDictionary new];
			});

		/*********************************************************************\
		|* Set up the window map and the top-level content view
		\*********************************************************************/
		_window					= window;
		NSNumber *winId			= @(SDL_GetWindowID(window));
		AZApp.windows[winId]	= self;
		}

	return self;
	}

/*****************************************************************************\
|* Add a content view to the window
\*****************************************************************************/
- (void) installContentView
	{
	int w,h;
	SDL_GetWindowSizeInPixels(_window, &w, &h);
	AZWindowContentView *cv 	= [[AZWindowContentView alloc] initWithWindow:self];
	[self installContentView:cv];
	}

/*****************************************************************************\
|* Add a content view to the window
\*****************************************************************************/
- (void) installContentView:(AZWindowContentView *)contentView
	{
	contentView.window		= self;
	NSNumber *windowId 		= @(SDL_GetWindowID(_window));

	_contentViews[windowId] = contentView;
	contentView.isOpaque 	= YES;
	self.contentView		= contentView;

	[contentView _installBackingTexture];
	}

/*****************************************************************************\
|* Return the window for the given SDL_Window.
\*****************************************************************************/
+ (AZWindow *) windowForSDLWindow:(SDL_Window *)sdlWindow
	{
	return _windows[@(SDL_GetWindowID(sdlWindow))];
	}

/*****************************************************************************\
|* Return the contentView for any given SDL_Window. If one does not exist it
|* will be created and returned
\*****************************************************************************/
+ (AZWindowContentView *) contentViewForWindow:(AZWindow *)window
	{
	return [self contentViewForSDLWindow:window.window];
	}

+ (AZWindowContentView *) contentViewForSDLWindow:(struct SDL_Window *)window;
	{
	NSNumber *windowId = @(SDL_GetWindowID(window));
	return [_contentViews objectForKey:windowId];
	}

/*****************************************************************************\
|* Make an AZResponder the first-responder
\*****************************************************************************/
- (BOOL) makeFirstResponder:(nullable AZResponder *)responder
	{
	BOOL changed = NO;
	if (responder == nil)
		{
		if (self.responders.count == 0)
			_firstResponder = nil;
		else
			{
			if ([self.responders.lastObject becomeFirstResponder])
				_firstResponder = self.responders.lastObject;
			else
				_firstResponder = nil;
			}
		}
	else if ([responder acceptsFirstResponder])
		{
		if (self.firstResponder != nil)
			{
			if ([self.firstResponder resignFirstResponder])
				changed = YES;
			}
		else
			changed = YES;
		}

	if (changed)
		{
		[self.responders addObject:responder];
		self.firstResponder = responder;
		[responder becomeFirstResponder];
		}
	return changed;
	}

/*****************************************************************************\
|* Allow setting of the title
\*****************************************************************************/
- (void) setTitle:(NSString *)title
	{
	_title = title;
	SDL_SetWindowTitle(_window, title.UTF8String);
	}

/*****************************************************************************\
|* End editing
\*****************************************************************************/
- (void) endEditingFor:(id)sender
	{
	// FIXME: Not implemented yet
	}

/*****************************************************************************\
|* For NIB loading, determine if a window (with a specific style-mask) means
|* there is a MainMenu to be added to it.
\*****************************************************************************/
+ (BOOL) hasMainMenuForStyleMask:(NSUInteger)styleMask
	{
	// FIXME: Not implemented yet
	return NO;
	}

@end
