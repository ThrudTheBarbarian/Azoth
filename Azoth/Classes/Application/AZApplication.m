//
//  AZApplication.m
//  Azoth
//
//  Created by Simon Gornall on 12/11/24.
//

#import <SDL3/SDL.h>
#import <SDL3_image/SDL_image.h>
#import <SDL3_ttf/SDL_ttf.h>

#import "AZApplication.h"
#import "AZAppDelegate.h"
#import "AZColour.h"
#import "AZEvent.h"
#import "AZEventSink.h"
#import "AZFont.h"
#import "AZGeometry.h"
#import "AZIconAtlas.h"
#import "AZNotifications.h"
#import "AZObject.h"
#import "AZRenderer.h"
#import "AZTypes.h"
#import "AZView.h"
#import "AZView+Internal.h"
#import "AZWindow.h"
#import "AZWindowContentView.h"
#import "NSBundle+ZIB.h"

NSString * const kTextureType	= @"texture";

NSString * const kUiMap			= @"ui";
NSString * const kIconsMap		= @"icons";
NSString * const kHudMap		= @"hud";
NSString * const kCursorsMap	= @"cursors";

@interface AZApplication()
// This is a place to temporarily store things that the renderer (for example)
// still needs to be alive up until [renderer present] is called, at which
// time they will be deleted
@property(strong, nonatomic) NSMutableArray<NSNumber *> * 		bin;

// A list of event-sinks that allow events to be temporarily
// diverted away from the main event-handling loop
@property(strong, nonatomic) NSMutableArray *					eventSinks;

// A map of integer:dictionary where the dictionary holds
// all the mappings of icons within the texture referenced
// by the integer
@property(strong, nonatomic)
NSMutableDictionary<NSString *, AZIconAtlas *> * 				atlantes;

// A list of objects in the ZIB that we loaded
@property(strong, nonatomic) NSMutableArray<NSObject *> *		zibObjects;

@end

@implementation AZApplication

/*****************************************************************************\
|* Constructor
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
		_bin 				= [NSMutableArray new];
		_eventSinks			= [NSMutableArray new];
		_atlantes			= [NSMutableDictionary new];
		_windowTitle		= @"Window title";
		_rendererType	 	= AZRendererType2d;
		_windowFlags		= 0;
		}
	return self;
	}

/*****************************************************************************\
|* Constructor
\*****************************************************************************/
+ (AZApplication *) sharedApplication
	{
	static AZApplication *instance;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		instance = [AZApplication new];
		});

	return instance;
	}

/*****************************************************************************\
|* Bootstrap the fonts and user-interface maps
\*****************************************************************************/
- (void) _bootstrap
	{
	id<AZRenderer> azr	= AZRenderer.renderer;

	/*************************************************************************\
    |* Create the text renderer for any textboxes
    \*************************************************************************/
	self.textEngine = TTF_CreateRendererTextEngine(azr.renderer);

	/*************************************************************************\
	|* Get the texture atlases for the UI etc. and put them into a GPU texture
	\*************************************************************************/
	for (NSString *name in @[kUiMap, kIconsMap, kHudMap, kCursorsMap])
		{
		AZIconAtlas *atlas = [AZIconAtlas atlasWithName:name];
		if (atlas)
			_atlantes[name] = atlas;
		}

	/*************************************************************************\
	|* Load the system font after notifying the delegate, so it has a
	|* chance to change the system font path
	\*************************************************************************/
	self.systemFont = [AZFont systemFontWithsize:_systemFontInfo.size];
	if (!_systemFont)
		{
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
					  "Failed to load system font %s!",
					  _systemFontInfo.name.fileSystemRepresentation);
		}

	/*************************************************************************\
	|* Similarly the control font
	\*************************************************************************/
	AZFontStyle style =
		{
		.size 	= 14,
		.name 	= AZApp.systemFontInfo.name,
		.style 	= AZFONT_MEDIUM
		};
	_controlFont = [AZFont fontWithStyle:style];
	if (!_controlFont)
		{
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
					  "Failed to load control font %s!",
					  _systemFontInfo.name.fileSystemRepresentation);
		}
		
	/*************************************************************************\
	|* Similarly the boldened-control font
	\*************************************************************************/
	AZFontStyle bstyle =
		{
		.size 	= 14,
		.name 	= AZApp.systemFontInfo.name,
		.style 	= AZFONT_BOLD
		};
	_boldControlFont = [AZFont fontWithStyle:bstyle];
	if (!_boldControlFont)
		{
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
					  "Failed to load bold control font %s!",
					  _systemFontInfo.name.fileSystemRepresentation);
		}
	}

