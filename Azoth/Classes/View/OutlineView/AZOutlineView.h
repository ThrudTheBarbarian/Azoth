//
//  AZOutlineView.h
//  Azoth
//
//  Created by Simon Gornall on 12/31/24.
//

#import <Azoth/AZTableView.h>

NS_ASSUME_NONNULL_BEGIN

@class AZTableColumn;
@class AZOutlineView;

/*****************************************************************************\
|* OutlineView datasource
\*****************************************************************************/
@protocol AZOutlineViewDataSource <NSObject>

// Return the number of children for a given item
- (NSInteger)outlineView:(AZOutlineView *)ov
  numberOfChildrenOfItem:(nullable NSObject *)item;

// Tell the outline view whether an item is expandable
- (BOOL)outlineView:(AZOutlineView *)ov isItemExpandable:(NSObject *)item;

// Get the specified child item of a given item
- (NSObject *) outlineView:(AZOutlineView *)ov
					 child:(NSInteger)index
					ofItem:(nullable NSObject *)item;
@end

/*****************************************************************************\
|* OutlineView delegate
\*****************************************************************************/
@protocol AZOutlineViewDelegate <NSObject>

// Fetch the view for a given row
- (AZView *) outlineView:(AZOutlineView *)ov
	  viewForTableColumn:(AZTableColumn *)column
				     row:(NSInteger)row;

@optional

// See if we should expand an item
- (BOOL)outlineView:(AZOutlineView *)ov shouldExpandItem:item;

// .. or collapse one
- (BOOL)outlineView:(AZOutlineView *)ov shouldCollapseItem:item;

// .. or change the selection in general
- (BOOL)selectionShouldChangeInOutlineView:(AZOutlineView *)ov;

// .. or allow selection of an item
- (BOOL)outlineView:(AZOutlineView *)ov shouldSelectItem:item;

// Do we want to provide widths for views by item ?
- (float) outlineView:(AZOutlineView *)ov
		  widthOfView:(AZView *)view
	   forTableColumn:(AZTableColumn *)column
			   byItem:(nullable NSObject *)item;

// We got a right-click on the outline view
- (void) outlineView:(AZOutlineView *)ov
	 rightClickAtRow:(NSInteger)row
	            item:(nullable NSObject *)item;
@end

/*****************************************************************************\
|* OutlineView ...
\*****************************************************************************/
@interface AZOutlineView : AZTableView

/*****************************************************************************\
|* Get the item for a given row
\*****************************************************************************/
- (nullable NSObject *) itemAtRow:(NSInteger)row;

/*****************************************************************************\
|* Get the row for an item
\*****************************************************************************/
- (NSInteger) rowForItem:(NSObject *)item;

/*****************************************************************************\
|* Get the parent for a given item
\*****************************************************************************/
- (NSObject *) parentForItem:(NSObject *)item;

/*****************************************************************************\
|* Is an item expandable
\*****************************************************************************/
- (BOOL) isExpandable:(NSObject *)item;

/*****************************************************************************\
|* Is an item expanded
\*****************************************************************************/
- (BOOL) isItemExpanded:(NSObject *)item;

/*****************************************************************************\
|* What indentation level is the item at
\*****************************************************************************/
- (NSInteger) levelForItem:(NSObject *)item;

/*****************************************************************************\
|* What indentation level is a given row at
\*****************************************************************************/
- (NSInteger) levelForRow:(NSInteger)row;


/*****************************************************************************\
|* expand an item
\*****************************************************************************/
- (void) expandItem:(NSObject *)item;

/*****************************************************************************\
|* expand an item, optionally expanding children as well
\*****************************************************************************/
- (void) expandItem:(NSObject *)item expandChildren:(BOOL)expandChildren;

/*****************************************************************************\
|* collapse an item
\*****************************************************************************/
- (void) collapseItem:(NSObject *)item;

/*****************************************************************************\
|* collapse an item, optionally expanding children as well
\*****************************************************************************/
- (void) collapseItem:(NSObject *)item collapseChildren:(BOOL)collapseChildren;

/*****************************************************************************\
|* reload an item
\*****************************************************************************/
- (void) reloadItem:(NSObject *)item;

/*****************************************************************************\
|* reload an item, optionally expanding children as well
\*****************************************************************************/
- (void) reloadItem:(NSObject *)item reloadChildren:(BOOL)reloadChildren;


// MARK: Embedded view management

/*****************************************************************************\
|* Embed a view representing a row within an AZOutlineItemView so we can
|* have disclosure triangles etc.
\*****************************************************************************/
- (AZView *) embedInItemView:(AZView *)view;



/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The table column representing this outline view
@property(strong, nonatomic) AZTableColumn *			outlineColumn;

// The indentation per level
@property(assign, nonatomic) float						indentPerLevel;

// Whether to auto-resize the outline view
@property(assign, nonatomic) BOOL						autoresizeOutline;

// Whether the indentation marker follows the view
@property(assign, nonatomic) BOOL						indentationFollowsView;
@end

NS_ASSUME_NONNULL_END
