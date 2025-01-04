//
//  AZZibber.m
//  Azoth
//
//  Created by Simon Gornall on 1/3/25.
//

#import "AZTypes.h"
#import "AZZibber.h"

@interface AZZibber()

// The input dictionary from the XIB file
@property(strong, nonatomic) NSDictionary<NSString *, id> *			info;

// The output dictionary, to save as the ZIB
@property(strong, nonatomic) NSMutableDictionary<NSString *, id> *	zib;
@end


@implementation AZZibber
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
+ (AZZibber *) zibberWithDictionary:(NSDictionary *)info
	{
	return [[AZZibber alloc] initWithDictionary:info];
	}

- (instancetype) initWithDictionary:(NSDictionary *)info
	{
	if (self = [super init])
		{
		_info = info;
		_zib  = [NSMutableDictionary new];
		}
	return self;
	}

/*****************************************************************************\
|* Run through the XIB, creating the ZIB
\*****************************************************************************/
- (void) process
	{
	[self _createPreferences];
	[self _createFilesOwner];
	[self _createOtherCustomObjects];
	[self _createWindow];
	[self _createCustomViews];
	}

/*****************************************************************************\
|* Save the ZIB
\*****************************************************************************/
- (void) save:(NSString *)path
	{
	if (![path hasSuffix:@".zib"])
		path = [NSString stringWithFormat:@"%@.zib", path];

	NSKeyedArchiver *coder 	= nil;

	coder = [[NSKeyedArchiver alloc] initRequiringSecureCoding:NO];
	[coder encodeObject:_zib forKey:@"graph"];
	[coder finishEncoding];

	NSData *toSave = coder.encodedData;

	if (![toSave writeToFile:path atomically:NO])
		NSLog(@"Failed to save to '%@'", path);
	}

/*****************************************************************************\
|* Write to stdout
\*****************************************************************************/
- (void) dump
	{
	printf("%s\n", _zib.description.UTF8String);
	}

// MARK: Private methods


/*****************************************************************************\
|* Create the top-level window and recursively manage its views
\*****************************************************************************/
- (void) _createWindow
	{
	NSMutableDictionary *window = [NSMutableDictionary new];
	NSDictionary *win = [_info valueForKeyPath:@"document.objects.window"];
	if (win == nil)
		{
		NSLog(@"Can't find the main window");
		return;
		}

	[self _xfer:@"id" in:win as: @"id" in:window];
	[self _xfer:@"title" in:win as: @"title" in:window];
	[self _xfer:@"connections" in:win as:@"connect" in:window];
	[self _xfer:@"windowStyleMask" in:win as:@"style" in:window];

	// Find the content rect
	NSArray *rects = win[@"rect"];
	if (rects)
		for (NSDictionary *rect in rects)
			{
			if ([rect[@"key"] isEqualToString:@"contentRect"])
				{
				window[@"rect"] = rect;
				break;
				}
			}

	// Find the content view
	NSDictionary *view = win[@"view"];
	if (view)
		{
		NSDictionary *viewInfo = [self _createView:view withKey:@"view"];
		if (viewInfo.count > 0)
			window[@"view"] = viewInfo;
		}


	if (window.count > 0)
		_zib[@"window"] = window;
	}


/*****************************************************************************\
|* Determine a class-type from a dictionary key. CustomClass should always
|* override though
\*****************************************************************************/
- (NSString *)_classFromKey:(NSString *)key
	{
	static NSDictionary *map = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,
		^{
		map = @{
			@"customView" 	: @"AZView",
			@"view" 		: @"AZView",
			@"button"		: @"AZButton"
			};
		});

	NSString *result = nil;
	if (key)
		{
		result = map[key];
		if (result == nil)
			{
			NSLog(@"Warning: cannot find class for key '%@'", key);
			result = @"AZView";
			}
		}
	else
		result = @"AZView";
	return result;
	}

/*****************************************************************************\
|* Determine a class-type from a Cocoa class type. We allow-list the common
|* things (basically anything in Foundation), but we want NS -> AZ in general
|* for anything else
\*****************************************************************************/
- (NSString *)_toAZ:(NSString *)name
	{
	Class nsClass = NSClassFromString(name);
	if (nsClass)
		{
		NSBundle *bundle = [NSBundle bundleForClass:nsClass];
		if ([bundle.bundleIdentifier isEqualToString:@"com.apple.Foundation"])
			return name;
		}
	if ([name hasPrefix:@"NS"])
		return [NSString stringWithFormat:@"AZ%@", [name substringFromIndex:2]];

	return name;
	}

/*****************************************************************************\
|* Handle any other custom objects
\*****************************************************************************/
- (void) _createCustomViews
	{
	NSMutableArray *views = [NSMutableArray new];

	NSArray *list = nil;
	id element	  = [_info valueForKeyPath:@"document.objects.customView"];
	if (![element isKindOfClass:NSArray.class])
		list = @[element];
	else
		list = element;

	for (NSDictionary *obj in list)
		[views addObject:[self _createView:obj withKey:nil]];

	if (views.count > 0)
		_zib[@"view"] = views;
	}


