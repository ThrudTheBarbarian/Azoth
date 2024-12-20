//
//  AZMenu.h
//  Azoth
//
//  Created by Simon Gornall on 12/18/24.
//

#import <Azoth/AZControl.h>

NS_ASSUME_NONNULL_BEGIN

@class AZMenuItem;
@class AZView;

struct AZMenuSize;

@interface AZMenu : AZControl

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithTitle:(NSString *)title;
+ (AZMenu *) menuWithTitle:(NSString *)title;

// MARK: Adding items

/*****************************************************************************\
|* Insert a menu item at an index
\*****************************************************************************/
- (BOOL) insertItem:(AZMenuItem *) newItem atIndex:(NSInteger) index;

/*****************************************************************************\
|* Creates and adds a menu item at a specified location in the menu
\*****************************************************************************/
- (nullable AZMenuItem *) insertItemWithTitle:(NSString *)title
									   action:(nullable SEL)selector
								keyEquivalent:(NSString *)charCode
									  atIndex:(NSInteger)index;

/*****************************************************************************\
|* Adds a menu item to the end of the menu
\*****************************************************************************/
- (void) addItem:(AZMenuItem *) newItem;

/*****************************************************************************\
|* Creates a new menu item and adds it to the end of the menu
\*****************************************************************************/
- (AZMenuItem *) addItemWithTitle:(NSString *) string
                           action:(nullable SEL) selector
                    keyEquivalent:(NSString *) charCode;

/*****************************************************************************\
|* Adds a menu item to the end of the menu
\*****************************************************************************/
- (int) widthForString:(NSString *)text;

/*****************************************************************************\
|* Return the items
\*****************************************************************************/
- (NSArray<AZMenuItem *> *) itemArray;

// MARK: Removing items


/*****************************************************************************\
|* Removes a menu item from the menu
\*****************************************************************************/
- (void) removeItem:(AZMenuItem *) item;

/*****************************************************************************\
|* Removes the menu item at a specified location in the menu
\*****************************************************************************/
- (BOOL) removeItemAtIndex:(NSInteger) index;

/*****************************************************************************\
|* Removes the first menu item with the given title
\*****************************************************************************/
- (BOOL) removeItemWithTitle:(NSString *) title;

/*****************************************************************************\
|* Removes all the menu items in the menu.
\*****************************************************************************/
- (void) removeAllItems;


// MARK: Finding items


/*****************************************************************************\
|* Returns the first menu item in the menu with the specified tag
\*****************************************************************************/
- (nullable AZMenuItem *) itemWithTag:(NSInteger) tag;

/*****************************************************************************\
|* Returns the first menu item in the menu with a specified title
\*****************************************************************************/
- (nullable AZMenuItem *) itemWithTitle:(NSString *) title;

/*****************************************************************************\
|* Returns the menu item at a specific location of the menu
\*****************************************************************************/
- (nullable AZMenuItem *) itemAtIndex:(NSInteger) index;

/*****************************************************************************\
|* Returns the index identifying the location of a specified menu item in the
|* menu, or -1 if it cannot be found
\*****************************************************************************/
- (NSInteger) indexOfItem:(AZMenuItem *) item;

/*****************************************************************************\
|* Returns the index of the first menu item in the menu that has a specified
|* title, or -1 if it cannot be found
\*****************************************************************************/
- (NSInteger) indexOfItemWithTitle:(NSString *) title;

/*****************************************************************************\
|* Returns the index of the first menu item in the menu identified by a tag,
|* or -1 if it cannot be found
\*****************************************************************************/
- (NSInteger) indexOfItemWithTag:(NSInteger) tag;

/*****************************************************************************\
|* Returns the index of the first menu item in the menu that has a given
|* represented object, or -1 if it cannot be found
\*****************************************************************************/
- (NSInteger) indexOfItemWithRepresentedObject:(NSObject *) object;

/*****************************************************************************\
|* Returns the index of the menu item in the menu with the given submenu,
|* or -1 if it cannot be found
\*****************************************************************************/
- (NSInteger) indexOfItemWithSubmenu:(AZMenu *) submenu;

/*****************************************************************************\
|* Returns the index of the menu item with the specified target and action
\*****************************************************************************/
- (NSInteger) indexOfItemWithTarget:(NSObject *)target andAction:(SEL)action;

/*****************************************************************************\
|* Returns the last item, or nil if there are none
\*****************************************************************************/
- (nullable AZMenuItem *) lastItem;

/*****************************************************************************\
|* Returns the list of item titles in the menu
\*****************************************************************************/
- (NSArray<NSString *> *) itemTitles;


// MARK: Selection

/*****************************************************************************\
|* Select a menu item
\*****************************************************************************/
- (BOOL) selectItem:(AZMenuItem *)item;

/*****************************************************************************\
|* Selects the item in the menu at the specified index
\*****************************************************************************/
- (BOOL) selectItemAtIndex:(NSInteger)index;

/*****************************************************************************\
|* Selects the menu item with the specified tag.
\*****************************************************************************/
- (BOOL) selectItemWithTag:(NSInteger)tag;

/*****************************************************************************\
|* Selects the item with the specified title
\*****************************************************************************/
- (BOOL) selectItemWithTitle:(NSString *) title;

/*****************************************************************************\
|* Returns the selected item, or nil if there are none
\*****************************************************************************/
- (nullable AZMenuItem *) selectedItem;

/*****************************************************************************\
|* Returns the index of the selected item, or -1 if there are none
\*****************************************************************************/
- (NSInteger) selectedIndex;


// MARK: Submenu management

/*****************************************************************************\
|* Assigns a menu to be a submenu of the menu controlled by a given menu item
\*****************************************************************************/
- (void) setSubmenu:(AZMenu *) menu forItem:(AZMenuItem *) item;

/*****************************************************************************\
|* The action method assigned to menu items that open submenus. Here to be
|* overridden by subclasses. Do not invoke directly
\*****************************************************************************/
- (void) submenuAction:(id) sender;


/*****************************************************************************\
|* Show a popup menu and run it, waiting for a click either on the menu or
|* off it (to dismiss)
\*****************************************************************************/
- (void) popUpMenuPositioningItem:(AZMenuItem *) item
                       atLocation:(NSPoint) location
                           inView:(AZView *) view
						 thenCall:(MenuDoneBlock)callback;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The number of menu items in the menu, including
// separator/header items
@property (copy, nonatomic) NSString* 							title;

// The number of menu items in the menu, including
// separator/header items
@property (readonly) NSInteger 									numberOfItems;

// The parent menu that contains this menu as a submenu.
// If the menu has no parent menu, then the value of this
// property is nil.
@property (assign, nullable) AZMenu * 							supermenu;

// The size of the menu in screen coordinates
@property (readonly) NSSize 									size;

// Indicates the currently highlighted item in the menu
@property (strong, readonly) AZMenuItem * 						highlightedItem;

// Describe how to render the menu (top/bottom/show-title)
@property (assign, nonatomic) AZMenuRenderFlag					renderFlags;

// Determines whether this is a pop-up or a pull-down menu
@property(assign, nonatomic) BOOL 								pullsDown;

// This is the first-calculated statistics of the menu. Can
// be manually altered if the menu ever changes. Used to make
// sure that the widths of the popup/pulldowns don't change
// drastically between invocations
@property(assign, nonatomic) AZMenuSize 						measure;
@end

NS_ASSUME_NONNULL_END
