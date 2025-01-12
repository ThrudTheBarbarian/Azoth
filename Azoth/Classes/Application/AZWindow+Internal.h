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
@class AZView;

@protocol AZDraggingSource;

@interface AZWindow (Internal)


/*****************************************************************************\
|* Initiate a dragging session
\*****************************************************************************/
- (nullable AZDraggingSession *)
		_beginDraggingSessionWithItems:(NSArray<AZDraggingItem *> *) items
								 event:(AZEvent *) event
								source:(id<AZDraggingSource>) source;

/*****************************************************************************\
|* Inform the window which view we're currently dragging over the top of
\*****************************************************************************/
- (void) _draggedOverView:(AZView *)view;
@end

NS_ASSUME_NONNULL_END
