//
//  AZCollectionView.h
//  Azoth
//
//  Created by Simon Gornall on 1/7/25.
//

#import <Azoth/AZView.h>

NS_ASSUME_NONNULL_BEGIN

@class AZCollectionView;
@class AZCVGroup;
@class AZCVLayoutManager;
@class AZViewController;

@protocol AZCollectionViewDelegate;


@interface AZCollectionView : AZView
	{
	}

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame;
- (instancetype) initWithDictionary:(NSDictionary *)info;


// MARK: Loading data

/*****************************************************************************\
|* Add items, optionally clear the cache
\*****************************************************************************/
- (void)reloadDataWithItems:(NSArray *)newContent
				emptyCaches:(BOOL)shouldEmptyCaches;

/*****************************************************************************\
|* Add items, specify groups, optionally clear the cache
\*****************************************************************************/
- (void)reloadDataWithItems:(NSArray *)newContent
					 groups:(NSArray *)newGroups
				emptyCaches:(BOOL)shouldEmptyCaches;

/*****************************************************************************\
|* Add items, specify groups, run a block when done, optionally clear the cache
\*****************************************************************************/
- (void)reloadDataWithItems:(NSArray *)newContent
					 groups:(NSArray *)newGroups
				emptyCaches:(BOOL)shouldEmptyCaches
			completionBlock:(dispatch_block_t)completionBlock;


// MARK: Selection

/*****************************************************************************\
|* Select an item at an index
\*****************************************************************************/
- (void)selectItemAtIndex:(NSUInteger)index;

/*****************************************************************************\
|* Select an item at an index, with the expectation that this is one of many
\*****************************************************************************/
- (void)selectItemAtIndex:(NSUInteger)index inBulk:(BOOL)bulk;

/*****************************************************************************\
|* Select an item using an index-set
\*****************************************************************************/
- (void)selectItemsAtIndexes:(NSIndexSet *)indexes;


/*****************************************************************************\
|* Deselect an item at an index
\*****************************************************************************/
- (void)deselectItemAtIndex:(NSUInteger)index;

/*****************************************************************************\
|* Deselect an item at an index, with the expectation that this is one of many
\*****************************************************************************/
- (void)deselectItemAtIndex:(NSUInteger)index inBulk:(BOOL)bulk;

/*****************************************************************************\
|* Deselect an item using an index-set
\*****************************************************************************/
- (void)deselectItemsAtIndexes:(NSIndexSet *)indexes;

/*****************************************************************************\
|* Deselect everything
\*****************************************************************************/
- (void)deselectAllItems;

/*****************************************************************************\
|* Return what is selected atm
\*****************************************************************************/
- (NSIndexSet *)selectionIndexes;


// MARK: Cell Information


/*****************************************************************************\
|* Return the size of a single cell. We assume all cells are the same size
\*****************************************************************************/
- (NSSize)cellSize;

/*****************************************************************************\
|* Height of the group header
\*****************************************************************************/
- (NSUInteger)groupHeaderHeight;

/*****************************************************************************\
|* Which items are in view
\*****************************************************************************/
- (NSRange)rangeOfVisibleItems;

/*****************************************************************************\
|* Which items are in view, and any extra pre-rendered
\*****************************************************************************/
- (NSRange)rangeOfVisibleItemsWithOverflow;

/*****************************************************************************\
|* The indexes of any items within a given rect
\*****************************************************************************/
- (NSIndexSet *)indexesOfItemsInRect:(NSRect)aRect;

/*****************************************************************************\
|* The indexes of the content-rects of any items in a given rect
\*****************************************************************************/
- (NSIndexSet *)indexesOfItemContentRectsInRect:(NSRect)aRect;


// MARK: View controllers

/*****************************************************************************\
|* The indexes of visible view controllers
\*****************************************************************************/
- (NSIndexSet *)indexesOfViewControllers;

/*****************************************************************************\
|* The indexes of invisible view controllers
\*****************************************************************************/
- (NSIndexSet *)indexesOfInvisibleViewControllers;

/*****************************************************************************\
|* the view-controller for an item at a given index
\*****************************************************************************/
- (AZViewController *)viewControllerForItemAtIndex:(NSUInteger)index;


/*****************************************************************************\
|* Do a relayout
\*****************************************************************************/
- (void)softReloadDataWithCompletionBlock:(dispatch_block_t)block;


/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The delegate
@property(assign, nonatomic)
id<AZCollectionViewDelegate> 							delegate;

// The number of rows we pre-render
@property (assign, nonatomic) NSUInteger 				numberOfPreRenderedRows;

// Which view controllers are visible
@property (readonly)
NSMutableDictionary<NSNumber*,AZViewController*> *		visibleVCs;

// .. and as an array
@property (readonly) NSArray<AZViewController *> *		visibleVCArray;

// The layout manager
@property (readonly) AZCVLayoutManager *				layoutManager;

// Groups we know about
@property (nonatomic, copy) NSArray *					groups;

// The content array
@property (nonatomic, copy) NSArray *					contentArray;

@end

NS_ASSUME_NONNULL_END
