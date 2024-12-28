//
//  AppDelegate.m
//  AZTable
//
//  Created by Simon Gornall on 12/27/24.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)notification
	{
	AZApp *app = AZApp.sharedInstance;

	/*************************************************************************\
	|* Set up the UI for this application
	\*************************************************************************/
	AZView *cv		= [AZWindow contentViewForWindow:app.window];
	[cv setIdentifier:@"content-view"];

	AZTableView *tv	 = [[AZTableView alloc] initWithFrame:NSMakeRect(0,0,600,360)];
	tv.autoresizingMask = AZViewHeightSizable|AZViewWidthSizable;
	[tv setDelegate:self];
	[tv setDataSource:self];
	[tv addTableColumn:[[AZTableColumn alloc] initWithIdentifier:@"col1"]];
	[tv setRowHeight:25];

	AZScrollView *sv = [[AZScrollView alloc]
							initWithFrame:NSMakeRect(100, 100, 600, 360)];
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
	return 10;
	}

/*****************************************************************************\
|* Return a view
\*****************************************************************************/
- (AZView *) tableView:(AZTableView *)tableView
	viewForTableColumn:(AZTableColumn *)column
				   row:(NSInteger)row
	{
	AZView *tf = [tableView dequeueViewWithIdentifier:@"textfield"];

	if (tf == nil)
		{
		NSRect frame 	= NSMakeRect(0,0,column.width, 20);
		tf 				= [[AZTextField alloc] initWithFrame:frame];
		tf.identifier	= @"textfield";
		}

	if ([column.identifier isEqualToString:@"col1"])
		((AZTextField *)tf).stringValue = @"hi there";

	return tf;
	}


@end
