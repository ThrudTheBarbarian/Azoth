//
//  AZZib.m
//  Azoth
//
//  Created by Simon Gornall on 1/3/25.
//

#import <SDL3/SDL.h>

#import "AZApplication.h"
#import "AZButton.h"
#import "AZClipView.h"
#import "AZControl.h"
#import "AZRenderer.h"
#import "AZScrollView.h"
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
NSString * const kZibOutlet	  		= @"outlet";
NSString * const kZibAction	  		= @"action";
NSString * const kZibDestination	= @"destination";
NSString * const kZibId				= @"id";
NSString * const kZibProperty		= @"property";
NSString * const kZibSelector		= @"selector";
NSString * const kZibTarget			= @"target";
NSString * const kZibPullsDown		= @"pullsDown";
NSString * const kZibSelect			= @"select";
NSString * const kZibSegments		= @"segments";
NSString * const kZibLabel			= @"label";
NSString * const kZibWidth			= @"width";
NSString * const kZibValue			= @"value";
NSString * const kZibMinValue		= @"minValue";
NSString * const kZibMaxValue		= @"maxValue";
NSString * const kZibCircular		= @"circular";
NSString * const kZibTextColour		= @"textColour";
NSString * const kZibEditable		= @"editable";
NSString * const kZibRound			= @"round";
NSString * const kZibHLineScroll	= @"dhLine";
NSString * const kZibHPageScroll	= @"dhPage";
NSString * const kZibVLineScroll	= @"dvLine";
NSString * const kZibVPageScroll	= @"dvPage";
NSString * const kZibHScroller		= @"hscroller";
NSString * const kZibVScroller		= @"vscroller";


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
				SDL_Log("ZIB: Failed to decode ZIB. %s",
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
			SDL_Log("ZIB: Failed to open ZIB file '%s'", path.UTF8String);
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
	BOOL ok = NO;
	if (owner)
		{
		ok  = [self _inflateObjects];
		ok &= [self _inflateOwner:owner];
		ok &= [self _inflateWindow];
		ok &= [self _inflateViews];
		ok &= [self _connect];

		ok &= [self _connect:owner];
		}

	return ok;
	}


// MARK: Private methods

/*****************************************************************************\
|* Make any connections between the items in the lists we hold
\*****************************************************************************/
- (BOOL) _connect
	{
	BOOL ok = YES;

	for (NSObject *item in _inflated)
		ok &= [self _connect:item];

	return ok;
	}

/*****************************************************************************\
|* Make any connections between the items in the lists we hold
\*****************************************************************************/
- (BOOL) _connect:(NSObject *)item
	{
	BOOL ok = YES;

	NSDictionary *conns = _connect[TO_KEY(item)];
	if (conns)
		{
		/*********************************************************************\
		|* Cope with there being one or multiple outlet connections to make
		\*********************************************************************/
		NSArray *list = nil;
		id element    = conns[kZibOutlet];
		if (element)
			{
			if (![element isKindOfClass:NSArray.class])
				list = @[element];
			else
				list = element;

			/*****************************************************************\
			|* Connect each outlet
			\*****************************************************************/
			for (NSDictionary *cInfo in list)
				{
				NSString *value 	= cInfo[kZibDestination];
				NSString *property	= cInfo[kZibProperty];
				if (value && property)
					{
					NSObject *obj 	= _byId[value];
					[item setValue:obj forKey:property];
					}
				else
					SDL_Log("ZIB: property %s (value %s) could not be set on %s",
							property.UTF8String,
							value.UTF8String,
							item.description.UTF8String);
				}
			}

		/*********************************************************************\
		|* Cope with there being one or multiple action connections to make
		\*********************************************************************/
		list = nil;
		element    = conns[kZibAction];
		if (element && [item isKindOfClass:AZResponder.class])
			{
			AZControl *control = (AZControl *)item;

			if (![element isKindOfClass:NSArray.class])
				list = @[element];
			else
				list = element;

			/*****************************************************************\
			|* Connect each action
			\*****************************************************************/
			for (NSDictionary *cInfo in list)
				{
				NSString *selectorId	= cInfo[kZibSelector];
				NSString *targetId 		= cInfo[kZibTarget];

				if (selectorId && targetId)
					{
					NSObject *target = _byId[targetId];
					if (target)
						{
						SEL action = NSSelectorFromString(selectorId);
						[control setAction:action];
						[control setTarget:target];
						}
					else
						SDL_Log("ZIB: Selector %s, target %s cannot link to %s",
								selectorId.UTF8String,
								targetId.UTF8String,
								item.class.description.UTF8String);
					}
				}
			}
		}

	return ok;
	}


