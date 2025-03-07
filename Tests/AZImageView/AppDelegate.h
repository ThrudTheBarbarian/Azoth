//
//  AppDelegate.h
//  AZImageView
//
//  Created by ThrudTheBarbarian on 12/30/24.
//

#import <Azoth/Azoth.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate : AZAppDelegate <AZAppDelegate>

@property (strong, nonatomic) AZImage *				small;
@property (strong, nonatomic) AZImage *				medium;
@property (strong, nonatomic) AZImage *				large;
@end

NS_ASSUME_NONNULL_END
