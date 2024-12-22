//
//  AZApp.m
//  Azoth
//
//  Created by Simon Gornall on 12/11/24.
//

#import <SDL3/SDL.h>
#import <SDL3_image/SDL_image.h>
#import <SDL3_ttf/SDL_ttf.h>

#import "AZApp.h"
#import "AZAppDelegate.h"
#import "AZEventSink.h"
#import "AZFont.h"
#import "AZGeometry.h"
#import "AZNotifications.h"
#import "AZObject.h"
#import "AZRenderer.h"
#import "AZView.h"
#import "AZView+Internal.h"
#import "AZWindow.h"

NSString * const kTextureType	= @"texture";


@interface AZApp()
// This is a place to temporarily store things that the renderer (for example)
// still needs to be alive up until [renderer present] is called, at which
// time they will be deleted
@property(strong, nonatomic) NSMutableArray<NSNumber *> * 		bin;

// This provides the x,y,w,h metadata for graphical UI items
@property(strong, nonatomic) NSDictionary *						uiMap;

// This provides the x,y,w,h metadata for graphical UI items
@property(strong, nonatomic) NSMutableArray *					eventSinks;
@end

@implementation AZApp

/*****************************************************************************\
|* Constructor
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
		_bin 			= [NSMutableArray new];
		_eventSinks		= [NSMutableArray new];
		}
	return self;
	}

/*****************************************************************************\
|* Constructor
\*****************************************************************************/
+ (AZApp *) sharedInstance
	{
	static AZApp *instance;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		instance = [AZApp new];
		});

	return instance;
	}

/*****************************************************************************\
|* Application startup code
\*****************************************************************************/
- (void) startWithArgc:(int)argc argv:(char **)argv
	{
	AZRenderer *azr = nil;

	/*************************************************************************\
    |* Create the window
    \*************************************************************************/
	_window = [AZWindow windowWithContentRect:_initialFrame
									styleMask:_windowFlags];
    if (self.window == nil)
		{
        SDL_Log("Couldn't create main window: %s", SDL_GetError());
		self.viability = SDL_APP_FAILURE;
		}
	else
		{
		azr = [AZRenderer renderer];
		[self.window installContentView];
		}
	/*************************************************************************\
    |* Create the text renderer for any textboxes
    \*************************************************************************/
	self.textEngine = TTF_CreateRendererTextEngine(azr.renderer);

	/*************************************************************************\
	|* Get the texture atlas for the UI and put it into a GPU texture
	\*************************************************************************/
	NSString *rsrc = [[NSBundle bundleForClass:[self class]] resourcePath];
	NSString *atlasPath = [NSString stringWithFormat:@"%@/atlas.png", rsrc];
	SDL_Surface *atlasSurface = IMG_Load(atlasPath.fileSystemRepresentation);
	if (!atlasSurface)
		{
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
					  "Failed to load UI atlas at %s!",
					  atlasPath.fileSystemRepresentation);
        self.viability =  SDL_APP_FAILURE;
		}
	else
		{
		self.ui = [azr createTextureWithSurface:atlasSurface];
		if (self.ui < 0)
			{
			SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
						  "Failed to create UI atlas!");
			self.viability =  SDL_APP_FAILURE;
			}

		SDL_DestroySurface(atlasSurface);
		atlasPath = [NSString stringWithFormat:@"%@/atlas.plist", rsrc];
		self.uiMap = [NSDictionary dictionaryWithContentsOfFile:atlasPath];
		if (!_uiMap)
			{
			SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
						  "Failed to load UI atlas metdata at %s!",
						  atlasPath.fileSystemRepresentation);
			self.viability =  SDL_APP_FAILURE;
			}
		}

	/*************************************************************************\
    |* Let the delegate say what the system font is going to be
    \*************************************************************************/
	NSString *name 	= @"applicationDidFinishLaunching:";
	SEL launch 		= NSSelectorFromString(name);
	if (self.delegate && [self.delegate respondsToSelector:launch])
		{
		/*********************************************************************\
		|* Set up the system-font info with reasonable defaults
		\*********************************************************************/
		_systemFontInfo.name = @"NotoSans-Medium";
		_systemFontInfo.size = 14;
		_systemFontInfo.style = AZFONT_STYLE_NORMAL;

		/*********************************************************************\
		|* Tell the delegate we're about to launch
		\*********************************************************************/
		NSMutableDictionary *args = [NSMutableDictionary new];
		for (int i=0; i<argc; i++)
			args[@(i)] = [NSString stringWithUTF8String:argv[i]];
		NSDictionary *info =
			@{
			@"args" : args
			};

		NSNotification *n = [NSNotification notificationWithName:name
														  object:self
														userInfo:info];
		[_delegate applicationDidFinishLaunching:n];

		/*********************************************************************\
		|* Load the system font after notifying the delegate, so it has a
		|* chance to change the system font path
		\*********************************************************************/
		self.systemFont = [AZFont systemFontWithsize:_systemFontInfo.size];
		if (!_systemFont)
			{
			SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
						  "Failed to load system font at %s!",
						  _systemFontInfo.name.fileSystemRepresentation);
			}

		/*********************************************************************\
		|* Similarly the control font
		\*********************************************************************/
		_controlFont = [AZFont systemFontWithsize:16];
		if (!_controlFont)
			{
			SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
						  "Failed to load control font at %s!",
						  _systemFontInfo.name.fileSystemRepresentation);
			}
		}
	}

