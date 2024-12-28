//
//  AppDelegate.m
//  AZTable
//
//  Created by Simon Gornall on 12/27/24.
//

#import "AppDelegate.h"

#define ROW_HEIGHT  (35.f)

@implementation AppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)notification
	{
	AZApp *app = AZApp.sharedInstance;

	/*************************************************************************\
	|* Set up the UI for this application
	\*************************************************************************/
	AZView *cv		= [AZWindow contentViewForWindow:app.window];
	[cv setIdentifier:@"content-view"];

	AZTableView *tv	 = [[AZTableView alloc] initWithFrame:NSMakeRect(0,0,300,360)];
	tv.autoresizingMask = AZViewHeightSizable|AZViewWidthSizable;
	[tv setDelegate:self];
	[tv setDataSource:self];
	[tv addTableColumn:[[AZTableColumn alloc] initWithIdentifier:@"col1"]];
	[tv addTableColumn:[[AZTableColumn alloc] initWithIdentifier:@"col2"]];

	AZScrollView *sv = [[AZScrollView alloc]
							initWithFrame:NSMakeRect(100, 100, 300, 360)];
	[sv setHasVerticalScroller:YES];
	[sv setHasHorizontalScroller:YES];
	[sv setBorderType: AZLineBorder];
	[sv setDocumentView:tv];

	sv.autoresizingMask = AZViewHeightSizable|AZViewWidthSizable;
	[cv addSubview:sv];

	[cv setBackgroundColour:[AZColour grey37Colour]];
	[tv reloadData];
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
	AZView *view = [tableView dequeueViewWithIdentifier:@"textfield"];

	if (view == nil)
		{
		NSRect frame 	= NSMakeRect(0, 0, column.width, ROW_HEIGHT);
		view 			= [[AZTextField alloc] initWithFrame:frame];
		view.identifier	= @"textfield";
		}

	if ([column.identifier isEqualToString:@"col1"])
		{
		AZTextField *tf = (AZTextField *)view;
		tf.stringValue = [NSString stringWithFormat:@"hi there %d", (int)row];
		tf.enabled = NO;
		}

	if ([column.identifier isEqualToString:@"col2"])
		{
		AZTextField *tf = (AZTextField *)view;
		tf.stringValue = [NSString stringWithFormat:@"hola! %d", (int)row];
		tf.enabled = NO;
		}
	return view;
	}


@end
