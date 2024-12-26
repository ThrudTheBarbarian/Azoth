//
//  AZClipView.h
//  Azoth
//
//  Created by Simon Gornall on 12/22/24.
//

#import <Azoth/AZView.h>

NS_ASSUME_NONNULL_BEGIN

struct SDL_MouseMotionEvent;

@interface AZClipView : AZView

/*****************************************************************************\
|* Return the visible rect, in the document view co-ords, of the document view
\*****************************************************************************/
-(NSRect)documentVisibleRect;

/*****************************************************************************\
|* Make sure the scroll point is within bounds
\*****************************************************************************/
-(NSPoint)constrainScrollPoint:(NSPoint)point;

/*****************************************************************************\
|* Autoscroll on a drag within the scrollview
\*****************************************************************************/
- (BOOL) autoscroll:(struct SDL_MouseMotionEvent *)e;

/*****************************************************************************\
|* Scroll the document view to a given point
\*****************************************************************************/
-(void)scrollToPoint:(NSPoint)point;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Do we do a copy or a redraw on scroll ?
@property(assign, nonatomic) BOOL								copiesOnScroll;

// Whether to draw the background. Not sure if we need this or
// if we can rely on the opaque property...
@property(assign, nonatomic) BOOL								drawsBackground;

// The document view that the clipview clips
@property(strong, nonatomic) AZView *							documentView;

// Where we are currently scrolled to
@property(assign, nonatomic, readonly) NSPoint					scrollPoint;
@end

NS_ASSUME_NONNULL_END
