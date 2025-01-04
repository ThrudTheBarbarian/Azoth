//
//  AZZib.m
//  Azoth
//
//  Created by Simon Gornall on 1/3/25.
//

#import <SDL3/SDL.h>

#import "AZApplication.h"
#import "AZButton.h"
#import "AZRenderer.h"
#import "AZTypes.h"
#import "AZWindow.h"
#import "AZView.h"
#import "AZZib.h"
#import "NSDictionary+ZIB.h"

/*****************************************************************************\
|* Constant strings, only really used here, but...
\*****************************************************************************/
NSString * const kZibObjects		= @"objects";
NSString * const kZibClassname		= @"class";
NSString * const kZibConnect		= @"connect";
NSString * const kZibIdentifier		= @"id";
NSString * const kZibOwner			= @"owner";
NSString * const kZibWindow			= @"window";
NSString * const kZibContentRect	= @"contentRect";
NSString * const kZibStyle			= @"style";
NSString * const kZibClosable		= @"closable";
NSString * const kZibTitle			= @"title";
NSString * const kZibView			= @"view";
NSString * const kZibFrame			= @"frame";
NSString * const kZibResizeMask		= @"resizeMask";
NSString * const kZibSubviews  		= @"subviews";
NSString * const kZibType	  		= @"type";


/*****************************************************************************\
|* Access to the application's private methods
\*****************************************************************************/
@interface AZApplication (PrivateMethods)
- (void) _bootstrap;
@end

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZZib()

// The Dictionary holding the content of the ZIB
@property(strong, nonatomic) NSDictionary *							zib;

// The Array of objects that have been inflated
@property(strong, nonatomic) NSMutableArray<id> *					inflated;

// The Path to the ZIB file
@property(strong, nonatomic) NSString *								path;

// The Dictionary of objects that will need connections
@property(strong, nonatomic) NSMutableDictionary<NSString *, id> *	connect;

// Objects by identifier
@property(strong, nonatomic) NSMutableDictionary<NSString *, id> *	byId;
@end

@implementation AZZib

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFile:(NSString *)path
	{
	if (self = [super init])
		{
		_path 					= path;
		_connect				= [NSMutableDictionary new];
		_inflated				= [NSMutableArray new];
		_byId					= [NSMutableDictionary new];
		NSError *error 			= nil;
		NSKeyedUnarchiver *src 	= nil;
		NSData *data 			= [NSData dataWithContentsOfFile:path];
		if (data)
			{
			src = [[NSKeyedUnarchiver alloc] initForReadingFromData:data
															  error:&error];
			if (error != nil)
				{
				SDL_Log("Failed to decode ZIB. %s",
						error.localizedDescription.UTF8String);
				self = nil;
				}
			else
				{
				src.requiresSecureCoding = NO;
				_zib = [src decodeObjectForKey:@"graph"];
				}
			}
		else
			{
			SDL_Log("Failed to open ZIB file '%s'", path.UTF8String);
			self = nil;
			}
		}
	return self;
	}

+ (AZZib *) zibWithFile:(NSString *)path
	{
	return [[AZZib alloc] initWithFile:path];
	}

/*****************************************************************************\
|* Inflate the ZIB file so we have real objects, not a dictionary representation
\*****************************************************************************/
- (BOOL) inflateWithOwner:(NSObject *)owner
			   andOptions:(NSDictionary<AZZibOptionsKey, id> *)options
	{
	BOOL  ok = [self _inflateObjects];
	ok 		&= [self _inflateOwner:owner];
	ok 		&= [self _inflateWindow];
	ok 		&= [self _inflateViews];
	return ok;
	}


// MARK: Private methods

/*****************************************************************************\
|* Inflate the Window, checking the class
\*****************************************************************************/
- (BOOL) _inflateViews
	{
	BOOL ok			= YES;
	id info	 		= _zib[kZibView];
	NSRect frame	= NSZeroRect;

	/*************************************************************************\
	|* Make sure we actually have a view table. This is not an error.
	\*************************************************************************/
	if (info == nil)
		return YES;

	/*************************************************************************\
	|* Cope with there being multiple views defined, not just one
	\*************************************************************************/
	NSArray *list = ([info isKindOfClass:NSArray.class])
				  ? (NSArray *)info
				  : @[(NSDictionary *)info];

	/*************************************************************************\
	|* Now create each view and any child views
	\*************************************************************************/
	for (NSDictionary *viewInfo in list)
		{
		AZView *view = [self _createViewFrom:viewInfo forWindow:nil inView:nil];

		/********************************************************************\
		|* Set the identifier
		\********************************************************************/
		if (view)
			ok &= [self _setIdentifierOn:view from:viewInfo in:@"top-view"];
		}

	return ok;
	}

