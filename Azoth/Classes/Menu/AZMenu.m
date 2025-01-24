//
//  AZMenu.m
//  Azoth
//
//  Created by Simon Gornall on 12/18/24.
//
#import <SDL3/SDL.h>

#import "AZApplication.h"
#import "AZEventSink.h"
#import "AZFont.h"
#import "AZMenu.h"
#import "AZMenuItem.h"
#import "AZMenuView.h"
#import "AZWindow.h"

#define MENU_HEIGHT 		25
#define MENU_LEADING   		12
#define MENU_TRAILING		12

@interface AZMenu()
@property(strong, nonatomic) NSMutableArray<AZMenuItem *> * 	items;
@property(strong, nonatomic) AZMenuView * 						menuView;
@end

@implementation AZMenu
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
+ (AZMenu *) menuWithTitle:(NSString *)title
	{
	return [[AZMenu alloc] initWithTitle:title];
	}

- (instancetype) init
	{
	NSRect frame = NSMakeRect(0, 0, MENU_LEADING + MENU_TRAILING, MENU_HEIGHT);

	if (self = [super initWithFrame:frame])
		{
		_renderFlags = AZMENU_RENDER_TOP | AZMENU_RENDER_BOTTOM;
		_items 		 = [NSMutableArray new];

		// Add the first item as the title of the menu. Menu choices are
		// 1-based to allow for a title at position-0
		AZMenuItem *titleItem = [AZMenuItem sectionHeaderWithTitle:@""];
		[self addItem:titleItem];
		}
	return self;
	}

- (instancetype) initWithTitle:(NSString *)title
	{
	int width  			= [self widthForString:title];
	NSRect frame		= NSMakeRect(100, 100, width, MENU_HEIGHT);

	if (self = [super initWithFrame:frame])
		{
		_items 		 = [NSMutableArray new];
		_renderFlags = AZMENU_RENDER_TOP | AZMENU_RENDER_BOTTOM;

		// Add the first item as the title of the menu. Menu choices are
		// 1-based to allow for a title at position-0
		AZMenuItem *titleItem = [AZMenuItem sectionHeaderWithTitle:title];
		[self addItem:titleItem];
		}
	return self;
	}

/*****************************************************************************\
|* Return the items
\*****************************************************************************/
- (NSArray<AZMenuItem *> *) itemArray
	{
	return _items;
	}


