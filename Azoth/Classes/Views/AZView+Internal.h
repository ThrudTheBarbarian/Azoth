//
//  AZView+Internal.h
//  Azoth
//
//  Created by Simon Gornall on 12/11/24.
//

#import <Foundation/Foundation.h>


#ifndef AZView_Internal_h
#define AZView_Internal_h

union SDL_Event;


@interface AZView(Internal)

// MARK: Event handling

/*****************************************************************************\
|* Events : handle the mouse-based events, using the view-coords to determine
|* 			which view gets to see the event
\*****************************************************************************/
- (BOOL) processMouseEvent:(union SDL_Event *)event atPoint:(NSPoint)p;


/*****************************************************************************\
|* Rendering: Install a SDL_Texture as backing for the view.
\*****************************************************************************/
- (BOOL) _installBackingTexture;

/*****************************************************************************\
|* Rendering: Render the texture to the screen.
\*****************************************************************************/
- (void) _render;


@end

#endif /* AZView_Internal_h */
