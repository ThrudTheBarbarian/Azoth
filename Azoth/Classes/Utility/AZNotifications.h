//
//  AZNotifications.h
//  Azoth
//
//  Created by Simon Gornall on 12/15/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const AZApplicationWillLaunch;
extern NSString * const AZApplicationDidFinishLaunching;

extern NSString * const AZRootViewWillResizeNotification;
extern NSString * const AZViewFrameDidChangeNotification;
extern NSString * const AZViewBoundsDidChangeNotification;

extern NSString * const AZPopUpButtonWillPopUpNotification;

extern NSString * const AZRadioButtonPressedNotification;

extern NSString * const AZSplitViewWillResizeSubviewsNotification;
extern NSString * const AZSplitViewDidResizeSubviewsNotification;

extern NSString * const AZTableViewSelectionWillChangeNotification;
extern NSString * const AZTableViewSelectionIsChangingNotification;
extern NSString * const AZTableViewSelectionDidChangeNotification;
extern NSString * const AZTableViewColumnDidMoveNotification;
extern NSString * const AZTableViewColumnDidResizeNotification;

extern NSString * const AZTextDidEndEditingNotification;

extern NSString *const AZOutlineViewItemWillExpandNotification;
extern NSString *const AZOutlineViewItemDidExpandNotification;
extern NSString *const AZOutlineViewItemWillCollapseNotification;
extern NSString *const AZOutlineViewItemDidCollapseNotification;

extern NSString *const AZOutlineViewColumnDidMoveNotification;
extern NSString *const AZOutlineViewColumnDidResizeNotification;

extern NSString *const AZOutlineViewSelectionDidChangeNotification;
extern NSString *const AZOutlineViewSelectionIsChangingNotification;

extern NSString *const AZImageViewDidReceiveDropNotification;

NS_ASSUME_NONNULL_END
