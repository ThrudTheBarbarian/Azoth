//
//  AZDraggingSession.h
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <Foundation/Foundation.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

@class AZDraggingItem;
@class AZDraggingSession;
@class AZEventSink;
@class AZPasteboard;
@class AZView;
@class AZWindow;

@protocol AZDraggingSource;

/*****************************************************************************\
|* A set of methods that supply information about a dragging session
\*****************************************************************************/
@protocol AZDraggingInfo <NSObject>

// The number of valid items for a drop operation
@property(assign, readonly) NSInteger 					numberOfValidItemsForDrop;

// The destination window for the dragging operation
@property(strong, readonly) AZWindow * 					draggingDestinationWindow;

// The current location of the mouse pointer in the
// base coordinate system of the destination object’s
// window. We only support in-window dragging atm,
// so the co-rds are always relevant to all views
@property (readonly) NSPoint 								draggingLocation;

// The current location of the dragged image’s origin,
// in the base coordinate system of the destination
// object’s window.
@property (readonly) NSPoint 								draggedImageLocation;

// Information about the dragging operation and
// the data it contains
@property (readonly) AZDragOperation 						draggingSourceOperationMask;

// The source, or owner, of the dragged data
@property (readonly) id<AZDraggingSource> 				draggingSource;

// A number that uniquely identifies the dragging session
@property (readonly) NSInteger 							draggingSequenceNumber;

// The dragging operation that is ultimately performed
// utilizes this pasteboard
@property (readonly) AZPasteboard * 						draggingPasteboard;
@end

/*****************************************************************************\
|* This is the object returned when a view requests a drag operation to begin
\*****************************************************************************/
@interface AZDraggingSession : NSObject <AZDraggingInfo>

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithWindow:(AZWindow *)window;


/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The DraggingSource for this session
@property(weak, nonatomic) id<AZDraggingSource>			source;

// Whether the drag has started yet
@property(assign, nonatomic) BOOL						dragStarted;

// The event-sink managing where events get routed
@property(strong, nonatomic) AZEventSink *				sink;

// The dragging operation
@property(assign, nonatomic) AZDragOperation			operation;

// The list of dragging items
@property(strong, nonatomic)
NSArray<AZDraggingItem *> *								items;

// The point where dragging started
@property(assign, nonatomic) NSPoint 					start;

// The mouse position now
@property(assign, nonatomic) NSPoint 					at;

// The last view we were dragged over
@property(strong, nonatomic, nullable) AZView *			lastView;

// The last time we informed a view that it had
// been dragged over
@property(strong, nonatomic, nullable) NSDate *			lastUpdate;

// The dragging response back from the view
@property(assign, nonatomic) AZDragOperation			response;
@end

NS_ASSUME_NONNULL_END
