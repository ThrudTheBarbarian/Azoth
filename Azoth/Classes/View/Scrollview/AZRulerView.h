//
//  AZRulerView.h
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <Azoth/AZView.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

@class AZScrollView;

@interface AZRulerView : AZView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithScrollView:(AZScrollView *) scrollView
                        orientation:(AZRulerOrientation) orientation;

/*****************************************************************************\
|* Tell the ruler it needs to recalculate the hash marks
\*****************************************************************************/
- (void) invalidateHashMarks;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The orientation of this ruler
@property(assign, nonatomic) AZRulerOrientation				orientation;

// The scroll view that this ruler is attached to
@property(weak, nonatomic) AZScrollView *					scrollView;

// Space needed to draw the horizontal ruler
@property(assign, nonatomic) float							requiredThickness;
@end

NS_ASSUME_NONNULL_END
