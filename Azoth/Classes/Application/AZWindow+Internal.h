//
//  AZWindow+Internal.h
//  Azoth
//
//  Created by Simon Gornall on 12/16/24.
//

#import <Azoth/AZWindow.h>

NS_ASSUME_NONNULL_BEGIN

@class AZDraggingSession;
@class AZDraggingItem;

@protocol AZDraggingSource;

@interface AZWindow (Internal)


/*****************************************************************************\
|* Initiate a dragging session
\*****************************************************************************/
- (AZDraggingSession *)
_beginDraggingSessionWithItems:(NSArray<AZDraggingItem *> *) items
						 event:(AZEvent *) event
					    source:(id<AZDraggingSource>) source;

@end

NS_ASSUME_NONNULL_END
