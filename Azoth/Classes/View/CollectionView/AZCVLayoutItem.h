//
//  AZCVLayoutItem.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/7/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AZCVLayoutItem;


@interface AZCVLayoutItem : NSObject

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Location of the item
@property (assign, nonatomic) NSInteger 						rowIndex;
@property (assign, nonatomic) NSInteger  						colIndex;
@property (assign, nonatomic) NSInteger 						itemIndex;

// Bounds of item
@property (assign, nonatomic) NSRect 							itemRect;

// Bounds of item content
@property (assign, nonatomic) NSRect							itemContentRect;

@end

NS_ASSUME_NONNULL_END