/*****************************************************************************\
|* Fill out a box that defines a particular named piece of the UI texture atlas
\*****************************************************************************/
- (NSRect) srcRectFor:(NSString *)uiName
	{
	NSRect rect = NSZeroRect;
	NSDictionary *info = [_uiMap objectForKey:uiName];
	if (info)
		{
		rect.origin.x	 	= ((NSNumber *)info[@"x"]).floatValue;
		rect.origin.y 		= ((NSNumber *)info[@"y"]).floatValue;
		rect.size.width 	= ((NSNumber *)info[@"w"]).floatValue;
		rect.size.height	= ((NSNumber *)info[@"h"]).floatValue;
		}
	return rect;
	}

/*****************************************************************************\
|* Handle events
\*****************************************************************************/
- (SDL_AppResult) handleEvent:(SDL_Event *)e withAppState:(void *)state
	{
	SDL_AppResult result 	= SDL_APP_CONTINUE;
	AZView *cv 				= [AZWindow contentViewForWindow:_window];
	NSPoint p				= (NSPoint){-1,-1};

	/*************************************************************************\
	|* If we have an event-sink installed, and it matches this event, then
	|* divert to the sink
	\*************************************************************************/
	for (AZEventSink *sink in _eventSinks)
		if ([sink matches:e])
			if ([sink call:e])
				return result;

	/*************************************************************************\
	|* Else process the event
	\*************************************************************************/
	switch (e->type)
		{
		/*********************************************************************\
		|* Tell the OS that we successfully quit
		\*********************************************************************/
		case SDL_EVENT_QUIT:
			result = SDL_APP_SUCCESS;
			break;

		/*********************************************************************\
		|* Handle mouse events
		\*********************************************************************/
		case SDL_EVENT_MOUSE_BUTTON_DOWN:
		case SDL_EVENT_MOUSE_BUTTON_UP:
			p.x = ((SDL_MouseButtonEvent *)e)->x;
			p.y = ((SDL_MouseButtonEvent *)e)->y;
			[cv processMouseEvent:e atPoint:p];
			break;

		case SDL_EVENT_MOUSE_MOTION:
			p.x = ((SDL_MouseMotionEvent *)e)->x;
			p.y = ((SDL_MouseMotionEvent *)e)->y;
			[cv processMouseEvent:e atPoint:p];
			break;

		case SDL_EVENT_MOUSE_WHEEL:
			p.x = ((SDL_MouseMotionEvent *)e)->x;
			p.y = ((SDL_MouseMotionEvent *)e)->y;
			[cv processMouseEvent:e atPoint:p];
			break;

		/*********************************************************************\
		|* Keyboard
		\*********************************************************************/
		case SDL_EVENT_TEXT_EDITING_CANDIDATES:
			if (_window.firstResponder)
				[_window.firstResponder textEditingCandidates:e];
			break;

		case SDL_EVENT_TEXT_EDITING:
			if (_window.firstResponder)
				[_window.firstResponder textEditing:&(e->edit)];
			break;

		case SDL_EVENT_TEXT_INPUT:
			if (_window.firstResponder)
				[_window.firstResponder textInput:&(e->text)];
			break;

		case SDL_EVENT_KEY_DOWN:
			if (_window.firstResponder)
				[_window.firstResponder keyDown:&(e->key)];
			break;

		/*********************************************************************\
		|* Handle resize events
		\*********************************************************************/
		case SDL_EVENT_WINDOW_RESIZED:
			{
			int w = e->window.data1;
			int h = e->window.data2;

			NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
			[nc postNotificationName:AZRootViewWillResizeNotification object:cv];
			[cv setFrame:NSMakeRect(0,0,w,h)];
			break;
			}
		}

	/* carry on with the program! */
	return result;
	}


