//
//  AZScrollView.h
//  Azoth
//
//  Created by Simon Gornall on 12/22/24.
//

#import <Azoth/Azoth.h>

@class AZClipView;

NS_ASSUME_NONNULL_BEGIN

@interface AZScrollView : AZView

/*****************************************************************************\
|* Lay out the scroll view
\*****************************************************************************/
- (void)tile;

/*****************************************************************************\
|* Document view changed, make sure the scrollers update
\*****************************************************************************/
- (void)reflectScrolledClipView:(AZClipView *)clipView;

/*****************************************************************************\
|* Do we have [type] scrollers
\*****************************************************************************/
- (BOOL) hasVerticalScroller;
- (BOOL) hasHorizontalScroller;

@end

NS_ASSUME_NONNULL_END
