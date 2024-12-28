//
//  AZTableView.h
//  Azoth
//
//  Created by Simon Gornall on 12/27/24.
//

#import <Azoth/AZView.h>

NS_ASSUME_NONNULL_BEGIN

@class AZView;
@class AZColour;

/*****************************************************************************\
|* Table-view datasource protocol
\*****************************************************************************/
@protocol AZTableViewDataSource <NSObject>

// Return the number of rows in the table view
- (NSInteger)numberOfRowsInTableView:(AZTableView *)tableView;
@end

/*****************************************************************************\
|* Table-view delegate protocol
\*****************************************************************************/
@protocol AZTableViewDelegate <NSObject>

// Return a view for a table-column/row combination
- (AZView *) tableView:(AZTableView *)tableView
	viewForTableColumn:(AZTableColumn *)column
				   row:(NSInteger)row;
				   
@optional
// Determine whether the user can edit a given row/col
- (BOOL)tableView:(AZTableView *)tableView
		shouldEditTableColumn:(AZTableColumn *)tableColumn
		row:(NSInteger)row;

// Ask the delegate if the user can change the selection
- (BOOL)selectionShouldChangeInTableView:(AZTableView *)tableView;

// Return the height of a given row
- (float)tableView:(AZTableView *)tableView heightOfRow:(NSInteger)row;

// Ask the delegate if the row can be selected
- (BOOL)tableView:(AZTableView *)tableView shouldSelectRow:(NSInteger)row;

// Ask the delegate if a column can be selected
- (BOOL)tableView:(AZTableView *)tableView
		shouldSelectTableColumn:(AZTableColumn *)tableColumn;

// Tell the delegate that a header was clicked on
- (void)tableView:(AZTableView *)tableView
		mouseDownInHeaderOfTableColumn:(AZTableColumn *)tableColumn;

// Tell the delegate we're about to display a view
- (void)tableView:(AZTableView *)tableView
		willDisplayView:(AZView *)view
		forTableColumn:(AZTableColumn *)tableColumn
		row:(NSInteger)row;

// Notification: selection is changing
- (void)tableViewSelectionIsChanging:(NSNotification *)note;

// Notification: selection did change
- (void)tableViewSelectionDidChange:(NSNotification *)note;

// Notification: column did move
- (void)tableViewColumnDidMove:(NSNotification *)note;

// Notification: column did resize
- (void)tableViewColumnDidResize:(NSNotification *)note;
@end


@interface AZTableView : AZView

// MARK: rows and columns

/*****************************************************************************\
|* Return the number of rows and optionally force a recount
\*****************************************************************************/
- (NSInteger) numberOfRows:(BOOL)recount;

/*****************************************************************************\
|* Add/remove a table column
\*****************************************************************************/
-(void)addTableColumn:(AZTableColumn *)column;
-(void)removeTableColumn:(AZTableColumn *)column;


// MARK: Layout and redraw

/*****************************************************************************\
|* Tile the view
\*****************************************************************************/
- (void) tile;

/*****************************************************************************\
|* Tell the tableview to reload its data
\*****************************************************************************/
- (void) reloadData;

/*****************************************************************************\
|* Use up all the space by resizing the last column
\*****************************************************************************/
- (void) sizeLastColumnToFit;


// MARK: View pool management

/*****************************************************************************\
|* Return an AZView from the pool of views we have, or nil if there's none
|* left of that type. If we don't find one, we create the set for next time
|* around...
\*****************************************************************************/
- (nullable AZView *) dequeueViewWithIdentifier:(NSString *)identifier;

/*****************************************************************************\
|* Allow the table columns to repopulate the pool. Views should be in the
|* column's cache, or in the pool, but not in both. The column will return
|* the views to the pool when the tableview's -tile method is called
\*****************************************************************************/
- (void) addToPool:(NSArray<AZView *> *)views;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The tableview delegate
@property(strong, nonatomic)
id<AZTableViewDelegate>										delegate;

// The tableview datasource
@property(strong, nonatomic)
id<AZTableViewDataSource>									dataSource;

// The tableview header view
@property(strong, nonatomic, nullable)
AZTableHeaderView *											headerView;

// The tableview corner view
@property(strong, nonatomic) AZView *						cornerView;

// The columns of the table
@property(strong, nonatomic)
NSMutableArray<AZTableColumn *> *							tableColumns;

// spacing between data-views
@property(assign, nonatomic) NSSize							spacing;

// Grid-drawing colour
@property(strong, nonatomic) AZColour * 					gridColour;

// Default row-height
@property(assign, nonatomic) float							rowHeight;

// Auto-resize columns to fit bounds
@property(assign, nonatomic) BOOL							autoresizeColumns;

// Alternate colours in view backgrounds
@property(assign, nonatomic) BOOL							alternateRowColours;

// Mask for how to draw grid lines
@property(assign, nonatomic) NSInteger						gridStyleMask;

// number of rows in the table
@property(assign, nonatomic) NSInteger						numberOfRows;

// number of rows in the table
@property(assign, nonatomic) NSInteger						numberOfColumns;

// Whether the table view shows a header-view
@property(assign, nonatomic) BOOL							usesHeader;


@end

NS_ASSUME_NONNULL_END
