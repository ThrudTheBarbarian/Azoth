//
//  AZPopupButton.m
//  Azoth
//
//  Created by Simon Gornall on 12/20/24.
//

#import <SDL3/SDL.h>

#import "AZApp.h"
#import "AZColour.h"
#import "AZFont.h"
#import "AZMenu.h"
#import "AZMenuItem.h"
#import "AZPainter.h"
#import "AZRenderer.h"
#import "AZPopupButton.h"

@interface AZPopupButton()
@end

enum
	{
	STATE_N	= 0,				// Normal
	STATE_P,					// Pulldown
	STATE_DN,					// Disabled, normal
	STATE_DP,					// Disabled, pulldown

	STATE_NUM
	};

static NSRect	_bL[STATE_NUM];			// Left-hand-side image
static NSRect	_bC[STATE_NUM];			// Center image
static NSRect	_bR[STATE_NUM];			// Right-hand-side image

@implementation AZPopupButton
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame pullsDown:(BOOL)yn
	{
	if (self = [super initWithFrame:frame])
		{
		[AZPopupButton _fetchRects];

		self.bgColour 		= [AZColour clearColour];
		_menu 				= [AZMenu menuWithTitle:@"Popup"];
		_menu.pullsDown		= yn;
		}
	return self;
	}

+ (AZPopupButton *) buttonWithFrame:(NSRect)frame pullsDown:(BOOL)yn
	{
	return [[AZPopupButton alloc] initWithFrame:frame pullsDown:yn];
	}

/*****************************************************************************\
|* Convenience initialisation for pulldown
\*****************************************************************************/
+ (AZPopupButton *) pullDownButtonWithTitle:(NSString *)text menu:(AZMenu *)menu
	{
	[AZPopupButton _fetchRects];

	AZApp *app 			= AZApp.sharedInstance;
	int width  			= [app.controlFont textWidthFor:text]
						+ _bC[0].size.width
						+ _bR[0].size.width;
	NSRect frame		= NSMakeRect(0, 0, width, _bC[0].size.height);
	AZPopupButton *btn	= [AZPopupButton buttonWithFrame:frame pullsDown:YES];
	if (menu.numberOfItems > 0)
		[[menu itemAtIndex:0] setTitle:text];
	else
		[menu addItemWithTitle:text action:nil keyEquivalent:@""];

	menu.pullsDown = YES;
	btn.menu = menu;

	return btn;
	}

/*****************************************************************************\
|* Convenience initialisation for popup
\*****************************************************************************/
+ (AZPopupButton *) popupButtonWithTitle:(NSString *)text menu:(AZMenu *)menu
	{
	[AZPopupButton _fetchRects];

	AZApp *app 			= AZApp.sharedInstance;
	int width  			= [app.controlFont textWidthFor:text]
						+ _bC[0].size.width
						+ _bR[0].size.width;
	NSRect frame		= NSMakeRect(0, 0, width, _bC[0].size.height);
	AZPopupButton *btn	= [AZPopupButton buttonWithFrame:frame pullsDown:NO];
	if (menu.numberOfItems > 0)
		[[menu itemAtIndex:0] setTitle:text];
	else
		[menu addItemWithTitle:text action:nil keyEquivalent:@""];

	[menu selectItemAtIndex:0];
	menu.pullsDown 		= NO;
	menu.renderFlags 	= AZMENU_RENDER_TOP | AZMENU_RENDER_BOTTOM;
	btn.menu = menu;

	return btn;
	}


/*****************************************************************************\
|* Populate the rectangles from the UI texture atlas
\*****************************************************************************/
+ (void) _fetchRects
	{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,
		^{
		AZApp *app		= AZApp.sharedInstance;
		_bL[STATE_N]   	= [app srcRectFor:@"button-bezel-left"];
		_bL[STATE_P]   	= [app srcRectFor:@"button-bezel-left"];
		_bL[STATE_DN]  	= [app srcRectFor:@"popup-bezel-disabled-left"];
		_bL[STATE_DP]   = [app srcRectFor:@"popup-bezel-disabled-left"];

		_bC[STATE_N]   	= [app srcRectFor:@"popup-bezel-center"];
		_bC[STATE_P]   	= [app srcRectFor:@"popup-bezel-center"];
		_bC[STATE_DN]  	= [app srcRectFor:@"popup-bezel-disabled-center"];
		_bC[STATE_DP]   = [app srcRectFor:@"popup-bezel-disabled-center"];

		_bR[STATE_N]   	= [app srcRectFor:@"popup-bezel-right"];
		_bR[STATE_P]   	= [app srcRectFor:@"popup-bezel-right-pullsdown"];
		_bR[STATE_DN]   = [app srcRectFor:@"popup-bezel-disabled-right"];
		_bR[STATE_DP]   = [app srcRectFor:@"popup-bezel-disabled-right-pullsdown"];
		});
	}

