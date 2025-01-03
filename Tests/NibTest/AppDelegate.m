//
//  AppDelegate.m
//  NibTest
//
//  Created by Simon Gornall on 1/1/25.
//

#import "AppDelegate.h"

#define ROW_HEIGHT  (35.f)

@implementation AppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)notification
	{
	/*************************************************************************\
	|* Try to load a view-xib in this bundle
	\*************************************************************************/

	[NSBundle loadNibNamed:@"view" owner:self];
	NSLog(@"self.view=%@", self.view);
	}


@end
