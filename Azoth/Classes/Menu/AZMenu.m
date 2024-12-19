//
//  AZMenu.m
//  Azoth
//
//  Created by Simon Gornall on 12/18/24.
//
#import <SDL3/SDL.h>

#import "AZApp.h"
#import "AZFont.h"
#import "AZMenu.h"
#import "AZMenuItem.h"
#import "AZMenuOverlayView.h"

#define MENU_HEIGHT 		25
#define MENU_LEADING   		12
#define MENU_TRAILING		12

@interface AZMenu()
@property(strong, nonatomic) NSMutableArray<AZMenuItem *> * 	items;
@property(strong, nonatomic) AZMenuOverlayView *				overlay;
@end

@implementation AZMenu
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
+ (AZMenu *) menuWithTitle:(NSString *)title
	{
	return [[AZMenu alloc] initWithTitle:title];
	}

- (instancetype) initWithTitle:(NSString *)title
	{
	AZApp *app 			= AZApp.sharedInstance;
	int width  			= [app.controlFont textWidthFor:title]
						+ MENU_LEADING + MENU_TRAILING;
	NSRect frame		= NSMakeRect(100, 100, width, MENU_HEIGHT);

	if (self = [super initWithFrame:frame])
		{
		_items = [NSMutableArray new];

		// Add the first item as the title of the menu. Menu choices are
		// 1-based to allow for a title at position-0
		AZMenuItem *titleItem = [AZMenuItem itemWithTitle:title
												   action:nil
											keyEquivalent:@""];
		[_items addObject:titleItem];
		}
	return self;
	}


// MARK: Adding items


/*****************************************************************************\
|* Insert a menu item at an index
\*****************************************************************************/
- (BOOL) insertItem:(AZMenuItem *)newItem atIndex:(NSInteger)index
	{
	BOOL ok = NO;
	if ((index >= 0) && (index < _items.count))
		{
		[_items insertObject:newItem atIndex:index];
		ok = YES;
		}
	return ok;
	}

/*****************************************************************************\
|* Creates and adds a menu item at a specified location in the menu
\*****************************************************************************/
- (AZMenuItem *) insertItemWithTitle:(NSString *)title
                              action:(SEL)selector
                       keyEquivalent:(NSString *)charCode
                             atIndex:(NSInteger)index
	{
	if ((index >= 0) && (index < _items.count))
		{
		AZMenuItem *item = [AZMenuItem itemWithTitle:title
											  action:selector
									   keyEquivalent:charCode];
		if ([self insertItem:item atIndex:index])
			return item;
		}
	return nil;
	}

/*****************************************************************************\
|* Adds a menu item to the end of the menu
\*****************************************************************************/
- (void) addItem:(AZMenuItem *)newItem
	{
	[_items addObject:newItem];
	}

/*****************************************************************************\
|* Creates a new menu item and adds it to the end of the menu
\*****************************************************************************/
- (AZMenuItem *) addItemWithTitle:(NSString *)title
                           action:(SEL)selector
                    keyEquivalent:(NSString *)charCode
	{
	AZMenuItem *item = [AZMenuItem itemWithTitle:title
										  action:selector
								   keyEquivalent:charCode];
	[self addItem:item];
	return item;
	}

/*****************************************************************************\
|* Removes a menu item from the menu
\*****************************************************************************/
- (void) removeItem:(AZMenuItem *) item
	{
	[_items removeObject:item];
	}

/*****************************************************************************\
|* Removes the menu item at a specified location in the menu
\*****************************************************************************/
- (BOOL) removeItemAtIndex:(NSInteger) index
	{
	BOOL ok = NO;
	if ((index >= 0) && (index < _items.count))
		{
		[_items removeObjectAtIndex:index];
		ok = YES;
		}
	return ok;
	}

/*****************************************************************************\
|* Removes all the menu items in the menu.
\*****************************************************************************/
- (void) removeAllItems
	{
	[_items removeAllObjects];
	}


// MARK: Finding items


/*****************************************************************************\
|* Returns the first menu item in the menu with the specified tag
\*****************************************************************************/
- (nullable AZMenuItem *) itemWithTag:(NSInteger) tag
	{
	for (AZMenuItem *item in _items)
		if (item.tag == tag)
			return item;
	return nil;
	}