/*****************************************************************************\
|* Return a list of system symbol names for the named images
\*****************************************************************************/
- (NSArray<NSString *> *) systemSymbolNames
	{
	return _atlantes[kIconsMap].metadata.allKeys;
	}

/*****************************************************************************\
|* Application startup code
\*****************************************************************************/
- (void) startWithArgc:(int)argc argv:(char **)argv
	{
	NSNotification *n 	= nil;

	/*************************************************************************\
    |* Make sure we can initialise video
    \*************************************************************************/
    if (!SDL_Init(SDL_INIT_VIDEO))
		{
        SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
		self.viability = SDL_APP_FAILURE;
		return;
		}

	/*************************************************************************\
    |* Initialise font system
    \*************************************************************************/
    if (!TTF_Init())
		{
        SDL_Log("Couldn't initialize TTF: %s\n",SDL_GetError());
        self.viability = SDL_APP_FAILURE;
        return;
		}

	/*************************************************************************\
    |* Choose a renderer
    \*************************************************************************/
	self.viability		= SDL_APP_CONTINUE;
	if (![AZRenderer makeDefaultRendererOfType:_rendererType])
		{
        SDL_Log("Couldn't create renderer: %s", SDL_GetError());
		self.viability = SDL_APP_FAILURE;
		return;
		}
	id<AZRenderer> azr = AZRenderer.renderer;

	/*************************************************************************\
    |* Set up the system-font info with reasonable defaults
    \*************************************************************************/
	_systemFontInfo.name = @"NotoSans";
	_systemFontInfo.size = 12;
	_systemFontInfo.style = AZFONT_MEDIUM;

	/*************************************************************************\
    |* Let the delegate know we're about to start launching
    \*************************************************************************/
	NSMutableDictionary *args = [NSMutableDictionary new];
	for (int i=0; i<argc; i++)
		args[@(i)] = [NSString stringWithUTF8String:argv[i]];
	NSDictionary *info =
		@{
		@"args" : args
		};

	n = [NSNotification notificationWithName:AZApplicationWillLaunch
									  object:self
									userInfo:info];

	SEL willLaunch = SELECTOR(@"applicationWillLaunch:");
	if ([_delegate respondsToSelector:willLaunch])
		[_delegate applicationWillLaunch:n];

	/*************************************************************************\
    |* Look for main.zib and load it if we can
    \*************************************************************************/
	NSString *rsrc 		= NSBundle.mainBundle.resourcePath;
	NSString *zibPath	= [rsrc stringByAppendingPathComponent:@"main.zib"];
	NSFileManager *fm	= NSFileManager.defaultManager;
	if ([fm fileExistsAtPath:zibPath])
		{
		_zibObjects		= NSMutableArray.new;
		[NSBundle.mainBundle loadZibNamed:@"main"
									owner:self
						  topLevelObjects:_zibObjects];
		}

	/*************************************************************************\
    |* Create the window if we didn't load one from a ZIB
    \*************************************************************************/
    if (_window == nil)
		{
		BOOL ok = [azr createWindowWithTitle:_windowTitle
									   frame:_initialFrame
									   style:_windowFlags];
		if (ok)
			{
			_window = azr.window;
			[_window installContentView];
			[self _bootstrap];
			}
		else
			{
			SDL_Log("Couldn't create main window: %s", SDL_GetError());
			self.viability = SDL_APP_FAILURE;
			}
		}

	/*************************************************************************\
    |* Let the delegate know that we've now launched
    \*************************************************************************/
	SEL didLaunch = NSSelectorFromString(@"applicationDidFinishLaunching:");
	if ([self.delegate respondsToSelector:didLaunch])
		[_delegate applicationDidFinishLaunching:n];
	}

/*****************************************************************************\
|* Return the texture-id (or -ve number on error) for a given atlas-by-name
\*****************************************************************************/
- (NSInteger) textureFor:(NSString *)atlasName
	{
	AZIconAtlas *atlas	= _atlantes[atlasName];
	if (atlas)
		return atlas.texture;
	return -2;
	}


