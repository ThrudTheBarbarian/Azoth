//
//  AZView+Internal.h
//  Azoth
//
//  Created by Simon Gornall on 12/11/24.
//

#import <Foundation/Foundation.h>


#ifndef AZView_Internal_h
#define AZView_Internal_h

@class AZEvent;


@interface AZView(Internal)

// MARK: Event handling

/*****************************************************************************\
|* Events : handle the mouse-based events, using the view-coords to determine
|* 			which view gets to see the event
\*****************************************************************************/
- (BOOL) processMouseEvent:(AZEvent *)event;

/*****************************************************************************\
|* Rendering: Install a SDL_Texture as backing for the view.
\*****************************************************************************/
- (BOOL) _installBackingTexture;

/*****************************************************************************\
|* Rendering: Render the texture to the screen.
\*****************************************************************************/
- (void) _renderToScreen;

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

@end

#endif /* AZView_Internal_h */
