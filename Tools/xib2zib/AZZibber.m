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
		NSDictionary *viewInfo = [self _createView:view withKey:@"contentView"];
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
			@"contentView" 			: @"AZWindowContentView",
			@"customView" 			: @"AZView",
			@"view" 				: @"AZView",
			@"button"				: @"AZButton",
			@"popUpButton"			: @"AZPopupButton",
			@"segmentedControl"		: @"AZSegmentedControl",
			@"slider"				: @"AZSlider",
			@"textField"			: @"AZTextField",
			@"scrollView"			: @"AZScrollView",
			@"clipView"				: @"AZClipView",
			@"tableView"			: @"AZTableView",
			@"outlineView"			: @"AZOutlineView",
			@"splitView"			: @"AZSplitView",
			@"collectionView"		: @"AZCollectionView"
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
	if (element)
		{
		if (![element isKindOfClass:NSArray.class])
			list = @[element];
		else
			list = element;

		for (NSDictionary *obj in list)
			[views addObject:[self _createView:obj withKey:nil]];
		}
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
				@"button"			: @"_handleButtonWithInfo:for:",
				@"popUpButton"		: @"_handlePopUpButtonWithInfo:for:",
				@"segmentedControl"	: @"_handleSegmentedControlWithInfo:for:",
				@"slider"			: @"_handleSliderWithInfo:for:",
				@"textField"		: @"_handleTextFieldWithInfo:for:",
				@"scrollView"		: @"_handleScrollViewWithInfo:for:",
				@"tableView"		: @"_handleTableViewWithInfo:for:",
				@"outlineView"		: @"_handleOutlineViewWithInfo:for:",
				@"splitView"		: @"_handleSplitViewWithInfo:for:"
				};
		});

	NSMutableDictionary *view = [NSMutableDictionary new];

	[self _xfer:@"autoresizingMask" in:vi as:@"resizeMask" in:view];
	[self _xfer:@"id" in:vi as:@"id" in:view];
	[self _xfer:@"key" in:vi as:@"key" in:view];
	[self _xfer:@"rect" in:vi as:@"rect" in:view];
	[self _xfer:@"userLabel" in:vi as:@"label" in:view];

	// Override the default class if we have a customClass set
	NSString *class = vi[@"customClass"];
	if (class == nil)
		class = [self _classFromKey:key];
	view[@"class"] = class;

	// view-specific method calls
	if (key && (map[key] != nil))
		{
		SEL action = SELECTOR(map[key]);
		IMP imp = [self methodForSelector:action];
		void (*func)(id, SEL, NSDictionary*, NSMutableDictionary*) = (void *)imp;
		func(self, action, vi, view);
		}

	// Add connections if we have them
	[self _xfer:@"connections" in:vi as:@"connect" in:view];


	// Recursively handle clipView
	NSDictionary *clip = vi[@"clipView"];
	if (clip)
		{
		clip = [self _createView:clip withKey:@"clipView"];
		view[@"subviews"] = @[clip];
		}

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
|* Called when this is a textfield-class. $deity, dynamic-dispatch is awesome.
\*****************************************************************************/
- (void) _handleTextFieldWithInfo:(NSDictionary *)vi
							  for:(NSMutableDictionary *)view
	{
	NSDictionary *cellInfo = vi[@"textFieldCell"];
	[self _xfer:@"editable" in:cellInfo as:@"editable" in:view];
	[self _xfer:@"selectable" in:cellInfo as:@"selectable" in:view];
	[self _xfer:@"drawsBackground" in:cellInfo as:@"drawsBackground" in:view];
	[self _xfer:@"title" in:cellInfo as:@"title" in:view];
	[self _xfer:@"sendsActionOnEndEditing" in:cellInfo
			 as:@"sendsActionOnEndEditing" in:view];

	NSArray *colours = nil;
	id element = cellInfo[@"color"];
	if (element != nil)
		{
		if ([element isKindOfClass:NSArray.class])
			colours = element;
		else
			colours = @[element];

		for (NSDictionary *colour in colours)
			{
			NSString *key = colour[@"key"];
			if ([key isEqualToString:@"textColor"])
				view[@"textColour"] = colour[@"name"];
			else if ([key isEqualToString:@"backgroundColor"])
				view[@"background"] = colour[@"name"];
			}
		}

	NSString *border = cellInfo[@"borderStyle"];
	if (border == nil)
		view[@"class"] = @"AZLabel"; // Override the existing class
	else
		{
		NSString *bezel = cellInfo[@"bezelStyle"];
		if ([bezel isEqualToString:@"round"])
			view[@"type"] = @"round";
		else
			view[@"type"] = @"square";
		}
	}

/*****************************************************************************\
|* Called when this is a outlineview-class.
\*****************************************************************************/
- (void) _handleOutlineViewWithInfo:(NSDictionary *)vi
								for:(NSMutableDictionary *)view
	{
	[self _handleTableViewWithInfo:vi for:view];
	[self _xfer:@"indentationPerLevel" in:vi as:@"indent" in:view];
	}

/*****************************************************************************\
|* Called when this is a splitview-class.
\*****************************************************************************/
- (void) _handleSplitViewWithInfo:(NSDictionary *)vi
							  for:(NSMutableDictionary *)view
	{
	[self _xfer:@"dividerStyle" in:vi as:@"style" in:view];
	if (vi[@"vertical"])
		view[@"vertical"] = @"YES";
	}

