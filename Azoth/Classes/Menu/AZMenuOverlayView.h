//
//  AZMenuOverlayView.h
//  Azoth
//
//  Created by Simon Gornall on 12/18/24.
//

#import <Azoth/AZView.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZMenuOverlayView : AZView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame;

/*****************************************************************************\
|* Run a popup menu
\*****************************************************************************/
- (BOOL) runMenuFor:(AZMenuItem *)item at:(NSPoint)p;

@end

NS_ASSUME_NONNULL_END
