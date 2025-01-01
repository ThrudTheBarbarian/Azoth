//
//  AppDelegate.m
//  AZOutline
//
//  Created by Simon Gornall on 12/31/24.
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
	AZApp *app = AZApp.sharedInstance;

	_root = [Node nodeWithName:@"root"];
	for (int i=0; i<40; i++)
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

	/*************************************************************************\
	|* Set up the UI for this application
	\*************************************************************************/
	AZView *cv		= [AZWindow contentViewForWindow:app.window];
	[cv setIdentifier:@"content-view"];

	// Create the outline-view we're debugging...
	NSRect frame 	 = NSMakeRect(0,0,300,360);
	AZOutlineView *ov	 = [[AZOutlineView alloc] initWithFrame:frame];
	ov.autoresizingMask = AZViewHeightSizable|AZViewWidthSizable;
	[ov setDelegate:self];
	[ov setDataSource:self];
	[ov addTableColumn:[[AZTableColumn alloc] initWithIdentifier:@"col1"]];
	ov.tableColumns[0].title = @"Really interesting list";

	//[ov expandItem:_root.kids[0]];
	// Add it to a scrollview
	frame = NSMakeRect(100, 100, 300, 360);
	AZScrollView *sv = [[AZScrollView alloc] initWithFrame:frame];
	[sv setHasVerticalScroller:YES];
	[sv setHasHorizontalScroller:YES];
	[sv setBorderType: AZLineBorder];
	[sv setDocumentView:ov];
	sv.autoresizingMask = AZViewHeightSizable|AZViewWidthSizable;

	// And add the scrollview to the content-view
	[cv addSubview:sv];

	[cv setBackgroundColour:[AZColour grey37Colour]];
	[ov tile];
	[ov reloadData];
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
		view = tf;
		}

	Node *item 		= (Node *)[ov itemAtRow:row];
	AZTextField *tf = (AZTextField *)view;
	tf.stringValue = [NSString stringWithFormat:@"row %d [%@]",
					  (int)row, item.name];
	tf.enabled = NO;
	tf.autoresizingMask = AZViewWidthSizable;
	return view;
	}

/*****************************************************************************\
|* Return a view
\*****************************************************************************/
- (void) selectionChanged:(NSNotification *)n
	{
	AZOutlineView *view = (AZOutlineView *)n.object;
	Node *node = (Node *) [view itemAtRow:view.selectedRow];
	NSLog(@"selection now: %@", node.name);
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
