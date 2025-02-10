//
//  AZView+Internal.h
//  Azoth
//
//  Created by Simon Gornall on 12/11/24.
//

#import <Foundation/Foundation.h>


#ifndef AZView_Internal_h
#define AZView_Internal_h

NS_ASSUME_NONNULL_BEGIN

@class AZClipView;
@class AZEvent;


@interface AZView(Internal)

// MARK: Event handling

/*****************************************************************************\
|* Events : handle the mouse-based events, using the view-coords to determine
|* 			which view gets to see the event
\*****************************************************************************/
- (BOOL) processMouseEvent:(AZEvent *)event depth:(NSInteger)depth;

/*****************************************************************************\
|* Rendering: Install a texture as backing for the view.
\*****************************************************************************/
- (BOOL) _installBackingTexture;

/*****************************************************************************\
|* Called by the painter before it draws the view, to ensure there's a
|* backing texture in place
\*****************************************************************************/
- (void) _installBackingTextureIfNecessary;

/*****************************************************************************\
|* Rendering: Render the texture to the screen.
\*****************************************************************************/
- (void) _renderToScreen;

/*****************************************************************************\
|* Rendering: Render view and all subviews.
\*****************************************************************************/
- (void) _render;

/*****************************************************************************\
|* Update the current view and then all its subviews in-order
\*****************************************************************************/
- (void) _redrawViewAndSubviews;

/*****************************************************************************\
|* Actually draw the dirty-rect
\*****************************************************************************/
- (void) _drawDirtyRect;

/*****************************************************************************\
|* Remove a subview
\*****************************************************************************/
- (void) _removeSubview:(AZView *)subview;

/*****************************************************************************\
|* Find the subview at a given point, in reverse order
\*****************************************************************************/
- (AZView *) _findViewAtPoint:(NSPoint)p;

@end

NS_ASSUME_NONNULL_END

#endif /* AZView_Internal_h */
