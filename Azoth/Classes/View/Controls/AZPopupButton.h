//
//  AZPopupButton.h
//  Azoth
//
//  Created by Simon Gornall on 12/20/24.
//

#import <AZoth/AZControl.h>

@class AZMenu;
@class AZMenuItem;

typedef enum
	{
	PopupButtonTypePopup 			= 0,
	PopupButtonTypePullDown			= 2,
	} AZPopupButtonType;

NS_ASSUME_NONNULL_BEGIN

@interface AZPopupButton : AZControl
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame pullsDown:(BOOL)yn;
+ (AZPopupButton *) buttonWithFrame:(NSRect)frame pullsDown:(BOOL)yn;
+ (AZPopupButton *) pullDownButtonWithTitle:(NSString *)text menu:(AZMenu *)menu;
+ (AZPopupButton *) popupButtonWithTitle:(NSString *)text menu:(AZMenu *)menu;


// MARK: Inserting and deleting items

/*****************************************************************************\
|* Adds an item with the specified title to the end of the menu
\*****************************************************************************/
- (void) addItemWithTitle:(NSString *) title;

/*****************************************************************************\
|* Adds an item with the specified title/tag to the end of the menu
\*****************************************************************************/
- (void) addItemWithTitle:(NSString *) title andTag:(NSInteger)tag;

/*****************************************************************************\
|* Adds multiple items to the end of the menu
\*****************************************************************************/
- (void) addItemsWithTitles:(NSArray<NSString *> *) itemTitles;

/*****************************************************************************\
|* Inserts an item at the specified position in the menu
\*****************************************************************************/
- (void) insertItemWithTitle:(NSString *) title atIndex:(NSInteger) index;

/*****************************************************************************\
|* Removes all items in the receiver’s item menu
\*****************************************************************************/
- (void) removeAllItems;

/*****************************************************************************\
|* Removes the item with the specified title from the menu
\*****************************************************************************/
- (BOOL) removeItemWithTitle:(NSString *) title;

/*****************************************************************************\
|* Removes the item at the specified index
\*****************************************************************************/
- (BOOL) removeItemAtIndex:(NSInteger) index;


// MARK: Selection...


/*****************************************************************************\
|* The menu item that was last selected by the user
\*****************************************************************************/
- (nullable AZMenuItem *) selectedItem;

/*****************************************************************************\
|* The title of the item that was last selected by the user
\*****************************************************************************/
- (NSString *) titleOfSelectedItem;

/*****************************************************************************\
|* The index of the item that was last selected by the user
\*****************************************************************************/
- (NSInteger) indexOfSelectedItem;

/*****************************************************************************\
|* The tag of the menu item that was last selected by the user
\*****************************************************************************/
- (NSInteger) selectedTag;


/*****************************************************************************\
|* Selects the specified menu item
\*****************************************************************************/
- (void) selectItem:(AZMenuItem *) item;

/*****************************************************************************\
|* Selects the item in the menu at the specified index
\*****************************************************************************/
- (void) selectItemAtIndex:(NSInteger) index;

/*****************************************************************************\
|* Selects the menu item with the specified tag.
\*****************************************************************************/
- (BOOL) selectItemWithTag:(NSInteger) tag;

/*****************************************************************************\
|* Selects the item with the specified title
\*****************************************************************************/
- (BOOL) selectItemWithTitle:(NSString *) title;


// MARK: Menu access...


/*****************************************************************************\
|* The array of menu item objects associated with the button
\*****************************************************************************/
- (NSArray<AZMenuItem *> *) itemArray;

/*****************************************************************************\
|* Returns the title of the item at the specified index
\*****************************************************************************/
- (nullable AZMenuItem *) itemAtIndex:(NSInteger) index;

/*****************************************************************************\
|* Returns the list of item titles in the menu
\*****************************************************************************/
- (NSArray<NSString *> *) itemTitles;

/*****************************************************************************\
|* Returns the menu item with the specified title
\*****************************************************************************/
- (nullable AZMenuItem *) itemWithTitle:(NSString *) title;

/*****************************************************************************\
|* The last item in the menu
\*****************************************************************************/
- (AZMenuItem *) lastItem;


// MARK: Item indices



/*****************************************************************************\
|* Returns the index of the specified menu item
\*****************************************************************************/
- (NSInteger) indexOfItem:(AZMenuItem *) item;

/*****************************************************************************\
|* Returns the index of the menu item with the specified tag
\*****************************************************************************/
- (NSInteger) indexOfItemWithTag:(NSInteger) tag;

/*****************************************************************************\
|* Returns the index of the item with the specified title
\*****************************************************************************/
- (NSInteger) indexOfItemWithTitle:(NSString *) title;

/*****************************************************************************\
|* Returns the index of the menu item that holds the represented object
\*****************************************************************************/
- (NSInteger) indexOfItemWithRepresentedObject:(NSObject *)obj;

/*****************************************************************************\
|* Returns the index of the menu item with the specified target and action
\*****************************************************************************/
- (NSInteger) indexOfItemWithTarget:(NSObject *)target andAction:(SEL)action;






/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The menu backing this popup button
@property (strong, nonatomic) AZMenu *									menu;
@end

NS_ASSUME_NONNULL_END