/*****************************************************************************\
|* Called when this is a table-class.
\*****************************************************************************/
- (void) _handleTableViewWithInfo:(NSDictionary *)vi
							  for:(NSMutableDictionary *)view
	{
	[self _xfer:@"rowHeight" in:vi as:@"rowHeight" in:view];
	[self _xfer:@"multipleSelection" in:vi as:@"multipleSelection" in:view];

	NSArray *colours = nil;
		id element = vi[@"color"];
	if (element != nil)
		{
		if ([element isKindOfClass:NSArray.class])
			colours = element;
		else
			colours = @[element];

		for (NSDictionary *colour in colours)
			{
			NSString *key = colour[@"key"];
			if ([key isEqualToString:@"gridColor"])
				view[@"gridColor"] = colour[@"name"];
			else if ([key isEqualToString:@"backgroundColor"])
				view[@"background"] = colour[@"name"];
			}
		}

	element = vi[@"headerView"];
	view[@"hasHeaderView"] = (element != nil) ? @"YES" : @"NO";

	NSArray *list = nil;
	element = [vi valueForKeyPath:@"tableColumns.tableColumn"];
	if ([element isKindOfClass:NSArray.class])
		list = element;
	else
		list = @[element];

	NSMutableArray *columns = [NSMutableArray new];
	for (NSDictionary *column in list)
		{
		NSDictionary *col = [NSMutableDictionary new];

		[self _xfer:@"id" in:column as:@"id" in:col];
		[self _xfer:@"identifier" in:column as:@"identifier" in:col];
		[self _xfer:@"maxWidth" in:column as:@"maxWidth" in:col];
		[self _xfer:@"minWidth" in:column as:@"minWidth" in:col];
		[self _xfer:@"width" in:column as:@"width" in:col];

		[columns addObject:col];
		}

	if (columns.count)
		view[@"columns"] = columns;
	}

/*****************************************************************************\
|* Called when this is a scrollview.
\*****************************************************************************/
- (void) _handleScrollViewWithInfo:(NSDictionary *)vi
							  for:(NSMutableDictionary *)view
	{
	// Only show up if set to NO
	NSString *hscroll = vi[@"hasHorizontalScroller"];
	view[@"hscroller"] = hscroll ? @"NO" : @"YES";

	NSString *vscroll = vi[@"hasVerticalScroller"];
	view[@"vscroller"] = vscroll ? @"NO" : @"YES";

	[self _xfer:@"horizontalLineScroll" in:vi as:@"dhLine" in:view];
	[self _xfer:@"horizontalPageScroll" in:vi as:@"dhPage" in:view];
	[self _xfer:@"verticalLineScroll" in:vi   as:@"dvLine" in:view];
	[self _xfer:@"verticalPageScroll" in:vi   as:@"dvPage" in:view];
	}

/*****************************************************************************\
|* Called when this is a slider-class.
\*****************************************************************************/
- (void) _handleSliderWithInfo:(NSDictionary *)vi
						   for:(NSMutableDictionary *)view
	{
	NSDictionary *cellInfo = vi[@"sliderCell"];
	[self _xfer:@"alignment" in:cellInfo as:@"align" in:view];
	[self _xfer:@"doubleValue" in:cellInfo as:@"value" in:view];
	[self _xfer:@"maxValue" in:cellInfo as:@"maxValue" in:view];
	[self _xfer:@"minValue" in:cellInfo as:@"minValue" in:view];
	[self _xfer:@"sliderType" in:cellInfo as:@"type" in:view];
	}

/*****************************************************************************\
|* Called when this is a button-class.
\*****************************************************************************/
- (void) _handleButtonWithInfo:(NSDictionary *)vi for:(NSMutableDictionary *)view
	{
	NSDictionary *cellInfo = vi[@"buttonCell"];
	[self _xfer:@"alignment" in:cellInfo as:@"align" in:view];
	[self _xfer:@"bezelStyle" in:cellInfo as:@"bezel" in:view];
	[self _xfer:@"imageScaling" in:cellInfo as:@"scaling" in:view];
	[self _xfer:@"title" in:cellInfo as:@"title" in:view];
	[self _xfer:@"type" in:cellInfo as:@"type" in:view];
	[self _xfer:@"state" in:cellInfo as:@"state" in:view];
	}

/*****************************************************************************\
|* Called when this is a pop-up-button-class.
\*****************************************************************************/
- (void) _handlePopUpButtonWithInfo:(NSDictionary *)vi
								for:(NSMutableDictionary *)view
	{
	NSDictionary *cellInfo = vi[@"popUpButtonCell"];
	[self _xfer:@"alignment" in:cellInfo as:@"align" in:view];
	[self _xfer:@"bezelStyle" in:cellInfo as:@"bezel" in:view];
	[self _xfer:@"imageScaling" in:cellInfo as:@"scaling" in:view];
	[self _xfer:@"title" in:cellInfo as:@"title" in:view];
	[self _xfer:@"type" in:cellInfo as:@"type" in:view];
	[self _xfer:@"menu" in:cellInfo as:@"menu" in:view];
	[self _xfer:@"selectedItem" in:cellInfo as:@"select" in:view];
	[self _xfer:@"pullsDown" in:cellInfo as:@"pullsDown" in:view];
	}

/*****************************************************************************\
|* Called when this is a pop-up-button-class.
\*****************************************************************************/
- (void) _handleSegmentedControlWithInfo:(NSDictionary *)vi
									 for:(NSMutableDictionary *)view
	{
	NSDictionary *cellInfo = vi[@"segmentedCell"];
	[self _xfer:@"alignment" in:cellInfo as:@"align" in:view];
	[self _xfer:@"menu" in:cellInfo as:@"menu" in:view];
	[self _xfer:@"segments.segment" in:cellInfo as:@"segments" in:view];
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