/*****************************************************************************\
|* Recursively create a view hierarchy
\*****************************************************************************/
- (NSMutableDictionary *) _createView:(NSDictionary *)vi withKey:(NSString *)key
	{
	static NSDictionary *map = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,
		^{
		map = 	@{
				@"button"	: @"_handleButtonWithInfo:for:"
				};
		});

	NSMutableDictionary *view = [NSMutableDictionary new];

	[self _xfer:@"autoresizingMask" in:vi as:@"resizeMask" in:view];
	[self _xfer:@"id" in:vi as:@"id" in:view];
	[self _xfer:@"key" in:vi as:@"key" in:view];
	[self _xfer:@"rect" in:vi as:@"rect" in:view];
	[self _xfer:@"userLabel" in:vi as:@"label" in:view];

	// view-specific method calls
	if (key && (map[key] != nil))
		{
		SEL action = SELECTOR(map[key]);
		IMP imp = [self methodForSelector:action];
		void (*func)(id, SEL, NSDictionary*, NSMutableDictionary*) = (void *)imp;
		func(self, action, vi, view);
		}

	// Override the default class if we have a customClass set
	NSString *class = vi[@"customClass"];
	if (class == nil)
		class = [self _classFromKey:key];
	view[@"class"] = class;

	// Add connections if we have them
	[self _xfer:@"connections" in:vi as:@"connect" in:view];


	// Recursively handle subviews
	NSMutableArray *subviews = NSMutableArray.new;
	NSDictionary *sv = vi[@"subviews"];
	if (sv.count)
		{
		NSArray *allKeys = sv.allKeys;
		for (NSString *key in allKeys)
			{
			NSArray *viewList = nil;
			if (![sv[key] isKindOfClass:NSArray.class])
				viewList = @[sv[key]];
			else
				viewList = sv[key];

			for (NSDictionary *subview in viewList)
				[subviews addObject:[self _createView:subview withKey:key]];
			}
		}

	if (subviews.count)
		view[@"subviews"] = subviews;

	return view;
	}

/*****************************************************************************\
|* Called when this is a button-class. God dynamic dispatch is awesome.
\*****************************************************************************/
- (void) _handleButtonWithInfo:(NSDictionary *)vi for:(NSMutableDictionary *)view
	{
	NSDictionary *cellInfo = vi[@"buttonCell"];
	[self _xfer:@"alignment" in:cellInfo as:@"align" in:view];
	[self _xfer:@"bezelStyle" in:cellInfo as:@"bezel" in:view];
	[self _xfer:@"imageScaling" in:cellInfo as:@"scaling" in:view];
	[self _xfer:@"title" in:cellInfo as:@"title" in:view];
	[self _xfer:@"type" in:cellInfo as:@"type" in:view];
	}

/*****************************************************************************\
|* Handle the file's owner object
\*****************************************************************************/
- (void) _createFilesOwner
	{
	NSMutableDictionary *owner = [NSMutableDictionary new];

	NSArray *custom = [_info valueForKeyPath:@"document.objects.customObject"];
	for (NSDictionary *obj in custom)
		{
		NSString *label = obj[@"userLabel"];
		if ([label isEqualToString:@"File's Owner"])
			{
			[self _xferClass:@"customClass" in:obj to:owner];
			[self _xfer:@"id" in:obj as: @"id" in:owner];
			[self _xfer:@"connections" in:obj as:@"connect" in:owner];
			break;
			}
		}

	if (owner.count == 0)
		NSLog(@"Failed to find 'File's Owner'");
	else
		_zib[@"owner"] = owner;
	}

/*****************************************************************************\
|* Handle any other custom objects
\*****************************************************************************/
- (void) _createOtherCustomObjects
	{
	NSMutableArray *objects = [NSMutableArray new];

	NSArray *custom = [_info valueForKeyPath:@"document.objects.customObject"];
	for (NSDictionary *obj in custom)
		{
		// Rule out the cases we're not interested in
		BOOL use = YES;
		NSString *label = obj[@"userLabel"];
		if ([label isEqualToString:@"File's Owner"])
			use = NO;

		NSString *idVal = obj[@"id"];
		if ([idVal hasPrefix:@"-"])
			use = NO;

		NSString *class = obj[@"customClass"];
		if ([class isEqualToString:@"NSFontManager"])
			use = NO;

		// All the rest, we are
		if (use)
			{
			NSMutableDictionary *customObj = [NSMutableDictionary new];
			[self _xferClass:@"customClass" in:obj to:customObj];
			[self _xfer:@"id" in:obj as:@"id" in:customObj];
			[self _xfer:@"connections" in:obj as:@"connect" in:customObj];
			[objects addObject:customObj];
			}
		}

	if (objects.count > 0)
		_zib[@"objects"] = objects;
	}


/*****************************************************************************\
|* Handle any global preferences
\*****************************************************************************/
- (void) _createPreferences
	{
	NSMutableDictionary *prefs = [NSMutableDictionary new];

	// Xcode tools version
	[self _xfer:@"document.toolsVersion" as:@"xcodeVersion" in:prefs];

	// XIB version
	[self _xfer:@"document.version" as:@"xibVersion" in:prefs];

	// Autolayout flags
	[self _xfer:@"document.useAutolayout" as:@"autoLayout" in:prefs];

	// Creation date
	prefs[@"creationDate"] = NSDate.date;

	// Install them all
	_zib[@"document"] = prefs;
	}

/*****************************************************************************\
|* Fetch and set
\*****************************************************************************/
- (BOOL) _xfer:(NSString *)path as:(NSString *)name in:(NSDictionary *)dst
	{
	return [self _xfer:path in:_info as:name in:dst];
	}

- (BOOL) _xfer:(NSString *)path in:(NSDictionary *)src
			as:(NSString *)name in:(NSDictionary *)dst
	{
	BOOL found = NO;
	NSObject *obj = [src valueForKeyPath:path];
	if (obj)
		{
		[dst setValue:obj forKey:name];
		found = YES;
		}
	return found;
	}

- (BOOL) _xferClass:(NSString *)path in:(NSDictionary *)src
			     to:(NSDictionary *)dst
	{
	BOOL found = NO;
	NSString *obj = [src valueForKeyPath:path];
	if (obj)
		{
		[dst setValue:[self _toAZ:obj] forKey:@"class"];
		found = YES;
		}
	return found;
	}

@end
