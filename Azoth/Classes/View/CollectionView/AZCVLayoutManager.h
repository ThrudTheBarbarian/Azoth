//
//  AZCVLayoutManager.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/7/25.
//

#import <Foundation/Foundation.h>
#import <Azoth/AZTypes.h>
#import <Azoth/AZCVLayoutOperation.h>

NS_ASSUME_NONNULL_BEGIN

@class AZCollectionView;


@interface AZCVLayoutManager : NSObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithCollectionView:(AZCollectionView *)cv;
+ (instancetype) managerWithCV:(AZCollectionView *)cv;

// MARK: Enumeration

/*****************************************************************************\
|* Enumerate the items
\*****************************************************************************/
- (void)enumerateItems:(AZCVLayoutOperationIterator)iterator
	   completionBlock:(dispatch_block_t)completionBlock;

/*****************************************************************************\
|* .. and stop that happening
\*****************************************************************************/
- (void)cancelItemEnumerator;


// MARK: Primitives

/*****************************************************************************\
|* Max items per row
\*****************************************************************************/
- (NSUInteger)maximumNumberOfItemsPerRow;


/*****************************************************************************\
|* Size of each cell - we currently assume each cell is the same size
\*****************************************************************************/
- (NSSize)cellSize;


// MARK: Rows and columns

/*****************************************************************************\
|* Return the index of the item at a given row/col combination
\*****************************************************************************/
- (NSUInteger) indexOfItemAtRow:(NSUInteger)rowIndex
						 column:(NSUInteger)colIndex;

/*****************************************************************************\
|* The inverse - return the row/col of an item at a given index
\*****************************************************************************/
- (NSPoint)rowAndColumnPositionOfItemAtIndex:(NSUInteger)anIndex;


// MARK: pixel-position to item

/*****************************************************************************\
|* Given a point, return the item that matches it
\*****************************************************************************/
- (NSUInteger) indexOfItemAtPoint:(NSPoint)p;

/*****************************************************************************\
|* Given a point, return the index of the content-rect that matches it
\*****************************************************************************/
- (NSUInteger) indexOfItemContentRectAtPoint:(NSPoint)p;


// MARK: item to pixel-position

/*****************************************************************************\
|* Given an index, return the rect of the item it represents
\*****************************************************************************/
- (NSRect) rectOfItemAtIndex:(NSUInteger)idx;

/*****************************************************************************\
|* Given an index, return the rect of the content-rect it represents
\*****************************************************************************/
- (NSRect) contentRectOfItemAtIndex:(NSUInteger)idx;


/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The collection view we're laying out
@property(weak, nonatomic) AZCollectionView *					collectionView;

// The queue that's doing the work
@property(strong, nonatomic) NSOperationQueue *					queue;

// The layouts
@property(strong, nonatomic) NSArray<AZCVLayoutItem *> *		itemLayouts;
@end

NS_ASSUME_NONNULL_END
