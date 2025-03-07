//
//  AppDelegate.m
//  NibTest
//
//  Created by ThrudTheBarbarian on 1/1/25.
//

#import "AppDelegate.h"
#import "Node.h"

#define ROW_HEIGHT  (35.f)

@interface AppDelegate ()
@property(strong, nonatomic) Node *			root;
@end

@implementation AppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)notification
	{
	/*************************************************************************\
	|* Set up for vsync, though it doesn't seem to make much difference. We
	|* still consume far too much CPU for my liking - might have to look into
	|* how to limit FPS
	\*************************************************************************/
	id<AZRenderer> azr	= AZRenderer.renderer;
	[azr syncToVsync:YES];

	/*************************************************************************\
	|* Create the nodes for the outline
	\*************************************************************************/
	_root = [Node nodeWithName:@"root"];
	for (int i=0; i<5; i++)
		{
		Node *kid = [Node nodeWithName:[NSString stringWithFormat:@"kid %d", i]];
		[_root.kids addObject:kid];
		}

	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
	[nc addObserver:self
		   selector:@selector(selectionChanged:)
		       name:AZTableViewSelectionDidChangeNotification
			 object:nil];


	Node *kidNode = [Node nodeWithName:@"subnode"];
	[_root.kids[0].kids addObject:kidNode];

	[_ov reloadData];
	[_tv reloadData];
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
		tf.editable = NO;
		tf.autoresizingMask = AZViewWidthSizable | AZViewHeightSizable;
		}

	if ([type isEqualToString:@"button"])
		{
		AZTextField *tf = (AZTextField *)view;
		tf.stringValue = [NSString stringWithFormat:@"hola! %d", (int)row];
		tf.editable = NO;
		tf.autoresizingMask = AZViewWidthSizable;
		}
	return view;
	}

/*****************************************************************************\
|* This is called before the selection changes
\*****************************************************************************/
- (void)tableViewSelectionWillChange:(NSNotification *)note;
	{
	AZTableView *tv 	= note.object;
	NSIndexSet *indices	= tv.selectedRowIndexes;
	NSInteger index    	= indices.firstIndex;
	NSArray *cols		= tv.tableColumns;

	while (index != NSNotFound)
		{
		for (AZTableColumn *col in cols)
			{
			AZTextField *tf = (AZTextField *)[col viewForRow:index];
			//tf.textColour = AZColour.black;
			tf.state = AZControlStateNormal;
			}
		index = [indices indexGreaterThanIndex:index];
		}
	}

/*****************************************************************************\
|* This is called as views are being recycled (eg: on scroll)
\*****************************************************************************/
- (void)tableView:(AZTableView *)tv
		willDisplayView:(AZView *)view
		forTableColumn:(AZTableColumn *)col
		row:(NSInteger)row
	{
	if ([tv.className isEqualToString:@"AZTableView"])
		{
		AZTextField *tf = (AZTextField *)[col viewForRow:row];
		NSIndexSet *indices	= tv.selectedRowIndexes;
		if ([indices containsIndex:row])
			tf.state = AZControlStateHighlighted;
			//tf.textColour = AZColour.white;
		else
			tf.state = AZControlStateNormal;
			//tf.textColour = AZColour.black;
		}
	}

/*****************************************************************************\
|* This is called after the selection changes
\*****************************************************************************/
- (void)tableViewSelectionDidChange:(NSNotification *)note;
	{
	AZTableView *tv 	= note.object;
	NSIndexSet *indices	= tv.selectedRowIndexes;
	NSInteger index    	= indices.firstIndex;
	NSArray *cols		= tv.tableColumns;

	while (index != NSNotFound)
		{
		for (AZTableColumn *col in cols)
			{
			AZTextField *tf = (AZTextField *)[col viewForRow:index];
			tf.state = AZControlStateHighlighted;
			//tf.textColour = AZColour.white;
			}
		index = [indices indexGreaterThanIndex:index];
		}
	}

// MARK: outlineview datasource

/*****************************************************************************\
|* Number of rows
\*****************************************************************************/
- (NSInteger)outlineView:(AZOutlineView *)ov numberOfChildrenOfItem:(NSObject *)item;
	{
	Node *node = (Node *)item;
	if (node == nil)
		return _root.kids.count;
	return node.kids.count;
	}

// Tell the outline view whether an item is expandable
- (BOOL)outlineView:(AZOutlineView *)ov isItemExpandable:(NSObject *)item
	{
	Node *node = (Node *)item;
	if (node == nil)
		return _root.hasKids;
	return node.hasKids;
	}


// Get the specified child item of a given item
- (id) outlineView:(AZOutlineView *)ov child:(NSInteger)index ofItem:(id)item
	{
	Node *node = (Node *)item;
	if (node == nil)
		node = _root;
		
	if (index < node.kids.count)
		return node.kids[index];
	return nil;
	}



// MARK: outlineview delegate

/*****************************************************************************\
|* Return a view
\*****************************************************************************/
- (AZView *)outlineView:(AZOutlineView *)ov
     viewForTableColumn:(AZTableColumn *)column
					row:(NSInteger)row
	{
	AZView *view = [ov dequeueViewWithIdentifier:@"test"];


	if (view == nil)
		{
		NSRect frame 	= NSMakeRect(0, 0, column.width, ROW_HEIGHT);

		AZTextField *tf = [[AZTextField alloc] initWithFrame:frame];
		tf.identifier	= @"test";
		tf.state = AZControlStateNormal;
		[tf setTextColour:AZColour.black];
		view = tf;
		}
	AZTextField *tf = (AZTextField *)view;

	// Manage selection here for outline view because the views will change
	// when the selection changes, so looking for old/new notifications isn't
	// going to work (though it does for TableView)
	NSIndexSet *selected = [ov selectedRowIndexes];
	if ([selected containsIndex:row])
		{
		tf.state = AZControlStateHighlighted;
		//[tf setTextColour:AZColour.red];
		}
	else
		{
		tf.state = AZControlStateNormal;
		//[tf setTextColour:AZColour.black];
		}

	Node *item 		= (Node *)[ov itemAtRow:row];
	tf.stringValue = [NSString stringWithFormat:@"row %d [%@]",
					  (int)row, item.name];
	tf.editable = NO;
	tf.autoresizingMask = AZViewWidthSizable;
	return view;
	}

/*****************************************************************************\
|* Return a view
\*****************************************************************************/
- (void) selectionChanged:(NSNotification *)n
	{
	AZOutlineView *view = (AZOutlineView *)n.object;
	if (view == _ov)
		{
		Node *node = (Node *) [view itemAtRow:view.selectedRow];
		NSLog(@"selection now: %@", node.name);
		}
	}

/*****************************************************************************\
|* We don't like the number 3...
\*****************************************************************************/
- (BOOL) outlineView:(AZOutlineView *)ov shouldSelectItem:(Node *)item
	{
	if ([item.name isEqualToString:@"kid 3"])
		{
		NSLog(@"Cowardly refusing to select kid 3");
		return NO;
		}
	return YES;
	}


@end