/*****************************************************************************\
|* Inflate the Window, checking the class
\*****************************************************************************/
- (BOOL) _inflateWindow
	{
	BOOL ok					= YES;
	NSDictionary *info	 	= _zib[kZibWindow];
	AZWindow *window		= nil;
	NSRect frame			= NSZeroRect;
	NSUInteger styleMask 	= 0;

	/*************************************************************************\
	|* Make sure we actually have a window table!
	\*************************************************************************/
	if (info == nil)
		{
		SDL_Log("Cannot find window table within ZIB %s", _path.UTF8String);
		ok = NO;
		}

	/*************************************************************************\
	|* Find the content-rect
	\*************************************************************************/
	if (ok)
		{
		frame = [info AZRectWithKey:kZibContentRect];
		if (NSIsEmptyRect(frame))
			ok = NO;
		}

	/*************************************************************************\
	|* Determine the style mask
	\*************************************************************************/
	if (ok && info[kZibStyle])
		{
		NSDictionary *style = info[kZibStyle];
		if ([style[kZibClosable] isEqualToString:@"YES"])
			styleMask |= SDL_WINDOW_RESIZABLE;
		}

	/*************************************************************************\
	|* Create the window if we have a rect
	\*************************************************************************/
	if (ok)
		window = [AZWindow windowWithContentRect:frame styleMask:styleMask];

	/*************************************************************************\
	|* Ok, if we're good, then set the identifier
	\*************************************************************************/
	if (window)
		{
		ok = [self _setIdentifierOn:window from:info in:@"window"];

		// Set the window title
		if (info[kZibTitle])
			window.title = info[kZibTitle];

		// And link us through to the shared application. This is a little
		// different to Cocoa, where the Application has a delegate which is
		// the object with a link to the window, but we don't need a delegate
		// as much as Cocoa does...
		AZApp.window = window;

		// Bootstrap the shared renderer instance at this point. Note that it
		// must be called *after* the window is set into the shared application
		[AZRenderer renderer];

		// And now we have a renderer, call the application to load up its
		// texture-based resources
		[AZApp _bootstrap];
		}

	/*************************************************************************\
	|* Now create the content-view and any child views
	\*************************************************************************/
	if (window)
		{
		NSDictionary *viewInfo = info[kZibView];
		if (viewInfo)
			[self _createViewFrom:viewInfo forWindow:window inView:nil];
		}

	return ok;
	}

/*****************************************************************************\
|* Create a view
\*****************************************************************************/
- (nullable AZView *) _createViewFrom:(NSDictionary *)info
							forWindow:(nullable AZWindow *)window
							   inView:(nullable AZView *)parentView
	{
	AZView *view 		= nil;
	NSString *className = info[kZibClassname];

	/*************************************************************************\
	|* Find the class. Default to a standard view if we can't find the class
	\*************************************************************************/
	Class class = NSClassFromString(className);
	if (class == Nil)
		{
		SDL_Log("Warning: Cannot find view of class '%s'", className.UTF8String);
		class = NSClassFromString(@"AZView");
		}

	/*************************************************************************\
	|* Create an instance of the class and get the ball rolling with view
	|* instantiation if this is the contentView of the window
	\*************************************************************************/
	view = [[class alloc] initWithDictionary:info];
	if (view)
		{
		if ((window != nil) && (parentView == nil))
			{
			view.autoresizingMask = AZViewWidthSizable | AZViewHeightSizable;
			[window installContentView:view];
			}
		else
			{
			/*****************************************************************\
			|* Cocoa measures Y upwards, and SDL measures it downwards, so
			\*****************************************************************/
			NSRect f = view.frame;
			f.origin.y = NSHeight(parentView.frame) - NSMaxY(f);
			view.frame = f;

			/*****************************************************************\
			|* Add the view to its parent, if it's not the root view
			\*****************************************************************/
			[parentView addSubview:view];
			}

		/*********************************************************************\
		|* Register this view's identifier for later
		\*********************************************************************/
		[self _setIdentifierOn:view from:info in:@"view"];

		/*********************************************************************\
		|* Add it to the list of inflated objects
		\*********************************************************************/
		[_inflated addObject:view];

		/*********************************************************************\
		|* And for each subview, do the same thing
		\*********************************************************************/
		NSArray *subviews = info[kZibSubviews];
		for (NSDictionary *subview in subviews)
			[self _createViewFrom:subview forWindow:window inView:view];
		}

	return view;
	}

