//
//  AZCollectionViewDelegate.h
//  Azoth
//
//  Created by Simon Gornall on 1/7/25.
//

#ifndef AZCollectionViewDelegate_h
#define AZCollectionViewDelegate_h


#import <Azoth/AZView.h>

NS_ASSUME_NONNULL_BEGIN

@class AZCollectionView;
@class AZCVGroup;
@class AZImage;
@class AZMenu;
@class AZPasteboard;
@class AZViewController;

@protocol AZPasteboardWriting;

/*****************************************************************************\
|* Scroll directions for when the delegate is listening for them
\*****************************************************************************/
enum
	{
	AZCVScrollUp   = 0,
	AZCVScrollDown = 1
	};

/*****************************************************************************\
|* Delegate protocol. All "VC"s are AZViewController objects, or
|* subclasses thereof
\*****************************************************************************/

@protocol AZCollectionViewDelegate <NSObject>

// MARK: Required delegate methods

@required
// CollectionView assumes all cells are the same size and will resize its
// subviews to this size.
- (NSSize) cellSizeForCollectionView:(AZCollectionView *)cv;

// Return an empty ViewController, this might not be visible to the user
// immediately
- (AZViewController *) reusableVCForCollectionView:(AZCollectionView *)cv;

// The CollectionView is about to display the viewController. Use this method
// to populate it with data
- (void) collectionView:(AZCollectionView *)cv
			 willShowVC:(AZViewController *)vc
			    forItem:(id)anItem;


// MARK: Optional delegate methods

@optional
// The view controller has been removed from view and stored for reuse.
// You can unload any resources here
- (void) collectionView:(AZCollectionView *)cv
	  VCNoLongerVisible:(AZViewController *)vc;


// MARK: redraw delegate methods

// Set the view-controller to be in a selected state. This is called by
// the collectionView to allow the delegate to change the state of the
// view, so the user knows it's selected. The ViewController cannot
// easily do it because it doesn't understand the view itself, but the
// delegate *created* the view, so it knows what to do
- (void) collectionView:(AZCollectionView *)cv
	 updateVCAsSelected:(AZViewController *)vc
			    forItem:(id)item;

// Set the view-controller to be in a deselected state. This is called by
// the collectionView to allow the delegate to change the state of the
// view, so the user knows it's selected. The ViewController cannot
// easily do it because it doesn't understand the view itself, but the
// delegate *created* the view, so it knows what to do
- (void) collectionView:(AZCollectionView *)cv
   updateVCAsDeselected:(AZViewController *)vc
			    forItem:(id)item;

// MARK: Selection delegate methods

// Don't update the viewController directly to reflect select status,
// implement the methods above instead


// Called to see if the delegate wants to deny selection of an item. The
// default behaviour, if this method is not implemented, is to return YES
- (BOOL) collectionView:(AZCollectionView *)cv
	   shouldSelectItem:(id)anItem
				 withVC:(AZViewController *)vc;

// Called to inform the delegate that the item was selected
- (void) collectionView:(AZCollectionView *)cv
		  didSelectItem:(id)anItem
				 withVC:(AZViewController *)vc;

// Called to inform the delegate that the item was deselected
- (void)collectionView:(AZCollectionView *)cv
	   didDeselectItem:(id)anItem
				withVC:(AZViewController *)vc;

// Called to inform the delegate that the selection was changed
- (void)collectionViewSelectionDidChange:(AZCollectionView *)cv;

// Margin for selecting items around one of the managed view-controllers
- (NSSize) insetMarginForSelectingItemsInCollectionView:(AZCollectionView *)cv;


// MARK: Event delegate methods

// Button event: An item was clicked on
- (void)collectionView:(AZCollectionView *)cv
		  didClickItem:(id)anItem
				withVC:(AZViewController *)vc;

// Movement: The view was scrolled in a given direction
- (void)collectionViewDidScroll:(AZCollectionView *)cv
					inDirection:(NSUInteger)scrollDirection;