/*****************************************************************************\
|* Handle redraw
\*****************************************************************************/
- (SDL_AppResult) nextFrameWithAppState:(void *)state
	{
	AZRenderer *azr = AZRenderer.renderer;

	// Before we render anything into the *textures* make sure there is
	// no outstanding blending effect from the last cycle around
	[azr setBlendMode:SDL_BLENDMODE_NONE];

	// Redraw any of the subviews that need it into their own textures
	AZView *view = [AZWindow contentViewForWindow:_window];
	if (!NSEqualRects(view.dirty, NSZeroRect))
		[view _drawDirtyRect];
	[view redrawSubViewsIfNecessary];

	// Get the top-level view, draw it as the background
	[azr blitFrom:view.bg src:view.bounds dst:view.bounds];

	// Run through the views in reverse order, telling them to render their
	// subviews to the screen
	for (AZView *subview in [view.subviews reverseObjectEnumerator])
		[subview _renderToScreen];

	// Tell the renderer we're done
	[azr present];

	// If there's anything in the bin, get rid of it safely now
	[self _purgeBin];

    // carry on with the program!
    return SDL_APP_CONTINUE;
	}

/*****************************************************************************\
|* Die gracefully
\*****************************************************************************/
- (void) terminateBecause:(SDL_AppResult)reason withAppState:(void *)state
	{}


/*****************************************************************************\
|* Application service: dispose of things after renderPresent called
\*****************************************************************************/
- (void) registerTextureForDisposal:(NSNumber *)texture
	{
	[_bin addObject:texture];
	}

// MARK: Event sinks

/*****************************************************************************\
|* Add an event sink
\*****************************************************************************/
- (void) addEventSink:(AZEventSink *)sink
	{
	[_eventSinks addObject:sink];
	}

/*****************************************************************************\
|* Remove an event sink
\*****************************************************************************/
- (void) removeEventSink:(AZEventSink *)sink
	{
	[_eventSinks removeObject:sink];
	}

// MARK: SDL callbacks

/*****************************************************************************\
|* Callback: This function runs when a new event occurs
\*****************************************************************************/
SDL_AppResult SDL_AppEvent(void *appState, SDL_Event *event)
	{
	return [AZApp.sharedInstance handleEvent:event withAppState:appState];
	}

/*****************************************************************************\
|* Callback: process the next frame
\*****************************************************************************/
SDL_AppResult SDL_AppIterate(void *appState)
	{
	AZApp *app = AZApp.sharedInstance;
	return [app nextFrameWithAppState:appState];
	}

/*****************************************************************************\
|* Callback: handle death gracefully
\*****************************************************************************/
void SDL_AppQuit(void *appState, SDL_AppResult result)
	{
	AZApp *app = AZApp.sharedInstance;
	[app terminateBecause:result withAppState:appState];

    /* SDL will clean up the window/renderer for us. */
	}


// MARK: Private methods

- (void) _purgeBin
	{
	AZRenderer *azr = [AZRenderer renderer];
	for (NSNumber *obj in _bin)
		[azr releaseTexture:obj.integerValue];

	[_bin removeAllObjects];
	}

@end