/*****************************************************************************\
|* Inflate the Owner, checking the class
\*****************************************************************************/
- (BOOL) _inflateOwner:(NSObject *)owner
	{
	BOOL ok 				= YES;
	NSDictionary *info	 	= _zib[kZibOwner];
	NSString *ownerClass 	= info[kZibClassname];

	/*************************************************************************\
	|* Make sure we actually have an owner table!
	\*************************************************************************/
	if (info == nil)
		{
		SDL_Log("Cannot find owner table within ZIB %s", _path.UTF8String);
		ok = NO;
		}

	/*************************************************************************\
	|* And a designated owner-class within that table...
	\*************************************************************************/
	else if (ownerClass == nil)
		{
		SDL_Log("Cannot find owner-class within ZIB %s", _path.UTF8String);
		ok = NO;
		}

	/*************************************************************************\
	|* And if so, that the owner-class matches the passed-in-owner's class
	\*************************************************************************/
	else
		{
		Class zibOwnerClass = NSClassFromString(ownerClass);
		if (![owner isKindOfClass:zibOwnerClass])
			{
			SDL_Log("Owner class (%s) mismatch with ZIB's owner class (%s)",
					owner.class.description.UTF8String,
					ownerClass.UTF8String);
			ok = NO;
			}
		}

	/*************************************************************************\
	|* Ok, if we're good, then set the identifier
	\*************************************************************************/
	if (ok)
		ok = [self _setIdentifierOn:owner from:info in:@"owner"];

	/*************************************************************************\
	|* And store the connections for later
	\*************************************************************************/
	if (ok)
		{
		NSDictionary *connections = info[kZibConnect];
		if (connections)
			_connect[TO_KEY(owner)] = connections;
		}
		
	return ok;
	}

/*****************************************************************************\
|* Inflate the ZIB objects table
\*****************************************************************************/
- (BOOL) _inflateObjects
	{
	BOOL ok = YES;

	/*************************************************************************\
	|* Make sure we actually have an objects table!
	\*************************************************************************/
	if (_zib[kZibObjects] == nil)
		{
		SDL_Log("Cannot find objects table within ZIB %s", _path.UTF8String);
		ok = NO;
		}

	/*************************************************************************\
	|* Cover the case of there being only one object. I can't think of a way
	|* this could happen, but ...
	\*************************************************************************/
	NSArray *objectList = nil;
	if (ok)
		{
		if (![_zib[kZibObjects] isKindOfClass:NSArray.class])
			objectList = @[_zib[kZibObjects]];
		else
			objectList = _zib[kZibObjects];
		}

	/*************************************************************************\
	|* For each object, expand it to a real thing and apply its properties
	\*************************************************************************/
	for (NSDictionary * object in objectList)
		{
		NSString *objectClass = object[kZibClassname];
		Class class			  = NSClassFromString(objectClass);
		if (class != Nil)
			{
			NSObject *obj = class.new;

			NSDictionary *connections = object[kZibConnect];
			if (connections)
				_connect[TO_KEY(obj)] = connections;

			// Set the identifier for this object, crucial for any
			// connection-making later
			ok = [self _setIdentifierOn:obj from:object in:@"objects"];

			// Add the object to the list of inflated instances
			if (ok)
				[_inflated addObject:obj];
			}
		else
			{
			SDL_Log("Cannot create concrete instance of class %s",
					objectClass.UTF8String);
			}
		}

	return ok;
	}

/*****************************************************************************\
|* Perform a selector without clang complaining...
\*****************************************************************************/
- (void) _make:(NSObject *)target call:(SEL)action with:(NSObject *)arg
	{
	IMP imp = [target methodForSelector:action];
	void (*func)(id, SEL, id) = (void *)imp;
	func(target, action, arg);
	}

/*****************************************************************************\
|* Set the identifier on an object, or complain
\*****************************************************************************/
- (BOOL) _setIdentifierOn:(NSObject *)obj
				     from:(NSDictionary *)info
					   in:(NSString *)section
	{
	BOOL ok = YES;

	// Set the identifier for this object, crucial for any
	// connection-making later
	if (info[kZibIdentifier])
		_byId[info[kZibIdentifier]] = obj;
	else
		{
		// Complain
		SDL_Log("No identifier set in the ZIB block for %s:",
				section.UTF8String);
		ok = NO;
		}

	return ok;
	}

@end
