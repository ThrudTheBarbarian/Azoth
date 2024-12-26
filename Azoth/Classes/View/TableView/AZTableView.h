//
//  AZTableView.h
//  Azoth
//
//  Created by Simon Gornall on 12/25/24.
//

#import <Azoth/AZControl.h>

NS_ASSUME_NONNULL_BEGIN

@class AZPainter;
@class AZTableColumn;
@class AZTableHeaderView;
@class AZTableView;
@class AZView;


/*****************************************************************************\
|* Table-view datasource protocol
\*****************************************************************************/
@protocol NSTableViewDataSource <NSObject>
@optional

// Return the number of rows in the table view
- (NSInteger)numberOfRowsInTableView:(AZTableView *)tableView;

// Return an object representing the value at a row/col
- (NSObject *)tableView:(AZTableView *)tableView
		objectValueForTableColumn:(AZTableColumn *)tableColumn
		row:(NSInteger)row;

// Set an object value at a row/col
- (void)tableView:(AZTableView *)tableView
	    setObjectValue:object
	    forTableColumn:(AZTableColumn *)tableColumn
	    row:(NSInteger)row;

// Returns whether a drag operation is allowed
//- (BOOL)tableView:(AZTableView *)tableView
//		writeRowsWithIndexes:(NSIndexSet *)indexes
//		toPasteboard:(AZPasteboard *)pasteboard;

// USed to determine a valid drop target
//- (AZDragOperation)tableView:(AZTableView *)tableView
//		validateDrop:(id<AZDraggingInfo>)draggingInfo
//		proposedRow:(int)proposedRow
//		proposedDropOperation:(AZTableViewDropOperation)dropOperation;

// Called when the mouse is released over a tableview that already
// said it would accept a drop
//- (BOOL)tableView:(AZTableView *)tableView
//	acceptDrop:(id<AZDraggingInfo>)draggingInfo
//	row:(NSInteger)row
//	dropOperation:(AZTableViewDropOperation)dropOperation;
@end


/*****************************************************************************\
|* Table-view delegate protocol
\*****************************************************************************/
@protocol NSTableViewDelegate <NSObject>
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


@interface AZTableView : AZControl

/*****************************************************************************\
|* Row height
\*****************************************************************************/
- (float) rowHeight;

/*****************************************************************************\
|* Whether to autosave columns
\*****************************************************************************/
- (BOOL) autosaveTableColumns;


// MARK: Geometry methods

/*****************************************************************************\
|* Return the rect of a given row
\*****************************************************************************/
- (NSRect)rectOfRow:(NSInteger)row;

/*****************************************************************************\
|* Return the rect of a given column
\*****************************************************************************/
- (NSRect)rectOfColumn:(NSInteger)column;

/*****************************************************************************\
|* Return the range of rows in a given rect
\*****************************************************************************/
- (NSRange)rowsInRect:(NSRect)rect;

/*****************************************************************************\
|* Return the range of columsn in a given rect
\*****************************************************************************/
- (NSRange)columnsInRect:(NSRect)rect;

/*****************************************************************************\
|* Return the row at a given point
\*****************************************************************************/
- (int)rowAtPoint:(NSPoint)point;

/*****************************************************************************\
|* Return the column at a given point
\*****************************************************************************/
- (int)columnAtPoint:(NSPoint)point;

/*****************************************************************************\
|* Return the frame of the view at a given row,column intersection
\*****************************************************************************/
- (NSRect)frameOfViewAtColumn:(int)column row:(int)row;

// MARK: Table columns


/*****************************************************************************\
|* Get the index (or column) of a column with a given identifier
\*****************************************************************************/
- (NSInteger) columnWithIdentifier:(NSObject *)identifier;
- (AZTableColumn *)tableColumnWithIdentifier:(NSObject *)identifier;

/*****************************************************************************\
|* Add a table column to the table
\*****************************************************************************/
- (void)addTableColumn:(AZTableColumn *)column;

/*****************************************************************************\
|* Remove a table column from the table
\*****************************************************************************/
- (void)removeTableColumn:(AZTableColumn *)column;

/*****************************************************************************\
|* Move a table column to a different index
\*****************************************************************************/
- (void)moveColumn:(NSInteger)columnIndex toColumn:(NSInteger)newIndex;


// MARK: Editing

/*****************************************************************************\
|* Perform an edit
\*****************************************************************************/
//- (void)editColumn:(NSInteger)column
//			   row:(NSInteger)row
//		 withEvent:(AZEvent *)event
//			select:(BOOL)select;


// MARK: Selection

/*****************************************************************************\
|* Number of rows selected (invalidates the single-row property)
\*****************************************************************************/
- (int)numberOfSelectedRows;

/*****************************************************************************\
|* Number of columns selected (invalidates the single-row property)
\*****************************************************************************/
- (int)numberOfSelectedColumns;

/*****************************************************************************\
|* Is a particular column selected
\*****************************************************************************/
- (BOOL)isColumnSelected:(NSInteger)row;

/*****************************************************************************\
|* Is a particular row selected
\*****************************************************************************/
- (BOOL)isRowSelected:(NSInteger)row;

/*****************************************************************************\
|* The set of selected columns
\*****************************************************************************/
- (NSIndexSet *)selectedColumnIndexes;

/*****************************************************************************\
|* The set of selected rows
\*****************************************************************************/
- (NSIndexSet *)selectedRowIndexes;

/*****************************************************************************\
|* Set a set of selected rows, optionally add to the selection
\*****************************************************************************/
- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend;

