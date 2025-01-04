//
//  AZAppDelegate.h
//  Azoth
//
//  Created by Simon Gornall on 12/14/24.
//

#import <Foundation/Foundation.h>

@class AZView;
@class AZWindow;

NS_ASSUME_NONNULL_BEGIN

/*****************************************************************************\
|* The minimum requirement is that an application-delegate implements the
|* AZAppDelegate protocol. The more normal state of affairs is that the
|* application's app-delegate inherits from the AZAppDelegate class.
\*****************************************************************************/
@protocol AZAppDelegate <NSObject>

@optional

// Called when the application object is fully set up, and is about to
// start the main loop
- (void) applicationDidFinishLaunching:(NSNotification *)notification;

// Called halfway through setup, before fonts are created, so the
// delegate can change them etc.
- (void) applicationWillLaunch:(NSNotification *)notification;

@required
/*****************************************************************************\
|* All AppDelegates need to be KVC-compliant for the following properties
|* since a loading ZIB will set them
\*****************************************************************************/

// The main application window
@property(strong) IBOutlet AZWindow *								window;

// Typically attached to the content-view of the window
@property(strong) IBOutlet AZView *   								view;
@end


@interface AZAppDelegate : NSObject < AZAppDelegate>

// The main application window
@property(strong) IBOutlet AZWindow *								window;

// Typically attached to the content-view of the window
@property(strong) IBOutlet AZView *   								view;

@end

NS_ASSUME_NONNULL_END
