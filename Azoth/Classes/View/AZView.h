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
#import <Azoth/AZResponder.h>
#import <Azoth/AZTypes.h>


/*****************************************************************************\
|* Declare the types we're using from SDL3, because we can't import the
|* header file and keep framework modularity
\*****************************************************************************/
struct SDL_Window;
struct SDL_Mutex;

@class AZClipView;
@class AZColour;
@class AZPainter;
@class AZScrollView;
@class AZTransform;
@class AZWindow;

NS_ASSUME_NONNULL_BEGIN

@interface AZView : AZResponder

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame;
+ (AZView *) viewWithFrame:(NSRect)frame;


// MARK: scrolling

/*****************************************************************************\
|* Scroll a view within an enclosing scrollview until the rect is visible
\*****************************************************************************/
- (BOOL) scrollRectToVisible:(NSRect)rect;

/*****************************************************************************\
|* Find the closest scrollview upwards in the hierarchy
\*****************************************************************************/
- (nullable AZScrollView *)enclosingScrollView;

/*****************************************************************************\
|* Find an enclosing clipview
\*****************************************************************************/
-(nullable AZClipView *) enclosingClipView;

/*****************************************************************************\
|* Scroll a view within an enclosing scrollview until the point is visible
\*****************************************************************************/
-(void)scrollPoint:(NSPoint)point;

// MARK: View processing and redraw

/*****************************************************************************\
|* Called by a top-level contentView, check if any of the subviews needs
|* to be redrawn to their backing textures. Note that the contentView
|* itself will always be fully drawn first, so no need to check that one
\*****************************************************************************/
- (void) redrawSubViewsIfNecessary;

/*****************************************************************************\
|* Add a subview to the current view
\*****************************************************************************/
- (BOOL) addSubview:(AZView *)view;
- (BOOL) addSubview:(AZView *)view after:(AZView *)other;
- (BOOL) addSubview:(AZView *)view before:(nullable AZView *)other;

/*****************************************************************************\
|* Tell the view it needs to redraw itself. Will happen on the next render-pass
\*****************************************************************************/
- (void) setNeedsDisplay:(BOOL)yn;
- (void) setNeedsDisplayInRect:(NSRect)rect;

/*****************************************************************************\
|* What to override in subclasses to get a view to draw. This renders into the
|* local texture, so is at (0,0) wrt to that texture. Pixel positioning ought
|* to be perfectly aligned
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter;

/*****************************************************************************\
|* Remove a view from its superview
\*****************************************************************************/
- (void) removeFromSuperview;

/*****************************************************************************\
|* Set the frame origin and size
\*****************************************************************************/
- (void) setFrameOrigin:(NSPoint)p;
- (void) setFrameSize:(NSSize)s;

/*****************************************************************************\
|* Set the bounds origin and size
\*****************************************************************************/
-(void)setBoundsSize:(NSSize)size;
-(void)setBoundsOrigin:(NSPoint)origin;

/*****************************************************************************\
|* Called on a view when it resizes
\*****************************************************************************/
- (void) didResizeFrom:(NSRect)oldFrame;

/*****************************************************************************\
|* Return the size of the texture to create. This is used when the view could
|* possibly grow outside of the size-limit of a GPU texture - eg when inside
|* an enormous scrollview. In that instance, it ought to implement the clipView
|* delegate -scrollToPoint:(NSPoint) to get where it is "scrolled" to, and
|* handle drawing specially with a window-sized texture rather than a backing-
|* sized texture. By default this method just returns the view's frame.size.
|*
|* The companion method is -(BOOL)directRendering which turns off the view
|* translation and will always render from 0,0->W,H (where W,H are taken from
|* -(NSSize)textureSize. The default return from this method is NO
\*****************************************************************************/
- (NSSize) textureSize;
- (BOOL) directRendering;

/*****************************************************************************\
|* Determine if this, or any view further up the view hierarchy, is hidden
\*****************************************************************************/
-(BOOL)isHiddenOrHasHiddenAncestor;

// MARK: Event manipulation

/*****************************************************************************\
|* Determine if we even want mouse events. This allows a subview to limit its
|* control of the event. By default we answer unconditional YES
\*****************************************************************************/
- (BOOL) hitTestAtPoint:(NSPoint)p;

/*****************************************************************************\
|* Convert a point from another view's co-ordinate system to our own. Calling
|* this with nil will convert from window co-ordinates. The view must be in
|* the superview-hierarchy otherwise.
\*****************************************************************************/

- (NSPoint) convertPoint:(NSPoint)p1 fromView:(nullable AZView *)otherView;
/*****************************************************************************\
|* Convenience method to do the same for a rect. Basically just do the origin
|* and leave the size alone
\*****************************************************************************/
- (NSRect) convertRect:(NSRect)r fromView:(nullable AZView *)otherView;

/*****************************************************************************\
|* Convert a point from our own view's co-ordinate system to another. Calling
|* this with nil will convert to window co-ordinates. The view must be in
|* the superview-hierarchy otherwise.
\*****************************************************************************/
- (NSPoint) convertPoint:(NSPoint)p1 toView:(nullable AZView *)otherView;

/*****************************************************************************\
|* Convenience method to do the same for a rect. Basically just do the origin
|* and leave the size alone
\*****************************************************************************/
- (NSRect) convertRect:(NSRect)r toView:(nullable AZView *)otherView;


/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The position and size of the view in its parent
@property(assign, nonatomic) NSRect 						frame;

// The position and size of the view's local co-ordinates
@property(assign, nonatomic) NSRect							bounds;

// The list of all views that are children to this view
@property(strong, nonatomic) NSMutableArray<AZView *> *		subviews;

// The view that this view is a child of, or nil
// for contentView
@property(strong, nonatomic, nullable) AZView *				superview;

// The window that this view is attached to
@property(assign, nonatomic, nullable) AZWindow	*			window;

// Backing texture-id for drawing into
@property(assign, nonatomic) NSInteger						bg;

// Aggregated dirty-rect (where needs to be redrawn)
@property(assign, nonatomic) NSRect 						dirty;

// Background colour if nothing else supplied to draw
@property(strong, nonatomic) AZColour *						backgroundColour;

// Is this view opaque - affects the blending mode,
// default is NO
@property(assign, nonatomic) BOOL							isOpaque;

// Does this view resize its subviews on having its
// frame set, default is YES
@property(assign, nonatomic) BOOL							autoresizesSubviews;

// The visible part of the view
@property(assign, nonatomic) NSRect 						visibleRect;

// The bit-mask of AZAutoresizingMaskOptions that defines
// how auto-resizing will work
@property(assign, nonatomic) enum AZAutoresizingMaskOptions	autoresizingMask;

// Backing texture mutex. Taken when the backing texture
// is swapped out, and also when rendering using it.
@property(assign, nonatomic) struct SDL_Mutex *				textureMutex;

// Whether the view is hidden (not displayed)
@property(assign, nonatomic) BOOL							hidden;

// Post notifications when the frame is changed
@property(assign, nonatomic) BOOL						postFrameNotifications;

// Post notifications when the bounds are changed
@property(assign, nonatomic) BOOL						postBoundsNotifications;
@end

NS_ASSUME_NONNULL_END