/*****************************************************************************\
|* Select a row, optionally add to the selection
\*****************************************************************************/
- (void)selectRow:(int)row byExtendingSelection:(BOOL)extend;

/*****************************************************************************\
|* Select a column, optionally add to the selection
\*****************************************************************************/
- (void)selectColumn:(int)column byExtendingSelection:(BOOL)extend;

/*****************************************************************************\
|* Deselect a row
\*****************************************************************************/
- (void)deselectRow:(NSInteger)row;

/*****************************************************************************\
|* Deselect a column
\*****************************************************************************/
- (void)deselectColumn:(NSInteger)column;


/*****************************************************************************\
|* Select everything
\*****************************************************************************/
- (void)selectAll:sender;

/*****************************************************************************\
|* Deselect everything
\*****************************************************************************/
- (void)deselectAll:sender;

// MARK: Scrolling support


/*****************************************************************************\
|* Scroll so that a row is visible
\*****************************************************************************/
- (void)scrollRowToVisible:(int)index;

/*****************************************************************************\
|* Scroll so that a column is visible
\*****************************************************************************/
- (void)scrollColumnToVisible:(int)index;


// MARK: Layout

/*****************************************************************************\
|* Send a notification that the number of rows has changed
\*****************************************************************************/
- (void)noteNumberOfRowsChanged;

/*****************************************************************************\
|* Send a notification that row-heights have changed
\*****************************************************************************/
- (void)noteHeightOfRowsWithIndexesChanged:(NSIndexSet *)indexSet;

/*****************************************************************************\
|* Call on the delegate to supply data to show
\*****************************************************************************/
- (void)reloadData;

/*****************************************************************************\
|* Lay the table out
\*****************************************************************************/
- (void)tile;

/*****************************************************************************\
|* Make the last column whatever size fits the table bounds
\*****************************************************************************/
- (void)sizeLastColumnToFit;

/*****************************************************************************\
|* Fetch the view at a given row / column
\*****************************************************************************/
- (AZView *) preparedViewAtColumn:(NSInteger)columnNumber row:(NSInteger)row;


// MARK: Drawing

/*****************************************************************************\
|* Highlight the selection within a rectangle
\*****************************************************************************/
- (void)highlightSelectionInClipRect:(NSRect)rect withPainter:(AZPainter *)P;

/*****************************************************************************\
|* Draw a row within a rectangle
\*****************************************************************************/
- (void)drawRow:(int)row clipRect:(NSRect)rect withPainter:(AZPainter *)P;

/*****************************************************************************\
|* Draw the background within a rectangle
\*****************************************************************************/
- (void)drawBackgroundInClipRect:(NSRect)rect withPainter:(AZPainter *)P;

/*****************************************************************************\
|* Draw the grid within a rectangle
\*****************************************************************************/
- (void)drawGridInClipRect:(NSRect)rect withPainter:(AZPainter *)P;


/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The tableview delegate
@property(strong, nonatomic)
id<NSTableViewDelegate>						delegate;

// The tableview datasource
@property(strong, nonatomic) NSObject *		datasource;

// The tableview header view
@property(strong, nonatomic)
AZTableHeaderView *							headerView;

// The tableview corner view
@property(strong, nonatomic) AZView *		cornerView;

// The columns of the table
@property(strong, nonatomic)
NSMutableArray<AZTableColumn *> *			tableColumns;

// spacing between data-views
@property(assign, nonatomic) NSSize			interViewSpacing;

// Grid-drawing colour
@property(strong, nonatomic) AZColour * 	gridColour;

// Allow the user to re-order columns
@property(assign, nonatomic) BOOL			allowsColumnReordering;

// Allow the user to resize columns
@property(assign, nonatomic) BOOL			allowsColumnResizing;

// Auto-resize columns to fit bounds
@property(assign, nonatomic) BOOL			autoresizeAllColumnsToFit;

// Do we allow multiple selection
@property(assign, nonatomic) BOOL			allowsMultipleSelection;

// Do we allow _no_ selection
@property(assign, nonatomic) BOOL			allowsEmptySelection;

// Do we allow column selection
@property(assign, nonatomic) BOOL			allowsColumnSelection;

// Alternate colours in view backgrounds
@property(assign, nonatomic) BOOL			usesAlternatingRowBackgroundColors;

// Mask for how to draw grid lines
@property(assign, nonatomic) NSInteger		gridStyleMask;

// How to highlight selections
@property(assign, nonatomic) NSInteger		selectionHighlightStyle;

// number of rows in the table
@property(assign, nonatomic) NSInteger		numberOfRows;

// number of rows in the table
@property(assign, nonatomic) NSInteger		numberOfColumns;

// The autosave name
@property(strong, nonatomic) NSString *		autosaveName;

// Do we draw the grid
@property(assign, nonatomic) BOOL			drawsGrid;

// column edited
@property(assign, nonatomic, readonly)
NSInteger									editedColumn;

// row edited
@property(assign, nonatomic, readonly)
NSInteger 									editedRow;

// column clicked on
@property(assign, nonatomic, readonly)
NSInteger									clickedColumn;

// row clicked on
@property(assign, nonatomic, readonly)
NSInteger									clickedRow;

// column selected
@property(assign, nonatomic, readonly)
NSInteger									selectedColumn;

// row selected
@property(assign, nonatomic, readonly)
NSInteger									selectedRow;
@end

NS_ASSUME_NONNULL_END
