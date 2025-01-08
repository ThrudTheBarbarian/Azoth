//
//  AZCVLayoutManager.m
//  Azoth
//
//  Created by Simon Gornall on 1/7/25.
//

#import "AZCollectionView.h"
#import "AZCVGroup.h"
#import "AZCVLayoutItem.h"
#import "AZCVLayoutManager.h"
#import "AZCVLayoutOperation.h"

@implementation AZCVLayoutManager

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithCollectionView:(AZCollectionView *)cv
	{
	if (self = [super init])
		{
		_collectionView = cv;
		_queue			= [NSOperationQueue new];
		[_queue setMaxConcurrentOperationCount:1];
		}
	return self;
	}

+ (instancetype) managerWithCV:(AZCollectionView *)cv
	{
	return [[AZCVLayoutManager alloc] initWithCollectionView:cv];
	}

// MARK: Enumeration

/*****************************************************************************\
|* Enumerate the items
\*****************************************************************************/
- (void)enumerateItems:(AZCVLayoutOperationIterator)iterator
	   completionBlock:(dispatch_block_t)completionBlock
	{
	AZCVLayoutOperation *op = AZCVLayoutOperation.new;
	op.cv 					= _collectionView;
	op.layoutCallBack 		= iterator;
	op.layoutCompletion 	= completionBlock;

    [self cancelItemEnumerator];
	[_queue addOperation:op];
	}

/*****************************************************************************\
|* .. and stop that happening
\*****************************************************************************/
- (void) cancelItemEnumerator
	{
	[_queue cancelAllOperations];
	}


// MARK: Primitives

/*****************************************************************************\
|* Number of items we can fit in a row
\*****************************************************************************/
- (NSUInteger)maximumNumberOfItemsPerRow
	{
	return MAX(1, _collectionView.frame.size.width/self.cellSize.width);
	}

/*****************************************************************************\
|* Ask the collection view for our cellsize
\*****************************************************************************/
- (NSSize)cellSize
	{
	return _collectionView.cellSize;
	}

// MARK: Rows and cols

/*****************************************************************************\
|* Return the index of the item at a given row/col combination
\*****************************************************************************/
- (NSUInteger) indexOfItemAtRow:(NSUInteger)rowIndex
						 column:(NSUInteger)colIndex;
	{
	__block NSUInteger index = NSNotFound;

	[_itemLayouts enumerateObjectsWithOptions:NSEnumerationConcurrent
								   usingBlock:
		^(AZCVLayoutItem *item, NSUInteger idx, BOOL *stop)
			{
			if ((item.rowIndex == rowIndex) && (item.colIndex == colIndex))
				{
				index = item.itemIndex;
				*stop = YES;
				}
			}];
	return index;
	}

/*****************************************************************************\
|* The inverse - return the row/col of an item at a given index
\*****************************************************************************/
- (NSPoint)rowAndColumnPositionOfItemAtIndex:(NSUInteger)anIndex;
	{
	if (_itemLayouts.count > anIndex)
		{
    	AZCVLayoutItem *layout = _itemLayouts[anIndex];
		return NSMakePoint(layout.colIndex, layout.rowIndex);
		}
    return NSZeroPoint;
	}


// MARK: pixel-position to item

/*****************************************************************************\
|* Given a point, return the item that matches it
\*****************************************************************************/
- (NSUInteger) indexOfItemAtPoint:(NSPoint)p
	{
	NSInteger count = _itemLayouts.count;
	for (NSInteger i=0; i<count; i++)
		if (NSPointInRect(p, _itemLayouts[i].itemRect))
			return i;
	return NSNotFound;
	}

/*****************************************************************************\
|* Given a point, return the index of the content-rect that matches it
\*****************************************************************************/
- (NSUInteger) indexOfItemContentRectAtPoint:(NSPoint)p
	{
	NSUInteger index = [self indexOfItemAtPoint:p];
	if (index != NSNotFound)
		{
		if (NSPointInRect(p, [self contentRectOfItemAtIndex:index]))
			return index;
		else
			return NSNotFound;
		}
	return index;
	}


// MARK: item to pixel-position

/*****************************************************************************\
|* Given an index, return the rect of the item it represents
\*****************************************************************************/
- (NSRect) rectOfItemAtIndex:(NSUInteger)idx
	{
	if (idx < _itemLayouts.count)
		return _itemLayouts[idx].itemRect;
    return NSZeroRect;
	}

/*****************************************************************************\
|* Given an index, return the rect of the content-rect it represents
\*****************************************************************************/
- (NSRect) contentRectOfItemAtIndex:(NSUInteger)idx
	{
	if (idx < _itemLayouts.count)
		return _itemLayouts[idx].itemContentRect;
    return NSZeroRect;
	}


@end