/*****************************************************************************\
|* Returns the first menu item in the menu with a specified title
\*****************************************************************************/
- (nullable AZMenuItem *) itemWithTitle:(NSString *) title
	{
	for (AZMenuItem *item in _items)
		if ([item.title isEqualToString:title])
			return item;
	return nil;
	}

/*****************************************************************************\
|* Returns the menu item at a specific location of the menu
\*****************************************************************************/
- (nullable AZMenuItem *) itemAtIndex:(NSInteger) index
	{
	if ((index >= 0) && (index < _items.count))
		return [_items objectAtIndex:index];
	return nil;
	}

/*****************************************************************************\
|* Returns the index identifying the location of a specified menu item in the
|* menu, or -1 if it cannot be found
\*****************************************************************************/
- (NSInteger) indexOfItem:(AZMenuItem *) item
	{
	NSInteger index = 0;
	for (AZMenuItem *candidate in _items)
		{
		if (candidate == item)
			return index;
		index ++;
		}
	return -1;
	}

/*****************************************************************************\
|* Returns the index of the first menu item in the menu that has a specified
|* title, or -1 if it cannot be found
\*****************************************************************************/
- (NSInteger) indexOfItemWithTitle:(NSString *) title
	{
	NSInteger index = 0;
	for (AZMenuItem *candidate in _items)
		{
		if ([candidate.title isEqualToString:title])
			return index;
		index ++;
		}
	return -1;
	}

/*****************************************************************************\
|* Returns the index identifying the location of a specified menu item in the
|* menu, or -1 if it cannot be found
\*****************************************************************************/
- (NSInteger) indexOfItemWithTag:(NSInteger) tag
	{
	NSInteger index = 0;
	for (AZMenuItem *candidate in _items)
		{
		if (candidate.tag == tag)
			return index;
		index ++;
		}
	return -1;
	}

/*****************************************************************************\
|* Returns the index of the first menu item in the menu that has a given
|* represented object, or -1 if it cannot be found
\*****************************************************************************/
- (NSInteger) indexOfItemWithRepresentedObject:(NSObject *)object
	{
	NSInteger index = 0;
	for (AZMenuItem *candidate in _items)
		{
		if (candidate.representedObject == object)
			return index;
		index ++;
		}
	return -1;
	}

/*****************************************************************************\
|* Returns the index of the menu item in the menu with the given submenu,
|* or -1 if it cannot be found
\*****************************************************************************/
- (NSInteger) indexOfItemWithSubmenu:(AZMenu *) submenu
	{
	NSInteger index = 0;
	for (AZMenuItem *candidate in _items)
		{
		if (candidate.submenu == submenu)
			return index;
		index ++;
		}
	return -1;
	}


// MARK: Submenu management

/*****************************************************************************\
|* Assigns a menu to be a submenu of the menu controlled by a given menu item
\*****************************************************************************/
- (void) setSubmenu:(AZMenu *) menu forItem:(AZMenuItem *) item
	{
	item.submenu = menu;
	}

/*****************************************************************************\
|* The action method assigned to menu items that open submenus. Here to be
|* overridden by subclasses. Do not invoke directly
\*****************************************************************************/
- (void) submenuAction:(id) sender
	{}


// Show a popup menu and run it

/*****************************************************************************\
|* Show a popup menu and run it, waiting for a click either on the menu or
|* off it (to dismiss)
\*****************************************************************************/
- (BOOL) popUpMenuPositioningItem:(AZMenuItem *) item
                       atLocation:(NSPoint) location
                           inView:(AZView *) view
	{
	BOOL ok = NO;
	
	// Find the contentview for this view
	AZView *contentView = view;
	while (contentView.superview != nil)
		contentView = view.superview;

	// Add a subview to the contentview which will overlay the entire content-
	// view, which is how we trap the clicks and make the menu modal
	_overlay = [[AZMenuOverlayView alloc] initWithFrame:[contentView frame]];
	[contentView addSubview:_overlay before:nil];

	// Find the position of the co-ordinates in window space (which is the
	// space that the overlay is running in
	NSPoint p = [view convertPoint:location toView:nil];
		NSLog(@"point: %@ -> %@", NSStringFromPoint(location), NSStringFromPoint(p));
	return ok;
	}


@end
