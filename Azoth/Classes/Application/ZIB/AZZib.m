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

/*****************************************************************************\
|* Constant strings, only really used here, but...
\*****************************************************************************/
static NSString * const kObjects		= @"objects";
static NSString * const kClassname		= @"class";
static NSString * const kConnect		= @"connect";
static NSString * const kIdentifier		= @"id";
static NSString * const kOwner			= @"owner";
static NSString * const kWindow			= @"window";
static NSString * const kContentRect	= @"contentRect";
static NSString * const kRect			= @"rect";
static NSString * const kKey			= @"key";
static NSString * const kX				= @"x";
static NSString * const kY				= @"y";
static NSString * const kW				= @"width";
static NSString * const kH				= @"height";
static NSString * const kStyle			= @"style";
static NSString * const kClosable		= @"closable";
static NSString * const kTitle			= @"title";
static NSString * const kView			= @"view";
static NSString * const kFrame			= @"frame";
static NSString * const kResizeMask		= @"resizeMask";
static NSString * const kFlexibleMaxX	= @"flexibleMaxX";
static NSString * const kFlexibleMaxY	= @"flexibleMaxY";
static NSString * const kFlexibleMinX	= @"flexibleMinX";
static NSString * const kFlexibleMinY	= @"flexibleMinY";
static NSString * const kHeightSizable  = @"heightSizable";
static NSString * const kWidthSizable  	= @"widthSizable";
static NSString * const kSubviews  		= @"subviews";
static NSString * const kType	  		= @"type";


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
	BOOL ok = [self _inflateObjects];
	ok &= [self _inflateOwner:owner];
	ok &= [self _inflateWindow];
	return ok;
	}


// MARK: Private methods

/*****************************************************************************\
|* Inflate the Window, checking the class
\*****************************************************************************/
- (BOOL) _inflateWindow
	{
	BOOL ok					= YES;
	NSDictionary *info	 	= _zib[kWindow];
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
		frame = [self _fetchRectFrom:info matching:kContentRect];
		if (NSIsEmptyRect(frame))
			ok = NO;
		}

	/*************************************************************************\
	|* Determine the style mask
	\*************************************************************************/
	if (ok && info[kStyle])
		{
		NSDictionary *style = info[kStyle];
		if ([style[kClosable] isEqualToString:@"YES"])
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
		if (info[kTitle])
			window.title = info[kTitle];

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
	|* Now create the content-view
	\*************************************************************************/
	if (window)
		{
		NSDictionary *viewInfo = info[kView];
		if (viewInfo)
			{
			[self _createViewFrom:viewInfo forWindow:window inView:nil];
			}
		}

	return ok;
	}