/*****************************************************************************\
|* Figure out the width requirements of an item's string
\*****************************************************************************/
- (int) widthForString:(NSString *)text
	{
	int width  			= [AZApp.controlFont textWidthFor:text]
						+ MENU_LEADING + MENU_TRAILING;
	return width;
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
		newItem.menu = self;
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
	newItem.menu = self;
	if (_highlightedItem == nil)
		_highlightedItem = newItem;

	int w = [self widthForString:newItem.title];
	if (w > self.frame.size.width)
		[self setFrameSize:NSMakeSize(w, self.size.height)];
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
|* Creates a new menu item and adds it to the end of the menu
\*****************************************************************************/
- (AZMenuItem *) addItemWithTitle:(NSString *)title
                           action:(nullable SEL)selector
                    keyEquivalent:(NSString *)charCode
							  tag:(NSInteger)tag;
	{
	AZMenuItem *item = [AZMenuItem itemWithTitle:title
										  action:selector
								   keyEquivalent:charCode];
	[item setTag:tag];
	[self addItem:item];
	return item;
	}

/*****************************************************************************\
|* Creates a new menu item and adds it to the end of the menu, also assigning
|* a tag so the menu can be easily recognised later. This one doesn't allow
|* for keyboard shortcuts or actions, really useful in popup menus
\*****************************************************************************/
- (AZMenuItem *) addItemWithTitle:(NSString *)title tag:(NSInteger)tag
	{
	return [self addItemWithTitle:title action:nil keyEquivalent:@"" tag:tag];
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
|* Removes the first menu item with the given title
\*****************************************************************************/
- (BOOL) removeItemWithTitle:(NSString *) title
	{
	AZMenuItem *toRemove = nil;
	for (AZMenuItem *item in _items)
		if ([item.title isEqualToString:title])
			{
			toRemove = item;
			break;
			}
	if (toRemove)
		[self removeItem:toRemove];
	return (toRemove != nil);
	}

/*****************************************************************************\
|* Return the numbe of items (all types) in the list
\*****************************************************************************/
- (NSInteger) numberOfItems
	{
	return _items.count;
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

/*****************************************************************************\
|* Returns the index of the menu item with the specified target and action
\*****************************************************************************/
- (NSInteger) indexOfItemWithTarget:(NSObject *)target andAction:(SEL)action
	{
	NSInteger index = 0;
	for (AZMenuItem *candidate in _items)
		{
		if ((candidate.target == target) && (candidate.action == action))
			return index;
		index ++;
		}
	return -1;
	}


/*****************************************************************************\
|* Returns the last item, or nil if there are none
\*****************************************************************************/
- (nullable AZMenuItem *) lastItem
	{
	if (_items.count > 0)
		return _items.lastObject;
	return nil;
	}


/*****************************************************************************\
|* Returns the list of item titles in the menu
\*****************************************************************************/
- (NSArray<NSString *> *) itemTitles
	{
	NSMutableArray<NSString *> * itemTitles = [NSMutableArray new];
	for (AZMenuItem *item in _items)
		[itemTitles addObject:item.title];
	return itemTitles;
	}



// MARK: Selection

/*****************************************************************************\
|* Returns the selected item, or nil if there are none
\*****************************************************************************/
- (nullable AZMenuItem *) selectedItem
	{
	for (AZMenuItem *item in _items)
		if (item.state == AZControlStateValueOn)
			return item;
	return nil;
	}

/*****************************************************************************\
|* Returns the index of the selected item, or -1 if there are none
\*****************************************************************************/
- (NSInteger) selectedIndex
	{
	int idx = 0;
	for (AZMenuItem *item in _items)
		{
		if (item.state == AZControlStateValueOn)
			return idx;
		idx ++;
		}
	return -1;
	}


/*****************************************************************************\
|* Select a menu item
\*****************************************************************************/
- (BOOL) selectItem:(AZMenuItem *)item
	{
	BOOL ok = NO;
	for (AZMenuItem *candidate in _items)
		if (item == candidate)
			{
			candidate.state = AZControlStateValueOn;
			ok = YES;
			}
		else
			candidate.state = AZControlStateValueOff;
	[self setNeedsDisplay:YES];
	return ok;
	}


/*****************************************************************************\
|* Selects the item in the menu at the specified index
\*****************************************************************************/
- (BOOL) selectItemAtIndex:(NSInteger)index
	{
	BOOL ok = NO;
	NSInteger count = 0;
	for (AZMenuItem *candidate in _items)
		{
		if (count == index)
			{
			candidate.state = AZControlStateValueOn;
			ok = YES;
			}
		else
			candidate.state = AZControlStateValueOff;
		count ++;
		}
	[self setNeedsDisplay:YES];
	return ok;
	}

/*****************************************************************************\
|* Selects the menu item with the specified tag.
\*****************************************************************************/
- (BOOL) selectItemWithTag:(NSInteger)tag
	{
	BOOL ok = NO;
	for (AZMenuItem *candidate in _items)
		if (tag == candidate.tag)
			{
			candidate.state = AZControlStateValueOn;
			ok = YES;
			}
		else
			candidate.state = AZControlStateValueOff;

	[self setNeedsDisplay:YES];
	return ok;
	}

/*****************************************************************************\
|* Selects the item with the specified title
\*****************************************************************************/
- (BOOL) selectItemWithTitle:(NSString *) title
	{
	BOOL ok = NO;
	for (AZMenuItem *candidate in _items)
		if ([title isEqualToString:candidate.title])
			{
			candidate.state = AZControlStateValueOn;
			ok = YES;
			}
		else
			candidate.state = AZControlStateValueOff;

	[self setNeedsDisplay:YES];
	return ok;
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
- (void) popUpMenuAtLocation:(NSPoint) location
                      inView:(AZView *) view
					thenCall:(MenuDoneBlock)callback
	{
	return [self popUpMenuPositioningItem:[self itemAtIndex:0]
							   atLocation:location
								   inView:view
								 thenCall:callback];
	}

/*****************************************************************************\
|* Show a popup menu and run it, waiting for a click either on the menu or
|* off it (to dismiss)
\*****************************************************************************/
- (void) popUpMenuPositioningItem:(AZMenuItem *) item
                       atLocation:(NSPoint) location
                           inView:(AZView *) view
						 thenCall:(MenuDoneBlock)callback
	{
	// Find the position of the co-ordinates in window space (which is the
	// space that the overlay is running in
	NSPoint p = [view convertPoint:location toView:nil];

	// Run the menu. If there's a click outside the bounds of the menu, we
	// cancel the menu and return NO. If there was a click inside the menu
	// (so a selection was made), we return yes, and we can query the menu
	[self runMenuFor:item at:p inView:view then:^(BOOL menuClicked) {
		[self.menuView removeFromSuperview];
		self.menuView = nil;
		callback(menuClicked);
		}];
	}

/*****************************************************************************\
|* Handle the menu execution
\*****************************************************************************/
- (void) runMenuFor:(AZMenuItem *)item
				 at:(NSPoint)p
			 inView:(AZView *) view
			   then:(MenuDoneBlock)call
	{
	AZMenu *menu	= item.menu;
	AZMenuSize sz 	= [AZMenuView measureMenu:menu];
	_menuView 	  	= [[AZMenuView alloc] initWithMenu:menu andSize:sz];
	AZView *cv    	= (AZView *)[AZWindow contentViewForWindow:view.window];

	NSInteger index	= [menu selectedIndex];
		if ((index < 1) && (menu.numberOfItems > 1))
		index = 1;

	if (!_pullsDown)
		p.y			= p.y
					- (index) * sz.fontHeight
					- sz.topHeight;
	if (p.y < 0)
		p.y = 0;
	if (p.y + _menuView.frame.size.height> cv.frame.size.height)
		p.y = cv.frame.size.height - _menuView.frame.size.height;
	if (p.x < 0)
		p.x = 0;
	if (p.x + _menuView.frame.size.width > cv.frame.size.width)
		p.x = cv.frame.size.width - _menuView.frame.size.width;
	[_menuView setFrameOrigin:p];
	_menuView.call = call;

	[_menuView setupEventSink];
	[cv addSubview:_menuView before:nil];
	}

// MARK: Private methods

@end