/*****************************************************************************\
|* Fill out a box that defines a particular named piece of the UI texture atlas
\*****************************************************************************/
- (NSRect) srcRectFor:(NSString *)symbol in:(NSString *)atlasName
	{
	NSRect rect 		= NSZeroRect;
	AZIconAtlas *atlas	= _atlantes[atlasName];

	NSDictionary *info = [atlas.metadata objectForKey:symbol];
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
	AZEvent * event			= [[AZEvent alloc] initWithSDLEvent:e];

	/*************************************************************************\
	|* If we have an event-sink installed, and it matches this event, then
	|* divert to the sink
	\*************************************************************************/
	for (AZEventSink *sink in _eventSinks)
		{
		if ([sink matches:event])
			if ([sink call:event])
				return result;
		}

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
			[cv processMouseEvent:event];
			break;

		case SDL_EVENT_MOUSE_MOTION:
			[cv processMouseEvent:event];
			break;

		case SDL_EVENT_MOUSE_WHEEL:
			[cv processMouseEvent:event];
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
	id<AZRenderer> azr	= AZRenderer.renderer;

	// Before we render anything into the *textures* make sure there is
	// no outstanding blending effect from the last cycle around
	[azr setBlendMode:SDL_BLENDMODE_NONE];

	// Redraw any of the subviews that need it into their own textures
	AZWindowContentView *wcv = [AZWindow contentViewForWindow:_window];
	if (!NSEqualRects(wcv.dirty, NSZeroRect))
		[wcv _drawDirtyRect];
	[wcv redrawSubViewsIfNecessary];

	// Get the top-level view, draw it as the background
	[azr blitFrom:wcv.bg src:wcv.bounds dst:wcv.bounds];

	// Run through the views in reverse order, telling them to render their
	// subviews to the screen
	for (AZView *subview in [wcv.subviews reverseObjectEnumerator])
		[subview _renderToScreen];

	// Handle any drag-in-progress
	[azr setClip:wcv.bounds];
	[wcv showDragInProgress];
	[azr clear];
/*
	[azr unlockFocus];
	[azr setDrawColour:AZColour.red];
	[azr renderRect:NSMakeRect(50,50,100,100)];

	NSPoint pts[10000];
	for (int i=0; i<10000; i++)
		{
		pts[i].x = SDL_rand(640);
		pts[i].y = SDL_rand(480);
		}
	[azr setDrawColour:AZColour.blue];
	[azr renderPoints:pts count:10000];
*/
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
	return [AZApplication.sharedApplication handleEvent:event
										   withAppState:appState];
	}

/*****************************************************************************\
|* Callback: process the next frame
\*****************************************************************************/
SDL_AppResult SDL_AppIterate(void *appState)
	{
	return [AZApp nextFrameWithAppState:appState];
	}

/*****************************************************************************\
|* Callback: handle death gracefully
\*****************************************************************************/
void SDL_AppQuit(void *appState, SDL_AppResult result)
	{
	[AZApp terminateBecause:result withAppState:appState];

    /* SDL will clean up the window/renderer for us. */
	}


// MARK: Private methods

/*****************************************************************************\
|* When we have assets that need to be disposed of at the end of the rendering
|* loop, they can be put in the bin, and will be purged here.
\*****************************************************************************/
- (void) _purgeBin
	{
	id<AZRenderer> azr	= AZRenderer.renderer;
	for (NSNumber *obj in _bin)
		[azr releaseTexture:obj.integerValue];

	[_bin removeAllObjects];
	}


// MARK: Error cases

/*****************************************************************************\
|* These are the concrete implementations of the macros for any unimplemented
|* code or abstractions
\*****************************************************************************/
void _AZInvalidAbstractInvocation(SEL selector,
								  id object,
								  const char *file,
								  int line)
	{
    [NSException raise:NSInvalidArgumentException
                format:@"-%s only defined for abstract class. "
					    "Define -[%@ %s] in %s:%d!",
                sel_getName(selector),
                [object class],
                sel_getName(selector),
				file,
				line];
	}

void _AZUnimplementedMethod(SEL selector,
							id object,
							const char *file,
							int line)
	{
	NSString *klass = [NSString stringWithFormat:@"%@", [object class]];
    SDL_Log("-[%s %s] unimplemented in %s at %d",
			klass.UTF8String,
			sel_getName(selector),
			file,
			line);
	}

@end