/*****************************************************************************\
|* Inflate the Window, checking the class
\*****************************************************************************/
- (BOOL) _inflateViews
	{
	BOOL ok			= YES;
	id info	 		= _zib[kZibView];

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

		/********************************************************************\
		|* If we have any connections, store them for later
		\********************************************************************/
		if (view && viewInfo[kZibConnect])
			_connect[TO_KEY(view)] = info[kZibConnect];
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
		SDL_Log("ZIB: Cannot find window table within ZIB %s", _path.UTF8String);
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

	/*************************************************************************\
	|* If we have any connections, store them for later
	\*************************************************************************/
	if (window)
		{
		NSDictionary *connections = info[kZibConnect];
		if (connections)
			_connect[TO_KEY(window)] = connections;
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
		SDL_Log("ZIB:  Cannot find view of class '%s'", className.UTF8String);
		class = NSClassFromString(@"AZView");
		}

	/*************************************************************************\
	|* Create an instance of the class and get the ball rolling with view
	|* instantiation if this is the contentView of the window
	\*************************************************************************/
	if ([class instancesRespondToSelector:@selector(initWithDictionary:)])
		view = [[class alloc] initWithDictionary:info];
	else
		SDL_Log("ZIB: class %s does not implement -initWithDictionary!",
				className.UTF8String);
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
			|* Add the view to its parent if it's not the root view, but take
			|* account of some special cases...
			|*
			|*  o If the parent view is an AZClipView, we want to call into
			|*    -setDocumentView: instead, so the listeners are set correctly
			|*    (Note: -setDocumentView will internally call -addSubview)
			|*
			|*  o If the parent view is an AZScrollView, we want to call
			|*    -setContentView: instead, so tiling etc. is all set up
			\*****************************************************************/
			BOOL parentIsSV = [parentView isKindOfClass:AZScrollView.class];
			BOOL parentIsCV = [parentView isKindOfClass:AZClipView.class];
			BOOL viewIsCV   = [view isKindOfClass:AZClipView.class];

			if (parentIsSV & viewIsCV)
				[(AZScrollView *)parentView setContentView:(AZClipView *)view];
			else if (parentIsSV)
				SDL_Log("Must set contentView as AZClipView in AZScrollView");
			else if (parentIsCV)
				[(AZClipView *)parentView setDocumentView:view];
			else
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
		|* If we have any connections, add them to the connect table
		\*********************************************************************/
		NSDictionary *connections = info[kZibConnect];
		if (connections)
			_connect[TO_KEY(view)] = connections;

		/*********************************************************************\
		|* And for each subview, do the same thing
		\*********************************************************************/
		NSArray *subviews = info[kZibSubviews];
		for (NSDictionary *subview in subviews)
			[self _createViewFrom:subview forWindow:window inView:view];
		}
	else
		SDL_Log("ZIB: Cannot create view of type %s", className.UTF8String);

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
		SDL_Log("ZIB: Cannot find owner table within ZIB %s", _path.UTF8String);
		ok = NO;
		}

	/*************************************************************************\
	|* And a designated owner-class within that table...
	\*************************************************************************/
	else if (ownerClass == nil)
		{
		SDL_Log("ZIB: Cannot find owner-class within ZIB %s", _path.UTF8String);
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
			SDL_Log("ZIB: Owner class (%s) mismatch with ZIB's owner class (%s)",
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
		SDL_Log("ZIB: Cannot find objects table within ZIB %s", _path.UTF8String);
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

			// Set the identifier for this object, crucial for any
			// connection-making later
			ok = [self _setIdentifierOn:obj from:object in:@"objects"];

			// Add the object to the list of inflated instances
			if (ok)
				{
				[_inflated addObject:obj];

				// Store any connection info we need to
				NSDictionary *connections = object[kZibConnect];
				if (connections)
					_connect[TO_KEY(obj)] = connections;
				}
			}
		else
			{
			SDL_Log("ZIB: Cannot create concrete instance of class %s",
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
		SDL_Log("ZIB: No identifier set in the ZIB block for %s:",
				section.UTF8String);
		ok = NO;
		}

	return ok;
	}

@end
