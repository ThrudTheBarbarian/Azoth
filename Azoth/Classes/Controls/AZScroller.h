//
//  AZScroller.h
//  Azoth
//
//  Created by Simon Gornall on 12/21/24.
//

#import <Azoth/AZControl.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZScroller : AZControl
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame;

/*****************************************************************************\
|* Return the size of a scrollbar
\*****************************************************************************/
+ (float) scrollerWidth;

// Set/Get the proportion of the scroller extent taken up
// by the knob part
@property(assign, nonatomic) double								knobProportion;

// Is the scroller hidden
@property(assign, nonatomic) BOOL								isHidden;

// Which part of the scroller did we hit
@property(assign, nonatomic) AZScrollerPart						hitPart;
@end

NS_ASSUME_NONNULL_END
