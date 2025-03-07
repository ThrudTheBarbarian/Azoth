//
//  AZTableRowRecord.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 12/27/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZTableRowRecord : NSObject
// Y co-ordinate of the row
@property (assign, nonatomic) float 							start;

// Height of the row
@property (assign, nonatomic) float 							height;
@end

NS_ASSUME_NONNULL_END
