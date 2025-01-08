//
//  AZCVLayoutOperation.m
//  Azoth
//
//  Created by Simon Gornall on 1/7/25.
//

#import "AZCollectionView.h"
#import "AZCollectionViewDelegate.h"
#import "AZCVGroup.h"
#import "AZCVLayoutItem.h"
#import "AZCVLayoutManager.h"
#import "AZCVLayoutOperation.h"
#import "AZTypes.h"

@implementation AZCVLayoutOperation

/*****************************************************************************\
|* The implementation of the layout operation
\*****************************************************************************/
- (void)main
	{
	if ([self isCancelled])
		return;
  
	NSInteger numberOfRows 	= 0;
	NSInteger startingX 	= 0;
	NSInteger x 			= 0;
	NSInteger y 			= 0;
	NSUInteger colIndex   	= 0;
	NSRect visibleRect    	= [_cv visibleRect];
	float W					= [_cv cellSize].width;
	float H					= [_cv cellSize].height;
	NSSize inset          	= NSZeroSize;
	NSInteger maxColumns  	= [_cv.layoutManager maximumNumberOfItemsPerRow];
	float frameWidth		= NSWidth(_cv.frame);
	NSUInteger gap        	= 0;

	if (maxColumns > 1)
		gap = (frameWidth - maxColumns * W) / (maxColumns-1);

	if (maxColumns < 4 && maxColumns >= 1)
		{
		gap 		= (frameWidth - maxColumns * W) / (maxColumns+1);
		startingX 	= gap;
		x 			= gap;
		}

	SEL insetSel = SELECTOR(@"insetMarginForSelectingItemsInCollectionView:");
 	if ([_cv.delegate respondsToSelector:insetSel])
		inset = [_cv.delegate insetMarginForSelectingItemsInCollectionView:_cv];

	NSMutableArray *newLayouts   	= NSMutableArray.new;
	NSEnumerator *groupEnum      	= _cv.groups.objectEnumerator;
	AZCVGroup *group 				= groupEnum.nextObject;

	if (!group.isCollapsed)
		{
		SEL topSel = SELECTOR(@"topOffsetForItemsInCollectionView:");
		if ([_cv.delegate respondsToSelector:topSel])
			y += [_cv.delegate topOffsetForItemsInCollectionView:_cv];
		}

		NSUInteger count = _cv.contentArray.count;
		for (NSInteger i=0; i<count; i++)
			{
			if (self.isCancelled)
				return;
    
			if (group && group.itemRange.location == i)
				{
				if (x != startingX)
					{
					numberOfRows++;
					colIndex = 0;
					y += H;
					}

				y += _cv.groupHeaderHeight;
				x = startingX;
				}

			AZCVLayoutItem *item = AZCVLayoutItem.new;
			item.itemIndex = i;
			if (!group.isCollapsed)
				{
				if (x + W > NSMaxX(visibleRect))
					{
					numberOfRows++;
					colIndex = 0;
					y += H;
					x  = startingX;
					}
				item.colIndex = colIndex;
				item.itemRect = NSMakeRect(x, y, W, H);
				x += W + gap;
				colIndex++;
				}
			else
				item.itemRect = NSMakeRect(-W*2, y, W, H);

		item.itemContentRect = NSInsetRect(item.itemRect,
										   inset.width,
										   inset.height);
		item.rowIndex = numberOfRows;
		[newLayouts addObject:item];
    
		if (_layoutCallBack != nil)
			{
			dispatch_async(dispatch_get_main_queue(),
				^{
				self.layoutCallBack(item);
				});
			}

		if (group.itemRange.location + group.itemRange.length-1 == i)
			group = groupEnum.nextObject;
		}

	numberOfRows = MAX(numberOfRows, _cv.groups.count);
	if ((_cv.contentArray.count > 0) && (numberOfRows == -1))
		numberOfRows = 1;
  
	if (!self.isCancelled)
		{
		dispatch_async(dispatch_get_main_queue(),
			^{
			[self.cv.layoutManager setItemLayouts:newLayouts];
			self.layoutCompletion();
			});
		}
	}

@end