// MARK: Drawing

/*****************************************************************************\
|* Draw the button
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	NSRect bounds	= self.bounds;
	[super drawInRect:dirtyRect withPainter:painter];

	int type		= _menu.pullsDown ? 1 : 0;
	NSRect srcL		= _bL[self.state + type];
	NSRect srcC		= _bC[self.state + type];
	NSRect srcR		= _bR[self.state + type];

	int stretch 	= bounds.size.width - srcL.size.width - srcR.size.width;
	NSRect dstL		= NSMakeRect(0, 0, srcL.size.width, srcL.size.height);
	NSRect dstC  	= NSMakeRect(srcL.size.width, 0, stretch, srcC.size.height);
	NSRect dstR		= NSMakeRect(srcL.size.width + stretch, 0,
								 srcR.size.width, srcR.size.height);

	AZRenderer *azr		= AZRenderer.renderer;
	NSInteger ui		= AZApp.sharedInstance.ui;

	[azr setBlendMode:SDL_BLENDMODE_ADD];
	[azr blitFrom:ui src:srcL dst:dstL];
	[azr tileFrom:ui src:srcC dst:dstC];
	[azr blitFrom:ui src:srcR dst:dstR];

	[painter setTextColour:[AZColour blackColour]];
	NSRect box = NSInsetRect(bounds, 3, 2);
	bounds.size.width -= dstR.size.width;
	[painter drawInBox:box text:_menu.itemArray[0].title];
	}

// Event handling

- (BOOL) mouseDown:(SDL_MouseButtonEvent *)e
	{
	if (_menu.pullsDown)
		_menu.renderFlags = AZMENU_RENDER_BOTTOM;
	else
		_menu.renderFlags = AZMENU_RENDER_BOTTOM | AZMENU_RENDER_TOP;

	int x = self.frame.origin.x;
	int y = self.frame.origin.y + self.frame.size.height;

	[_menu popUpMenuPositioningItem:_menu.itemArray[0]
						 atLocation:NSMakePoint(x, y)
							 inView:self.superview
						   thenCall:^(BOOL menuClicked)
		{
		if ((!self.menu.pullsDown) && (self.menu.numberOfItems > 1))
			{
			self.menu.itemArray[0].title = self.menu.selectedItem.title;
			[self setNeedsDisplay:YES];
			}
			
		if (menuClicked && self.target && self.action)
			[self sendAction:self.action to:self.target];
		}];

	return YES;
	}

// MARK: Inserting and deleting items

/*****************************************************************************\
|* Adds an item with the specified title to the end of the menu
\*****************************************************************************/
- (void) addItemWithTitle:(NSString *) title
	{
	[_menu addItemWithTitle:title action:nil keyEquivalent:@""];
	}

/*****************************************************************************\
|* Adds multiple items to the end of the menu
\*****************************************************************************/
- (void) addItemsWithTitles:(NSArray<NSString *> *) itemTitles
	{
	for (NSString *title in itemTitles)
		[self addItemWithTitle:title];
	}

/*****************************************************************************\
|* Inserts an item at the specified position in the menu
\*****************************************************************************/
- (void) insertItemWithTitle:(NSString *) title atIndex:(NSInteger) index
	{
	[_menu insertItemWithTitle:title action:nil keyEquivalent:@"" atIndex:index];
	}

/*****************************************************************************\
|* Removes all items in the receiver’s item menu
\*****************************************************************************/
- (void) removeAllItems
	{
	[_menu removeAllItems];
	}

/*****************************************************************************\
|* Removes the item with the specified title from the menu
\*****************************************************************************/
- (BOOL) removeItemWithTitle:(NSString *) title
	{
	return [_menu removeItemWithTitle:title];
	}

