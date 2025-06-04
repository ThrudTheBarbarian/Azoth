//
//  AZCVGroup.h
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZCVGroup : NSObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
+ (instancetype) groupWithTitle:(NSString *)title range:(NSRange)range;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The title for the group
@property(copy, nonatomic) NSString *							title;

// Define the range over which this group operates
@property(assign, nonatomic) NSRange 							itemRange;

// Is this group collapsed or not
@property(assign, nonatomic, getter=isCollapsed) BOOL 			collapsed;
@end

NS_ASSUME_NONNULL_END
