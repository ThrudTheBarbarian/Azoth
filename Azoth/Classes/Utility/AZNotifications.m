//
//  AZNotifications.m
//  Azoth
//
//  Created by Simon Gornall on 12/15/24.
//

#import "AZNotifications.h"

NSString *const AZApplicationWillLaunch 					= @"AZ:WillLaunch";
NSString *const AZApplicationDidFinishLaunching 			= @"AZ:DidLaunch";

NSString *const AZRootViewWillResizeNotification 			= @"AZ:ResizeRootView";
NSString *const AZViewFrameDidChangeNotification 			= @"AZ:FrameResized";
NSString *const AZViewBoundsDidChangeNotification 			= @"AZ:BoundsResized";

NSString *const AZPopUpButtonWillPopUpNotification 			= @"AZ:PopupWillShow";

NSString *const AZRadioButtonPressedNotification 			= @"AZ:RadioButtonPressed";

NSString *const AZSplitViewDidResizeSubviewsNotification 	= @"AZ:SplitviewDidResize";
NSString *const AZSplitViewWillResizeSubviewsNotification 	= @"AZ:SplitviewWillResize";

NSString *const AZTableViewSelectionIsChangingNotification	= @"AZ:TvSelIsChanging";
NSString *const AZTableViewSelectionDidChangeNotification 	= @"AZ:TvSelDidChange";
NSString *const AZTableViewColumnDidMoveNotification 		= @"AZ:TvColDidMove";
NSString *const AZTableViewColumnDidResizeNotification 		= @"AZ:TvColDidResize";

NSString *const AZTextDidEndEditingNotification				= @"AZ:TextEndEdit";


NSString *const AZOutlineViewItemWillExpandNotification		= @"AZ:OVItemWillExpand";
NSString *const AZOutlineViewItemDidExpandNotification		= @"AZ:OVItemDidExpand";
NSString *const AZOutlineViewItemWillCollapseNotification	= @"AZ:OVItemWillCollapse";
NSString *const AZOutlineViewItemDidCollapseNotification	= @"AZ:OVItemDidCollapse";;

NSString *const AZOutlineViewColumnDidResizeNotification	= @"AZ:OVColumnDidResize";;

NSString *const AZOutlineViewSelectionDidChangeNotification	= @"AZ:OVSelectionDidChange";
NSString *const AZOutlineViewSelectionIsChangingNotification= @"AZ:OVSelectionChanging";
