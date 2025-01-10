//
//  AZDraggingSession.h
//  Azoth
//
//  Created by Simon Gornall on 1/9/25.
//

#import <Foundation/Foundation.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

@class AZDraggingSession;
@class AZEventSink;

/*****************************************************************************\
|* Define the source's dragging responsibilities. These are methods implemented
|*  by an object that initiates a drag session. The source application is sent
|* these messages during dragging.  The first must be implemented, the others
|* are sent if the source responds to them.
\*****************************************************************************/
@protocol NSDraggingSource <NSObject>

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
|* This is the object returned when a view requests a drag operation to begin
\*****************************************************************************/
@interface AZDraggingSession : NSObject


/*****************************************************************************\
|* Properties
\*****************************************************************************/
@property(strong, nonatomic) AZEventSink *						sink;
@end

NS_ASSUME_NONNULL_END