// Button event: An item was double-clicked on
- (void)collectionView:(AZCollectionView *)cv
	  didDoubleClickVC:(AZViewController *)vc;

// Key event: user pressed delete, get rid of whatever is selected
- (void)collectionView:(AZCollectionView *)cv
  deleteItemsAtIndexes:(NSIndexSet *)indexSet;

// Key event: user started typing, find something that matches
- (BOOL)collectionView:(AZCollectionView *)cv
			nameOfItem:(id)anItem
			startsWith:(NSString *)startingString;


// Whether the Collection View should try to indicate selection
// defaults to YES but subclasses can override and implement the above
// redraw delegate methods
- (BOOL)collectionViewShouldDrawSelections:(AZCollectionView *)cv;

// Whether the Collection View should try to indicate hover
// defaults to YES but subclasses can override and implement the above
// redraw delegate methods
- (BOOL)collectionViewShouldDrawHover:(AZCollectionView *)cv;

// If the delegate wants to supply a context-sensitive menu, it can do
// so by implementing the below. Note there is some more plumbing to do
// in Azoth before menus will work
- (AZMenu *) collectionView:(AZCollectionView *)cv
	  menuForItemsAtIndexes:(NSIndexSet *)indexSet;

// We lost first-responder status
- (void)collectionViewLostFirstResponder:(AZCollectionView *)cv;

// We gained first-responder status
- (void)collectionViewBecameFirstResponder:(AZCollectionView *)cv;



// MARK: Group management.

// Groups are just a range of views, but can indicate a relationship
// between the views

// Height of the group header in this CollectionView
- (NSUInteger) groupHeaderHeightForCollectionView:(AZCollectionView *)cv;

// The header for the group
- (AZViewController *)collectionView:(AZCollectionView *)cv
					  headerForGroup:(AZCVGroup *)group;

// Offset for the top of the items within the group
- (NSInteger) topOffsetForItemsInCollectionView:(AZCollectionView *)cv;



// MARK: Drag and drop

// Return an image for an item at a given index
- (AZImage *) collectionView:(AZCollectionView *)cv
		imageForItemAtIndex:(NSInteger)index;

// Determine if the collection view is allowed to drag the items at a
// given set of indices
- (BOOL)collectionView:(AZCollectionView *)cv
		canDragItemsAtIndexes:(NSIndexSet *)indexSet;

// Provide an id<AZPasteboardWriting> object that can write to the
// pasteboard when a given item is serialised
- (id<AZPasteboardWriting>) collectionView:(AZCollectionView *)cv
					  writerForItemAtIndex:(NSUInteger)itemIndex;

// Determine if this is a valid drop location
- (BOOL)collectionView:(AZCollectionView *)cv
		validateDrop:(id <AZDraggingInfo>)info
		onItemAtIndex:(NSInteger)index;

// Tell the delegate that the drag is over a given view controller
- (void)collectionView:(AZCollectionView *)cv
		dragEnteredViewController:(AZViewController *)vc;

// Tell the delegate that the drag is no longer over a given view controller
- (void)collectionView:(AZCollectionView *)cv
		dragExitedViewController:(AZViewController *)vc;

// We want to perform a drag operation while over a given view controller
- (BOOL)collectionView:(AZCollectionView *)cv
  performDragOperation:(id <AZDraggingInfo>)info
      onViewController:(AZViewController *)vc
               forItem:(id)item;

// Notification that a drag operation is now over this collection view
- (AZDragOperation)collectionView:(AZCollectionView *)cv
		draggingEntered:(id <AZDraggingInfo>)info;

// Notification that a drag operation finished while over this collection view
- (void)collectionView:(AZCollectionView *)cv
		draggingEnded:(id <AZDraggingInfo>)info;

// Notification that a drag operation is no longer over this collection view
- (void)collectionView:(AZCollectionView *)cv
		draggingExited:(id <AZDraggingInfo>)info;


@end

NS_ASSUME_NONNULL_END

#endif /* AZCollectionViewDelegate_h */
