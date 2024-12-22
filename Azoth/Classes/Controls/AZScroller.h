//
//  AZScroller.h
//  Azoth
//
//  Created by Simon Gornall on 12/21/24.
//

#import <Azoth/Azoth.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZScroller : AZControl
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame;

@property(assign, nonatomic) double								knobProportion;
@end

NS_ASSUME_NONNULL_END
