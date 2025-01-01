//
//  AZOutlineItemView.h
//  Azoth
//
//  Created by Simon Gornall on 12/31/24.
//

// The AZOutlineItemView expects to move the supplied view around inside
// itself to:
//
//  - Provide a space on the right to show/action a disclosure triangle
//  - embed space on the left to indicate the level of the item
//
// The embedded view's frame will be set commensurately.

#import <Azoth/AZControl.h>

typedef enum
	{
	AZOutlineViewItemNothing	= 0,
	AZOutlineViewItemSelected	= 1,
	AZOutlineViewItemDisclosed	= 2
	} AZOutlineItemViewReason;



@class AZOutlineView;

NS_ASSUME_NONNULL_BEGIN

@interface AZOutlineItemView : AZControl

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithView:(AZView *)view andFrame:(NSRect)frame;
+ (AZOutlineItemView *) itemViewWithView:(AZView *)view andFrame:(NSRect)frame;

/*****************************************************************************\
|* Reconfigure with an indentation
\*****************************************************************************/
- (void) indentBy:(float)indent;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Whether the item for this view is already open
// (ie: showing children)
@property(assign, nonatomic) BOOL								isOpen;

// Whether the item for this view has children
@property(assign, nonatomic) BOOL								hasChildren;

// The item for this view, used to tell the
// outlineView which item has changed on mousedown
@property(strong, nonatomic) NSObject *							item;

// The outlineview we are attached to
@property(strong, nonatomic) AZOutlineView *					outlineView;

// The width we prefer to have, generally the initial
// width set on the frame
@property(assign, nonatomic) float								preferredWidth;

// The reason why we sent a target/action message
@property(assign, nonatomic) AZOutlineItemViewReason			reason;

// Whether we should render as selected
@property(assign, nonatomic) BOOL								selected;
@end

NS_ASSUME_NONNULL_END
