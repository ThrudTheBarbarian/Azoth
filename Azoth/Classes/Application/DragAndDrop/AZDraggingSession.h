//
//  AZDraggingSession.h
//  Azoth
//
//  Created by Simon Gornall on 1/9/25.
//

#import <Foundation/Foundation.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

@class AZDraggingItem;
@class AZDraggingSession;
@class AZEventSink;

@protocol AZDraggingSource;

/*****************************************************************************\
|* This is the object returned when a view requests a drag operation to begin
\*****************************************************************************/
@interface AZDraggingSession : NSObject


/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The DraggingSource for this session
@property(weak, nonatomic) id<AZDraggingSource>					source;

// Whether the drag has started yet
@property(assign, nonatomic) BOOL								dragStarted;

// The event-sink managing where events get routed
@property(strong, nonatomic) AZEventSink *						sink;

// The dragging operation
@property(assign, nonatomic) AZDragOperation					operation;

// The list of dragging items
@property(strong, nonatomic) NSArray<AZDraggingItem *> *		items;

// The point where dragging started
@property(assign, nonatomic) NSPoint 							start;

// The mouse position now
@property(assign, nonatomic) NSPoint 							at;

@end

NS_ASSUME_NONNULL_END
