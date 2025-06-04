//
//  AZMenuItem.h
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <Foundation/Foundation.h>
#import <Azoth/AZTypes.h>
#import <Azoth/AZMenu.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZMenuItem : NSObject
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithTitle:(NSString *)title
						action:(nullable SEL)action
				 keyEquivalent:(NSString *)charcode;

+ (AZMenuItem *) itemWithTitle:(NSString *)title
						action:(nullable SEL)action
				 keyEquivalent:(NSString *)charcode;

+ (AZMenuItem *) separatorItem;
+ (AZMenuItem *) sectionHeaderWithTitle:(NSString *)title;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Determines whether this menuitem is a separator-item
@property(assign, nonatomic) BOOL						separatorItem;

// Determines whether this menuitem is a header-item
@property(assign, nonatomic) BOOL						headerItem;

// Determines if this menu has a submenu
@property(strong, nonatomic, nullable) AZMenu *			hasSubmenu;

// State for this menu item
@property(assign, nonatomic) AZControlStateValue		state;

// The owning menu for this menuItem
@property(weak, nonatomic) AZMenu *						menu;

// The tag of this item, can be used to select etc.
@property(assign, nonatomic) NSInteger					tag;

// The represented object. Kind of like a tag
// but is an object so can carry more context
@property(strong, nonatomic) NSObject *					representedObject;

// The string for this menu-item
@property(copy, nonatomic) NSString *					title;

// The target for any action called
@property(strong, nonatomic) NSObject *					target;

// The action to call on the target, or nil
@property(nullable) SEL									action;

// The action to call on the target, or nil
@property(copy, nonatomic, nullable) NSString *			keyEquivalent;

// The submenu for this menuItem, or nil
@property(strong, nonatomic, nullable) AZMenu *			submenu;

@end

NS_ASSUME_NONNULL_END
