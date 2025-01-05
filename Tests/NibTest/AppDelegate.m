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
	AZRenderer *azr = AZRenderer.renderer;
	[azr syncToVsync:YES];
	}


- (void) clicked:(id)sender
	{
	NSLog(@"Button '%@' was clicked", [sender stringValue]);
	}


// MARK: tableview datasource

/*****************************************************************************\
|* Number of rows
\*****************************************************************************/
- (NSInteger) numberOfRowsInTableView:(AZTableView *)tableView
	{
	return 20;
	}

/*****************************************************************************\
|* Height of a row
\*****************************************************************************/
- (float) tableView:(AZTableView *)tv heightOfRow:(NSInteger)row
	{
	return ROW_HEIGHT;
	}

/*****************************************************************************\
|* Return a view
\*****************************************************************************/
- (AZView *) tableView:(AZTableView *)tableView
	viewForTableColumn:(AZTableColumn *)column
				   row:(NSInteger)row
	{
	NSString *type 	= ([column.identifier isEqualToString:@"col1"])
					? @"button"
					: @"textfield";

	AZView *view = [tableView dequeueViewWithIdentifier:type];

	if (view == nil)
		{
		NSRect frame 	= NSMakeRect(0, 0, column.width, ROW_HEIGHT);
		if ([type isEqualToString:@"textfield"])
			{
			view 			= [[AZTextField alloc] initWithFrame:frame];
			view.identifier	= @"textfield";
			}
		else
			{
			//view			= [AZButton buttonWithFrame:frame];
			view 			= [[AZTextField alloc] initWithFrame:frame];
			view.identifier	= @"button";
			}
		}

	if ([type isEqualToString:@"textfield"])
		{
		AZTextField *tf = (AZTextField *)view;
		tf.stringValue = [NSString stringWithFormat:@"hi there %d", (int)row];
		tf.enabled = NO;
		tf.autoresizingMask = AZViewWidthSizable;
		}

	if ([type isEqualToString:@"button"])
		{
//		AZButton *b = (AZButton *)view;
//		b.stringValue = [NSString stringWithFormat:@"hola! %d", (int)row];
//		b.autoresizingMask = AZViewWidthSizable;
		AZTextField *tf = (AZTextField *)view;
		tf.stringValue = [NSString stringWithFormat:@"hola! %d", (int)row];
		tf.enabled = NO;
		tf.autoresizingMask = AZViewWidthSizable;
		}
	return view;
	}


@end
