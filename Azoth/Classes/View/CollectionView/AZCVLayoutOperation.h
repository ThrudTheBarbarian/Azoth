//
//  AZCVLayoutOperation.h
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AZCollectionView;
@class AZCVLayoutItem;

/*****************************************************************************\
|* Define the iterator block-type
\*****************************************************************************/
typedef void(^AZCVLayoutOperationIterator) (AZCVLayoutItem *layoutItem);



@interface AZCVLayoutOperation : NSOperation

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The iterator callback block
@property (copy, nonatomic) AZCVLayoutOperationIterator 	layoutCallBack;

// The completion block
@property (copy, nonatomic) dispatch_block_t 				layoutCompletion;

// The collection view to operatove over
@property (weak, nonatomic) AZCollectionView *				cv;

@end

NS_ASSUME_NONNULL_END
