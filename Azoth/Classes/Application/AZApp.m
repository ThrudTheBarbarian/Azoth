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
#import "AZFont.h"
#import "AZGeometry.h"
#import "AZNotifications.h"
#import "AZObject.h"
#import "AZView.h"
#import "AZView+Internal.h"

NSString * const kTextureType	= @"texture";


@interface AZApp()
// This is a place to temporarily store things that the renderer (for example)
// still needs to be alive up until [renderer present] is called, at which
// time they will be deleted
@property(strong, nonatomic) NSMutableArray<AZObject *> * 		bin;

// This provides the x,y,w,h metadata for graphical UI items
@property(strong, nonatomic) NSDictionary *						uiMap;
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
- (void) startWithArgc:(int)argc argv:(char **)argv state:(void *)state
	{
	NSString *name 	= @"applicationDidFinishLaunching:";
	SEL launch 		= NSSelectorFromString(name);
	if (_delegate && [_delegate respondsToSelector:launch])
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
		_systemFont = [AZFont systemFontWithsize:_systemFontInfo.size];
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

		/*********************************************************************\
		|* Get the texture atlas for the UI and put it into a GPU texture
		\*********************************************************************/
		NSString *rsrc = [[NSBundle bundleForClass:[self class]] resourcePath];
		NSString *atlasPath = [NSString stringWithFormat:@"%@/atlas.png", rsrc];
		SDL_Surface *atlasSurface = IMG_Load(atlasPath.fileSystemRepresentation);
		if (!atlasSurface)
			{
			SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
						  "Failed to load UI atlas at %s!",
						  atlasPath.fileSystemRepresentation);
			}
		else
			{
			_ui = SDL_CreateTextureFromSurface(_renderer, atlasSurface);
			SDL_DestroySurface(atlasSurface);
			atlasPath = [NSString stringWithFormat:@"%@/atlas.plist", rsrc];
			_uiMap = [NSDictionary dictionaryWithContentsOfFile:atlasPath];
			//NSLog(@"uimap:%@", _uiMap);
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
	AZView *cv 				= [AZView contentViewForWindow:_window];
	NSPoint p				= (NSPoint){-1,-1};

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
		|* Handle resize events
		\*********************************************************************/
		case SDL_EVENT_WINDOW_RESIZED:
			{
			SDL_Window *win = SDL_GetWindowFromID(e->window.windowID);
			AZView *cv = [AZView contentViewForWindow:win];
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
	// Before we render anything into the *textures* make sure there is
	// no outstanding blending effect from the last cycle around
	SDL_SetRenderDrawBlendMode(_renderer, SDL_BLENDMODE_NONE);

	// Redraw any of the subviews that need it into their own textures
	AZView *view = [AZView contentViewForWindow:_window];
	if (!NSEqualRects(view.dirty, NSZeroRect))
		[view _drawDirtyRect];
	[view redrawSubViewsIfNecessary];

	// Get the top-level view, draw it as the background
	SDL_FRect rect = SDLFRectFromNSRect(view.bounds);
	SDL_RenderTexture(_renderer, view.bg, &rect, &rect);

	// Run through the views in reverse order, telling them to render their
	// subviews to the screen
	for (AZView *subview in [view.subviews reverseObjectEnumerator])
		[subview _renderToScreen];

	// Tell the renderer we're done
	SDL_RenderPresent(_renderer);

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
- (void) registerTextureForDisposal:(SDL_Texture *)texture
	{
	AZObject *obj = [AZObject objectWithPointer:texture andHint:kTextureType];
	[_bin addObject:obj];
	}


// MARK: Private methods

- (void) _purgeBin
	{
	for (AZObject *obj in _bin)
		{
		if ([obj.hint isEqualToString:kTextureType])
			SDL_DestroyTexture(obj.ptr);
		else
			SDL_Log("Found unknown type '%s' in bin!", obj.hint.UTF8String);
		}
	[_bin removeAllObjects];
	}

@end

