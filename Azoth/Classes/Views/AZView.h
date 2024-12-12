//
//  AZView.h
//  Azoth
//
//  Created by Simon Gornall on 12/11/24.
//

/*****************************************************************************\
|* AZView is the base-class for any region of the screen that wants to
|* participate in either drawing to the screen or receiving input events on
|* a position-basis.
|*
|* The window has a toplevel view, and all views are in some child-relationship
|* with that top-level view. The toplevel ("contentView") always covers the
|* entire window, though child views can have any dimension
|*
|* The deeper the view is in the hierarchy, the sooner it gets to respond to
|* input events, and deeper views render over views higher up in the hierarchy,
|* so in the view tree below:
|*
|* Window -> ContentView -> View A -> View B
|*
|* The views will be drawn in the order {contentView, A, B}, and views will be
|* asked if they want to respond to an event in the order {B, A, contentView}
\*****************************************************************************/

#import <Foundation/Foundation.h>

struct SDL_Window;

NS_ASSUME_NONNULL_BEGIN

@class AZRect;

@interface AZView : NSObject
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(AZRect*)frame;
+ (AZView *) viewWithFrame:(AZRect *)frame;


/*****************************************************************************\
|* Return the contentView for any given SDL_Window. If one does not exist it
|* will be created and returned
\*****************************************************************************/
+ (AZView *) contentViewForWindow:(struct SDL_Window *)window;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The position and size of the view in its parent
@property(strong, nonatomic) AZRect * 		frame;

// The position and size of the view's local co-ordinate space
@property(strong, nonatomic) AZRect	*		bounds;
@end

NS_ASSUME_NONNULL_END
