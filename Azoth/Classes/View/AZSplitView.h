//
//  AZSplitView.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 12/24/24.
//

#import <Azoth/AZView.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZSplitView : AZView
/*****************************************************************************\
|* Lay out the subviews, called after conformational change
\*****************************************************************************/
- (void)adjustSubviews;

/*****************************************************************************\
|* Thickness of the divider, based on type
\*****************************************************************************/
- (float)dividerThickness;

/*****************************************************************************\
|* Determine if a subview has completely collapsed
\*****************************************************************************/
- (BOOL)isSubviewCollapsed:(AZView *)subview;

/*****************************************************************************\
|* Get the minimum or maximum possible position of a divider
\*****************************************************************************/
//- (float)minPossiblePositionOfDividerAtIndex:(int)index;
//- (float)maxPossiblePositionOfDividerAtIndex:(int)index;

/*****************************************************************************\
|* Set the position of a divider
\*****************************************************************************/
- (void)setPosition:(float)position ofDividerAtIndex:(NSInteger)index;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The delegate for the splitview
@property(strong, nonatomic) NSObject *							delegate;

// Whether we're vertical or horizontal
@property(assign, nonatomic) BOOL								isVertical;

// Which type of divider
@property(assign, nonatomic) AZSplitViewDividerStyle			dividerStyle;
@end


// MARK: Delegate interface



@interface NSObject (AZSplitView_delegate)
/*****************************************************************************\
|* Whether a splitview _can_ be collapsed
\*****************************************************************************/
- (BOOL)splitView:(AZSplitView *)sv canCollapseSubview:(AZView *)subview;

/*****************************************************************************\
|* Whether a splitview _should_ be collapsed
\*****************************************************************************/
- (BOOL)splitView:(AZSplitView *)sv
		shouldCollapseSubview:(AZView *)subview
		forDoubleClickOnDividerAtIndex:(int)index;

/*****************************************************************************\
|* Constrain the minimum or maximum co-ord of a divider
\*****************************************************************************/
- (CGFloat)splitView:(AZSplitView *)sv
		   constrainMinCoordinate:(float)proposedMinimumPosition
		   ofSubviewAt:(NSInteger)index;

- (CGFloat)splitView:(AZSplitView *)sv
		   constrainMaxCoordinate:(float)proposedMaximumPosition
		   ofSubviewAt:(NSInteger)index;

/*****************************************************************************\
|* Constrain the split position of a divider
\*****************************************************************************/
- (float)splitView:(AZSplitView *)sv
		 constrainSplitPosition:(float)position
		 ofSubviewAt:(NSInteger)index;

/*****************************************************************************\
|* Handle resizing
\*****************************************************************************/
- (void)splitView:(AZSplitView *)sv resizeSubviewsWithOldSize:(NSSize)size;

/*****************************************************************************\
|* Whether we _should_ adjust the size of a subview
\*****************************************************************************/
- (BOOL)splitView:(AZSplitView *)sv shouldAdjustSizeOfSubview:(AZView *)view;

/*****************************************************************************\
|* Whether we should hide the divider specified
\*****************************************************************************/
- (BOOL)splitView:(AZSplitView *)sv shouldHideDividerAtIndex:(int)index;

/*****************************************************************************\
|* Figure out drawing constraints
\*****************************************************************************/
- (NSRect)splitView:(AZSplitView *)sv
		  effectiveRect:(NSRect)proposedEffectiveRect
		  forDrawnRect:(NSRect)drawnRect
		  ofDividerAtIndex:(int)index;

- (NSRect)splitView:(AZSplitView *)sv
		  additionalEffectiveRectOfDividerAtIndex:(NSInteger)index;

/*****************************************************************************\
|* Handle notifications
\*****************************************************************************/
- (void)splitViewDidResizeSubviews:(NSNotification *)n;
- (void)splitViewWillResizeSubviews:(NSNotification *)n;
@end

NS_ASSUME_NONNULL_END
