//
//  AppDelegate.h
//  NibTest
//
//  Created by ThrudTheBarbarian on 1/1/25.
//

#import <Azoth/Azoth.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate : AZAppDelegate <AZAppDelegate,
										AZTableViewDelegate,
										AZTableViewDataSource,
										AZOutlineViewDelegate,
										AZOutlineViewDataSource>

@property(strong) IBOutlet AZOutlineView *ov;
@property(strong) IBOutlet AZTableView *tv;
@end

NS_ASSUME_NONNULL_END
