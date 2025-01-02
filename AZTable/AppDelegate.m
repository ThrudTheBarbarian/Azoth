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
	/*************************************************************************\
	|* Set up the UI for this application
	\*************************************************************************/
	AZView *cv		= [AZWindow contentViewForWindow:AZApp.window];
	[cv setIdentifier:@"content-view"];

	// Create the table-view we're debugging...
	NSRect frame 	 = NSMakeRect(0,0,300,360);
	AZTableView *tv	 = [[AZTableView alloc] initWithFrame:frame];
	tv.autoresizingMask = AZViewHeightSizable|AZViewWidthSizable;
	[tv setDelegate:self];
	[tv setDataSource:self];
	[tv addTableColumn:[[AZTableColumn alloc] initWithIdentifier:@"col1"]];
	[tv addTableColumn:[[AZTableColumn alloc] initWithIdentifier:@"col2"]];
	tv.tableColumns[0].title = @"column 1";

	// Add it to a scrollview
	frame = NSMakeRect(100, 100, 300, 360);
	AZScrollView *sv = [[AZScrollView alloc] initWithFrame:frame];
	[sv setHasVerticalScroller:YES];
	[sv setHasHorizontalScroller:YES];
	[sv setBorderType: AZLineBorder];
	[sv setDocumentView:tv];
	sv.autoresizingMask = AZViewHeightSizable|AZViewWidthSizable;

	// And add the scrollview to the content-view
	[cv addSubview:sv];

	[cv setBackgroundColour:[AZColour grey37Colour]];
	[tv tile];
	[tv reloadData];

	[tv setAllowsMultipleSelection:YES];
	[tv selectRow:4 byExtendingSelection:NO];
	[tv selectRow:7 byExtendingSelection:YES];

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
