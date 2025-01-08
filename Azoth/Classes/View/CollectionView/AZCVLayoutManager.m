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


@end
