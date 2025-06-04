//
//  AZView.h
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
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

#import <Azoth/AZResponder.h>
#import <Azoth/AZTypes.h>
#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>

NS_ASSUME_NONNULL_BEGIN

/*****************************************************************************\
|* Declare the types we're using from SDL3, because we can't import the
|* header file and keep framework modularity
\*****************************************************************************/
struct SDL_Window;
struct SDL_Mutex;

@class AZClipView;
@class AZColour;
@class AZDraggingItem;
@class AZDraggingSession;
@class AZImage;
@class AZPainter;
@class AZScrollView;
@class AZTransform;
@class AZWindow;
@class AZZib;

@protocol AZDraggingInfo;

/*****************************************************************************\
|* Define the source's dragging responsibilities. These are methods implemented
|* by an object that initiates a drag session. The source application is sent
|* these messages during dragging.  The first must be implemented, the others
|* are sent if the source responds to them. The dragging source is typically
|* the view itself that initiated the drag, as AZView implements this protocol
\*****************************************************************************/
@protocol AZDraggingSource <NSObject>

@required

// Declares what types of operations the source allows to be performed
- (AZDragOperation)draggingSession:(AZDraggingSession *)session
	sourceOperationMaskForDraggingContext:(AZDraggingContext)context;

@optional
// Sent when the dragging starts
- (void)draggingSession:(AZDraggingSession *)session
	   willBeginAtPoint:(NSPoint)screenPoint;

// Sent when as the dragging progresses
- (void)draggingSession:(AZDraggingSession *)session
		   movedToPoint:(NSPoint)screenPoint;

// Sent when the dragging is complete, along with the operation performed
- (void)draggingSession:(AZDraggingSession *)session
		   endedAtPoint:(NSPoint)screenPoint
		      operation:(AZDragOperation)operation;

// Returns whether modifier keys will be ignored for this session
- (BOOL)ignoreModifierKeysForDraggingSession:(AZDraggingSession *)session;

@end


/*****************************************************************************\
|* A set of methods that the destination object (or recipient) of a
|* dragged image must implement
\*****************************************************************************/
@protocol AZDraggingDestination <NSObject>

// Invoked when the dragged image enters destination bounds or frame;
// delegate returns dragging operation to perform
- (AZDragOperation) draggingEntered:(id<AZDraggingInfo>) sender;

// Asks the destination object whether it wants to receive periodic
// draggingUpdated: messages
- (BOOL) wantsPeriodicDraggingUpdates;

// Invoked periodically as the image is held within the destination area,
// allowing modification of the dragging operation or mouse-pointer position
- (AZDragOperation) draggingUpdated:(id<AZDraggingInfo>) sender;

// Invoked when the dragged image exits the destination’s bounds rectangle
- (void) draggingExited:(id<AZDraggingInfo>) sender;

// Called when a drag operation ends
- (void) draggingEnded:(id<AZDraggingInfo>) sender;
@end

@interface AZView : AZResponder 	<AZDraggingSource,
								 AZDraggingDestination>

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame;
+ (AZView *) viewWithFrame:(NSRect)frame;

/*****************************************************************************\
|* Purge the texture. Shouldn't be needed but sometimes the dealloc() doesn't
|* seem to be called even if retainCount == 0
\*****************************************************************************/
- (void) purge;

/*****************************************************************************\
|* Configuration via dictionary. This is called by the NIB loader, but is a
|* valid way to create the view
\*****************************************************************************/
- (instancetype) initWithDictionary:(NSDictionary *)info;

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
|* Not normally necessary, but allow a forced rebuild of the transforms to
|* and from the window co-ordinate space
\*****************************************************************************/
- (void) rebuildTransforms;


/*****************************************************************************\
|* The mouse has entered the view, default behaviour is to change the pointer
\*****************************************************************************/
- (void) mouseEntered:(AZEvent *)event;

/*****************************************************************************\
|* The mouse has exited the view
\*****************************************************************************/
- (void) mouseExited:(AZEvent *)event;


// MARK: Drag and drop

/*****************************************************************************\
|* Initiate a dragging session
\*****************************************************************************/
- (nullable AZDraggingSession *)
beginDraggingSessionWithItems:(NSArray<AZDraggingItem *> *) items
						event:(AZEvent *) event
					   source:(id<AZDraggingSource>) source;

/*****************************************************************************\
|* Register this view as having an interest in a bunch of drag-types
\*****************************************************************************/
- (void) registerForDraggedTypes:(NSArray<NSString *> *) newTypes;

/*****************************************************************************\
|* We got a mouse-release in an acceptable drop-target, prepare for the actual
|* drop
\*****************************************************************************/
- (BOOL) prepareForDragOperation:(id<AZDraggingInfo>) sender;

/*****************************************************************************\
|* Do the actual drop, sent if the -prepareForDragOperation returns YES
\*****************************************************************************/
- (BOOL) performDragOperation:(id<AZDraggingInfo>) sender;

/*****************************************************************************\
|* And handle the drop completing, sent if -performDragOperation returns YES
\*****************************************************************************/
- (void) concludeDragOperation:(id<AZDraggingInfo>) sender;

// MARK: End of methods


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
@property(weak, nonatomic, nullable) AZWindow	*			window;

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
@property(assign, nonatomic) BOOL						postsFrameNotifications;

// Post notifications when the bounds are changed
@property(assign, nonatomic) BOOL						postsBoundsNotifications;

// Property from IB, just a numeric identifier
@property (assign, nonatomic) NSInteger 					tag;

// Property from IB, justfor compatibility right now
@property (copy, nonatomic) NSString * 						tooltip;

// A set of drag-types that we have registered interest in
@property (strong, nonatomic) NSSet<NSString *> * 			dragTypes;

// Create and return an image from the view's backing
// texture
@property (strong, nonatomic) AZImage *						backingImage;

// The cursor to use in this view
@property (assign, nonatomic) SDL_Cursor *					mouseCursor;

@end

NS_ASSUME_NONNULL_END
