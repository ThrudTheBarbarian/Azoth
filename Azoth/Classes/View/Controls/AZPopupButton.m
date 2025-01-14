//
//  AZPopupButton.m
//  Azoth
//
//  Created by Simon Gornall on 12/20/24.
//

#import <SDL3/SDL.h>

#import "AZApplication.h"
#import "AZColour.h"
#import "AZFont.h"
#import "AZMenu.h"
#import "AZMenuItem.h"
#import "AZPainter.h"
#import "AZRenderer.h"
#import "AZPopupButton.h"
#import "AZZib.h"
#import "NSDictionary+ZIB.h"

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

static NSRect		_uiRect;				// drawing rect
static NSInteger	_ui[STATE_NUM];			// 9-way texture-maps
static float 		_uiW[STATE_NUM];		// left-border for 9-way
static float		_uiN[STATE_NUM];		// top-border for 9-way
static float		_uiE[STATE_NUM];		// right-border for 9-way
static float 		_uiS[STATE_NUM];		// bottom-border for 9-way

@implementation AZPopupButton
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame pullsDown:(BOOL)yn
	{
	if (self = [super initWithFrame:frame])
		{
		[self _commonPopUpButtonInit];

		_menu 					= [AZMenu menuWithTitle:@"Popup"];
		_menu.pullsDown			= yn;
		}
	return self;
	}

+ (AZPopupButton *) buttonWithFrame:(NSRect)frame pullsDown:(BOOL)yn
	{
	return [[AZPopupButton alloc] initWithFrame:frame pullsDown:yn];
	}

/*****************************************************************************\
|* Configuration via dictionary. This is called by the NIB loader, but is a
|* valid way to create the view
\*****************************************************************************/
- (instancetype) initWithDictionary:(NSDictionary *)info;
	{
	if (self = [super initWithDictionary:info])
		{
		[self _commonPopUpButtonInit];

		// Fetch the title
		NSString *title 		= [info AZStringWithKey:kZibTitle
											  orDefault:@"Button"];

		// Build the menu
		_menu 					= [AZMenu menuWithTitle:title];
		NSArray *items			= [info valueForKeyPath:@"menu.items.menuItem"];

		int idx = 0;
		int selected = -1;
		NSString *selectedId	= info[kZibSelect];
		for (NSDictionary *item in items)
			{
			[_menu addItemWithTitle:item[kZibTitle]
							 action:nil
					  keyEquivalent:@""];
			[[_menu lastItem] setTag:idx];
			if ([item[kZibId] isEqualToString:selectedId])
				selected = idx;
			idx ++;
			}

		// If we have a selection, select it.
		if (selected >= 0)
			{
			[_menu selectItemWithTag:selected];
			// Only popups change their title when a selection is made
			if (_menu.pullsDown == NO)
				_menu.title = [_menu itemWithTag:selected].title;
			}

		// Set the menu to pullsdown if needed
		if ([info[kZibPullsDown] isEqualToString:@"YES"])
			_menu.pullsDown = YES;
		}
	return self;
	}

/*****************************************************************************\
|* Common initialisation between -withFrame and -withDictionary
\*****************************************************************************/
- (void) _commonPopUpButtonInit
	{
	[AZPopupButton _fetchRects];
		self.backgroundColour	= AZColour.clear;
	}

