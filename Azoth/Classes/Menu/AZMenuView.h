//
//  AZMenuView.h
//  Azoth
//
//  Created by Simon Gornall on 12/18/24.
//

#import <Azoth/AZTypes.h>
#import <Azoth/AZView.h>

NS_ASSUME_NONNULL_BEGIN

@class AZMenu;


@interface AZMenuView : AZView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithMenu:(AZMenu *)menu andSize:(AZMenuSize)size;

/*****************************************************************************\
|* Measure a menu to figure out its frame
\*****************************************************************************/
+ (AZMenuSize) measureMenu:(AZMenu *)menu withFlags:(int)flags;

/*****************************************************************************\
|* Configure the event-sink
\*****************************************************************************/
- (void) setupEventSink;

@property(strong, nonatomic) AZMenu *								menu;
@property(strong, nonatomic) MenuDoneBlock 							call;
@end

NS_ASSUME_NONNULL_END
