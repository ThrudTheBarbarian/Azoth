//
//  AppDelegate.h
//  AZOutline
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <Azoth/Azoth.h>

@interface AppDelegate : AZAppDelegate <AZAppDelegate,
										AZOutlineViewDelegate,
										AZOutlineViewDataSource>


@property(strong) IBOutlet AZOutlineView *ov;
@property(strong) IBOutlet AZTableView *tv;
@end