/*****************************************************************************\
|* Convenience initialisation for pulldown
\*****************************************************************************/
+ (AZPopupButton *) pullDownButtonWithTitle:(NSString *)text menu:(AZMenu *)menu
	{
	[AZPopupButton _fetchRects];

	int width  			= [AZApp.controlFont textWidthFor:text]
						+ _uiE[0]
						+ _uiW[0];
	NSRect frame		= NSMakeRect(0, 0, width, _uiRect.size.height);
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

	int width  			= [AZApp.controlFont textWidthFor:text]
						+ _uiE[0]
						+ _uiW[0];
	NSRect frame		= NSMakeRect(0, 0, width, _uiRect.size.height);
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
		NSRect bL[STATE_NUM];
		NSRect bC[STATE_NUM];
		NSRect bR[STATE_NUM];

		bL[STATE_N]   	= [AZApp srcRectFor:@"button-bezel-left" in:kUiMap];
		bL[STATE_P]   	= [AZApp srcRectFor:@"button-bezel-left" in:kUiMap];
		bL[STATE_DN]  	= [AZApp srcRectFor:@"popup-bezel-disabled-left" in:kUiMap];
		bL[STATE_DP]	= [AZApp srcRectFor:@"popup-bezel-disabled-left" in:kUiMap];

		bC[STATE_N]   	= [AZApp srcRectFor:@"popup-bezel-center" in:kUiMap];
		bC[STATE_P]   	= [AZApp srcRectFor:@"popup-bezel-center" in:kUiMap];
		bC[STATE_DN]  	= [AZApp srcRectFor:@"popup-bezel-disabled-center" in:kUiMap];
		bC[STATE_DP]	= [AZApp srcRectFor:@"popup-bezel-disabled-center" in:kUiMap];

		bR[STATE_N]   	= [AZApp srcRectFor:@"popup-bezel-right" in:kUiMap];
		bR[STATE_P]   	= [AZApp srcRectFor:@"popup-bezel-right-pullsdown" in:kUiMap];
		bR[STATE_DN]	= [AZApp srcRectFor:@"popup-bezel-disabled-right" in:kUiMap];
		bR[STATE_DP]	= [AZApp srcRectFor:@"popup-bezel-disabled-right-pullsdown" in:kUiMap];

		id<AZRenderer> azr	= AZRenderer.renderer;
		NSInteger S			= [AZApp textureFor:kUiMap];

		for (int i=0; i<STATE_NUM; i++)
			{
			int W,H;

			float left 	= NSWidth(bL[i]);
			float mid 	= NSWidth(bC[i]);
			float right	= NSWidth(bR[i]);

			/*****************************************************************\
			|* Create 9-way tileable textures for the button, so we can fill
			|* in the background of any-size button
			\*****************************************************************/
			W = left  + mid  + right;
			H = NSHeight(bL[i]);

			_ui[i] = [azr createTextureOfSize:NSMakeSize(W, H)];

			/*****************************************************************\
			|* Draw the pixmap rectangles to the new combined texture
			\*****************************************************************/
			[azr lockFocusOn:_ui[i]];
			[azr blitFrom:S src:bL[i] dst:NSMakeRect(0 ,0, left, H)];
			[azr blitFrom:S src:bC[i] dst:NSMakeRect(left, 0, mid, H)];
			[azr blitFrom:S src:bR[i] dst:NSMakeRect(left+mid, 0, right, H)];
			[azr unlockFocus];

			_uiRect 	= NSMakeRect(0, 0, W, H);
			_uiW[i]		= left;// left;
			_uiN[i]		= 5;
			_uiE[i]		= right+1;//left + mid+mid;
			_uiS[i]		= 5;
			}
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

	id<AZRenderer> azr	= AZRenderer.renderer;
	int state 			= self.state + (_menu.pullsDown ? 1 : 0);

	[azr setBlendMode:SDL_BLENDMODE_ADD];
	[azr blit9WayFrom:_ui[state]
				  src:_uiRect
				scale:1.f
				 left:_uiW[state]
				right:_uiE[state]
				  top:_uiN[state]
			   bottom:_uiS[state]
				  dst:self.bounds];

	[painter setTextColour:AZColour.black];
	NSRect box 		= NSInsetRect(bounds, 5, 2);
	box.size.width 	= box.size.width + 5 - _uiE[state];

	NSInteger selected = _menu.selectedIndex;
	if ((selected < 0) || (selected >= _menu.itemArray.count))
		selected = 0;
	[painter textInBox:box text:_menu.itemArray[selected].title];
	}

// Event handling

- (BOOL) mouseDown:(AZEvent *)e
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
