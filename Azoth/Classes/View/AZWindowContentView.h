//
//  AZWindowContentView.h
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <Azoth/AZView.h>

NS_ASSUME_NONNULL_BEGIN

@class AZDraggingSession;

@interface AZWindowContentView : AZView


/*****************************************************************************\
|* Initialisation: Create with a window
\*****************************************************************************/
- (instancetype) initWithWindow:(AZWindow *)window;

/*****************************************************************************\
|* Convenience initialiser
\*****************************************************************************/
+ (instancetype) withWindow:(AZWindow *)window;

/*****************************************************************************\
|* Represent the current dragging session
\*****************************************************************************/
- (void) showDragInProgress;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// If we are doing a drag-and-drop operation, this session will
// be non-nil
@property(strong, nonatomic, nullable) AZDraggingSession *				drag;
@end

NS_ASSUME_NONNULL_END