/*****************************************************************************\
|* Create a view
\*****************************************************************************/
- (nullable AZView *) _createViewFrom:(NSDictionary *)info
							forWindow:(AZWindow *)window
							   inView:(nullable AZView *)parentView
	{
	static NSDictionary *map = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,
		^{
		map = 	@{
				@"AZButton"	: @"_handleButton:withInfo:"
				};
		});



	AZView *view 		= nil;
	NSString *className = info[kClassname];

	/*************************************************************************\
	|* Find the content-rect
	\*************************************************************************/
	NSRect frame = [self _fetchRectFrom:info matching:kFrame];
	if (NSIsEmptyRect(frame))
		{
		SDL_Log("Cannot find frame rect for '%s'", className.UTF8String);
		return nil;
		}

	/*************************************************************************\
	|* Cocoa measures Y upwards, and SDL measures it downwards, so
	\*************************************************************************/
	if (parentView)
		frame.origin.y = NSHeight(parentView.frame) - NSMaxY(frame);

	/*************************************************************************\
	|* Find the class. Default to a standard view if we can't find the class
	\*************************************************************************/
	Class class = NSClassFromString(className);
	if (class == Nil)
		{
		SDL_Log("Warning: Cannot create view of class '%s'", className.UTF8String);
		class = NSClassFromString(@"AZView");
		}

	/*************************************************************************\
	|* Initialise the autoresize mask
	\*************************************************************************/
	int resizeMask = AZViewNotSizable;

	/*************************************************************************\
	|* Create an instance of the class and get the ball rolling with view
	|* instantiation if this is the contentView of the window
	\*************************************************************************/
	view = [[class alloc] initWithFrame:frame];
	if (view)
		{
		if (parentView == nil)
			{
			resizeMask = AZViewWidthSizable | AZViewHeightSizable;
			[window installContentView:view];
			}
		else
			{
			NSDictionary *resize = info[kResizeMask];
			if ([resize[kFlexibleMinX] isEqualToString:@"YES"])
				resizeMask |= AZViewMinXMargin;
			if ([resize[kWidthSizable] isEqualToString:@"YES"])
				resizeMask |= AZViewWidthSizable;
			if ([resize[kFlexibleMaxX] isEqualToString:@"YES"])
				resizeMask |= AZViewMaxXMargin;
			if ([resize[kFlexibleMinY] isEqualToString:@"YES"])
				resizeMask |= AZViewMinYMargin;
			if ([resize[kHeightSizable] isEqualToString:@"YES"])
				resizeMask |= AZViewHeightSizable;
			if ([resize[kFlexibleMaxY] isEqualToString:@"YES"])
				resizeMask |= AZViewMaxYMargin;

			/*****************************************************************\
			|* Add the view to its parent, if it's not the root view
			\*****************************************************************/
			[parentView addSubview:view];
			}

		/*********************************************************************\
		|* Install the autoresize mask
		\*********************************************************************/
		view.autoresizingMask = resizeMask;

		/*********************************************************************\
		|* view-class-specific method calls
		\*********************************************************************/
		if (map[className] != nil)
			{
			SEL action = SELECTOR(map[className]);
			IMP imp = [self methodForSelector:action];
			void (*func)(id, SEL, AZView *, NSDictionary*) = (void *)imp;
			func(self, action, view, info);
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
		NSArray *subviews = info[kSubviews];
		for (NSDictionary *subview in subviews)
			[self _createViewFrom:subview forWindow:window inView:view];
		}

	return view;
	}

/*****************************************************************************\
|* Button-specific view-handling
\*****************************************************************************/
- (void) _handleButton:(AZButton *)button withInfo:(NSDictionary *)info
	{
	NSString *title = info[kTitle];
	if (title)
		button.stringValue = title;

	if ([info[kType] isEqualToString:@"roundRect"])
		button.type = ButtonTypeRounded;
	}

/*****************************************************************************\
|* Fetch a matching rectangle from the info dictionary
\*****************************************************************************/
- (NSRect) _fetchRectFrom:(NSDictionary *)info matching:(NSString *)key
	{
	NSArray *rectList = nil;

	if (![info[kRect] isKindOfClass:NSArray.class])
		rectList = @[info[kRect]];
	else
		rectList = info[kRect];

	for (NSDictionary *rect in rectList)
		{
		if ([rect[kKey] isEqualToString:key])
			{
			float x = ((NSNumber *)rect[kX]).floatValue;
			float y = ((NSNumber *)rect[kY]).floatValue;
			float w = ((NSNumber *)rect[kW]).floatValue;
			float h = ((NSNumber *)rect[kH]).floatValue;

			return NSMakeRect(x,y,w,h);
			}
		}

	return NSZeroRect;
	}

/*****************************************************************************\
|* Inflate the Owner, checking the class
\*****************************************************************************/
- (BOOL) _inflateOwner:(NSObject *)owner
	{
	BOOL ok 				= YES;
	NSDictionary *info	 	= _zib[kOwner];
	NSString *ownerClass 	= info[kClassname];

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
		NSDictionary *connections = info[kConnect];
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
	if (_zib[kObjects] == nil)
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
		if (![_zib[kObjects] isKindOfClass:NSArray.class])
			objectList = @[_zib[kObjects]];
		else
			objectList = _zib[kObjects];
		}

	/*************************************************************************\
	|* For each object, expand it to a real thing and apply its properties
	\*************************************************************************/
	for (NSDictionary * object in objectList)
		{
		NSString *objectClass = object[kClassname];
		Class class			  = NSClassFromString(objectClass);
		if (class != Nil)
			{
			NSObject *obj = class.new;

			NSDictionary *connections = object[kConnect];
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
	if (info[kIdentifier])
		_byId[info[kIdentifier]] = obj;
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
