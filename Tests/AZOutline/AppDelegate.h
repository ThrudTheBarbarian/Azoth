//
//  AppDelegate.h
//  AZOutline
//
//  Created by Simon Gornall on 12/31/24.
//

#import <Azoth/Azoth.h>

@interface AppDelegate : AZAppDelegate <AZAppDelegate,
										AZOutlineViewDelegate,
										AZOutlineViewDataSource>


@property(strong) IBOutlet AZOutlineView *ov;
@property(strong) IBOutlet AZTableView *tv;
@end

