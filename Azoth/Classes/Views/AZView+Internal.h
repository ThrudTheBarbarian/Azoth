//
//  AZView+Internal.h
//  Azoth
//
//  Created by Simon Gornall on 12/11/24.
//

#import <Foundation/Foundation.h>

#ifndef AZView_Internal_h
#define AZView_Internal_h

@interface AZView(Internal)



// MARK: Event handling

/*****************************************************************************\
|* Events : handle the mouse-based events, using the view-coords to determine
|* 			which view gets to see the event
\*****************************************************************************/
- (BOOL) processMouseEvent:(union SDL_Event *)event atPoint:(NSPoint)p;

@end

#endif /* AZView_Internal_h */
