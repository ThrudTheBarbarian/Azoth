//
//  AZAppDelegate.h
//  Azoth
//
//  Created by Simon Gornall on 12/14/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AZAppDelegate <NSObject>

@optional

// Called when the application object is fully set up, and is about to
// start the main loop
- (void) applicationDidFinishLaunching:(NSNotification *)notification;

// Called halfway through setup, before fonts are created, so the
// delegate can change them etc.
- (void) applicationWillLaunch:(NSNotification *)notification;

@end

NS_ASSUME_NONNULL_END