/*****************************************************************************\
|* Removes the item at the specified index
\*****************************************************************************/
- (BOOL) removeItemAtIndex:(NSInteger) index
	{
	return [_menu removeItemAtIndex:index];
	}


// MARK: Selection...


/*****************************************************************************\
|* The menu item that was last selected by the user
\*****************************************************************************/
- (nullable AZMenuItem *) selectedItem
	{
	return _menu.highlightedItem;
	}

/*****************************************************************************\
|* The title of the item that was last selected by the user
\*****************************************************************************/
- (NSString *) titleOfSelectedItem
	{
	return _menu.highlightedItem.title;
	}

/*****************************************************************************\
|* The index of the item that was last selected by the user
\*****************************************************************************/
- (NSInteger) indexOfSelectedItem;
	{
	return _menu.selectedIndex;
	}

/*****************************************************************************\
|* The tag of the menu item that was last selected by the user
\*****************************************************************************/
- (NSInteger) selectedTag;
	{
	return self.selectedItem.tag;
	}


/*****************************************************************************\
|* Selects the specified menu item
\*****************************************************************************/
- (void) selectItem:(AZMenuItem *) item
	{
	[_menu selectItem:item];
	}

/*****************************************************************************\
|* Selects the item in the menu at the specified index
\*****************************************************************************/
- (void) selectItemAtIndex:(NSInteger) index
	{
	[_menu selectItemAtIndex:index];
	}

/*****************************************************************************\
|* Selects the menu item with the specified tag.
\*****************************************************************************/
- (BOOL) selectItemWithTag:(NSInteger) tag
	{
	return [_menu selectItemWithTag:tag];
	}

/*****************************************************************************\
|* Selects the item with the specified title
\*****************************************************************************/
- (BOOL) selectItemWithTitle:(NSString *) title
	{
	return [_menu selectItemWithTitle:title];
	}


// MARK: Menu access...



/*****************************************************************************\
|* The array of menu item objects associated with the button
\*****************************************************************************/
- (NSArray<AZMenuItem *> *) itemArray
	{
	return _menu.itemArray;
	}

/*****************************************************************************\
|* Returns the title of the item at the specified index
\*****************************************************************************/
- (nullable AZMenuItem *) itemAtIndex:(NSInteger) index
	{
	return [_menu itemAtIndex:index];
	}

/*****************************************************************************\
|* Returns the list of item titles in the menu
\*****************************************************************************/
- (NSArray<NSString *> *) itemTitles;
	{
	return [_menu itemTitles];
	}

/*****************************************************************************\
|* Returns the menu item with the specified title
\*****************************************************************************/
- (nullable AZMenuItem *) itemWithTitle:(NSString *) title;
	{
	return [_menu itemWithTitle:title];
	}

/*****************************************************************************\
|* The last item in the menu
\*****************************************************************************/
- (AZMenuItem *) lastItem
	{
	return _menu.lastItem;
	}


// MARK: Item indices


/*****************************************************************************\
|* Returns the index of the item, or -1
\*****************************************************************************/
- (NSInteger) indexOfItem:(AZMenuItem *) item
	{
	return [_menu indexOfItem:item];
	}

/*****************************************************************************\
|* Returns the index of the menu item with the specified tag
\*****************************************************************************/
- (NSInteger) indexOfItemWithTag:(NSInteger) tag
	{
	return [_menu indexOfItemWithTag:tag];
	}

/*****************************************************************************\
|* Returns the index of the item with the specified title
\*****************************************************************************/
- (NSInteger) indexOfItemWithTitle:(NSString *) title
	{
	return [_menu indexOfItemWithTitle:title];
	}

/*****************************************************************************\
|* Returns the index of the menu item that holds the represented object
\*****************************************************************************/
- (NSInteger) indexOfItemWithRepresentedObject:(NSObject *)obj
	{
	return [_menu indexOfItemWithRepresentedObject:obj];
	}

/*****************************************************************************\
|* Returns the index of the menu item with the specified target and action
\*****************************************************************************/
- (NSInteger) indexOfItemWithTarget:(NSObject *)target andAction:(SEL) action
	{
	return [_menu indexOfItemWithTarget:target andAction:action];
	}









@end
