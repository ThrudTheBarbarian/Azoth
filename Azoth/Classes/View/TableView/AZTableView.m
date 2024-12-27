//
//  AZTableView.m
//  Azoth
//
//  Created by Simon Gornall on 12/25/24.
//

#import <SDL3/SDL.h>

#import "AZClipView.h"
#import "AZColour.h"
#import "AZControl.h"
#import "AZPainter.h"
#import "AZPopupButton.h"
#import "AZScrollView.h"
#import "AZTableColumn.h"
#import "AZTableColumn+Private.h"
#import "AZTableCornerView.h"
#import "AZTableHeaderView.h"
#import "AZTableView.h"
#import "AZTextField.h"
#import "AZTypes.h"

#define DEFAULT_ROWHEIGHT		(16.f)

/*****************************************************************************\
|* delegate notifications
\*****************************************************************************/
@interface AZTableView(AZTableView_notifications)
-(BOOL)delegateShouldSelectTableColumn:(AZTableColumn *)tableColumn ;
-(BOOL)delegateShouldSelectRow:(NSInteger)row;
-(BOOL)delegateShouldEditTableColumn:(AZTableColumn *)tableColumn
								 row:(NSInteger)row;
-(BOOL)delegateSelectionShouldChange;
-(void)noteSelectionIsChanging;
-(void)noteSelectionDidChange;
-(void)noteColumnDidResizeWithOldWidth:(float)oldWidth;
-(BOOL)dataSourceCanSetObjectValue;
-(void)dataSourceSetObjectValue:object
				 forTableColumn:(AZTableColumn *)tableColumn
							row:(NSInteger)row;
@end

/*****************************************************************************\
|* "private" methods / properties
\*****************************************************************************/
@interface AZTableView()

// Number of row-heights
@property(assign, nonatomic) NSInteger					rowHeightsCount;

// Actual row-heights
@property(assign, nonatomic) float *					rowHeights;

// Temporary: selected columns
@property(strong, nonatomic)
NSMutableArray<AZTableColumn *> *						selectedColumns;


// The View being used as an editor
@property(strong, nonatomic) AZControl *				editingView;

// Rect for the editing view
@property(assign, nonatomic) NSRect						editingFrame;

// Rect for the editing view's border
@property(assign, nonatomic) NSRect						editingBorder;

// row being dragged
@property(assign, nonatomic) NSInteger					draggingRow;
@end

/*****************************************************************************\
|* Helper structures
\*****************************************************************************/
typedef struct
	{
	NSString *name;
	SEL selector;
	} NotifyMap;


@implementation AZTableView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
-initWithFrame:(NSRect)frame
	{
    if (self = [super initWithFrame:frame])
		{
		_rowHeightsCount			= 0;
		_rowHeights					= NULL;
		_rowHeight 					= DEFAULT_ROWHEIGHT;
		_interViewSpacing 			= NSMakeSize(3.0,2.0);
		_selectedRowIndexes 		= [NSIndexSet new];
		_selectedColumns 			= [NSMutableArray new];
		_sortDescriptors			= [NSArray new];
		_editedColumn 				= -1;
		_editedRow 					= -1;
		_numberOfRows 				= -1;
		_draggingRow 				= -1;

		_allowsColumnReordering 	= YES;
		_allowsColumnResizing 		= YES;

		// the default isn't actually given in the spec, but this seems
		// more like default behavior
		_autoresizeAllColumnsToFit 	= NO;
		_allowsMultipleSelection 	= NO;
		_allowsEmptySelection 		= YES;

		_allowsColumnSelection 		= YES;

		float height				= _rowHeight + _interViewSpacing.height;
		float width					= NSWidth(self.bounds);
		NSRect headerRect			= NSMakeRect(0,0,width,height);
		_headerView = [[AZTableHeaderView alloc] initWithFrame:headerRect];
		[_headerView setTableView:self];

		NSRect cornerRect			= NSMakeRect(0,0,_rowHeight,_rowHeight);
		_cornerView = [[AZTableCornerView alloc] initWithFrame:cornerRect];

		_tableColumns 				= [NSMutableArray  new];
		self.backgroundColour 		= AZColour.controlBackgroundColour;
		_gridColour 				= AZColour.gridColour;
		_gridStyleMask 				= AZTableViewGridNone;
		_alternatesRowColours 		= NO;
		}
    return self;
	}

/*****************************************************************************\
|* Clean up on dealloc
\*****************************************************************************/
- (void) dealloc
	{
	SAFELY_FREE(_rowHeights);
	[NSNotificationCenter.defaultCenter removeObserver:self];
	}

/*****************************************************************************\
|* Return the number of rows
\*****************************************************************************/
-(NSInteger)numberOfRows
	{
    if (_numberOfRows < 0)
		{
		if (_dataSource==nil)
			_numberOfRows=0;
		else
			{
			SEL rowsSEL = @selector(numberOfRowsInTableView:);
			if ([_dataSource respondsToSelector:rowsSEL] == YES)
				_numberOfRows = [_dataSource numberOfRowsInTableView:self];
			else
				{
				// Apple AppKit only logs here, so we do the same.
				SDL_Log("data source %s does not respond to "
						"numberOfRowsInTableView:",
						_dataSource.description.UTF8String);
				_numberOfRows=0;
				}
			}
		}
	return _numberOfRows;
	}

/*****************************************************************************\
|* Return the number of columns
\*****************************************************************************/
-(NSInteger) numberOfColumns
	{
    return _tableColumns.count;
	}

/*****************************************************************************\
|* Return a specific table column index
\*****************************************************************************/
- (NSInteger) columnWithIdentifier:(NSObject *)identifier
	{
	int idx = 0;
	for (AZTableColumn *column in _tableColumns)
		{
		if ([column.identifier isEqual:identifier])
			return idx;
		idx ++;
		}
	return -1;
	}

/*****************************************************************************\
|* Return a specific table column
\*****************************************************************************/
- (nullable AZTableColumn *)tableColumnWithIdentifier:(NSObject *)identifier
	{
	for (AZTableColumn *column in _tableColumns)
		if ([column.identifier isEqual:identifier])
			return column;

	return nil;
	}

/*****************************************************************************\
|* Return the rect for a given row
\*****************************************************************************/
- (NSRect) rectOfRow:(NSInteger)row
	{
    NSRect rect = self.bounds;
    NSInteger count;

    if (row < 0 || row >= self.numberOfRows)
        return NSZeroRect;

    rect.origin.x = 0.f;
    rect.origin.y = 0.f;
    for (NSInteger i = 0; i < row; i++)
        rect.origin.y += _rowHeightAtIndex(self,i)+ _interViewSpacing.height;

    rect.size.width = 0.f;
    count = _tableColumns.count;
    for (NSInteger i = 0; i < count; i++)
        rect.size.width += _tableColumns[i].width + _interViewSpacing.width;
    rect.size.height = _rowHeightAtIndex(self,row) + _interViewSpacing.height;

    return rect;
	}

/*****************************************************************************\
|* Return the rect for a given column
\*****************************************************************************/
- (NSRect) rectOfColumn:(NSInteger)column
	{
    NSInteger numberOfRows 	= self.numberOfRows;
    NSInteger numberOfCols 	= _tableColumns.count;
    NSRect rect 			= self.bounds;

    if (column < 0 || column >= numberOfCols)
		{
        SDL_Log("rectOfColumn: invalid index %d (valid {%d, %d})",
				(int)column, 0, (int)numberOfCols);
		return NSZeroRect;
		}

    rect.origin.x = 0.;
    for (NSInteger i = 0; i < column; i++)
        rect.origin.x += _tableColumns[i].width + _interViewSpacing.width;
    rect.origin.y = 0.;
    
    rect.size.width = _tableColumns[column].width + _interViewSpacing.width;
    rect.size.height = 0.;
    for (NSInteger i = 0; i < numberOfRows; i++)
        rect.size.height += _rowHeightAtIndex(self,i) + _interViewSpacing.height;
	rect.size.height = MAX(NSHeight(rect), self.superview.bounds.size.height);

    return rect;
	}

/*****************************************************************************\
|* Return a range indicating which rows are within a given rect
\*****************************************************************************/
- (NSRange) rowsInRect:(NSRect)rect
	{
    NSRange range 			= NSMakeRange(0, 0);
    NSInteger numberOfRows	= self.numberOfRows;
    float height 			= 0.f;

    _rowHeightsCount		= numberOfRows;
    _rowHeights				= realloc(_rowHeights,sizeof(float)*_rowHeightsCount);

	NSInteger i;
    for (i = 0; i < numberOfRows; i++)
		{
		float H = height + _rowHeightAtIndex(self,i) + _interViewSpacing.height;
        if (H > rect.origin.y)
            break;
        else
            height += _rowHeightAtIndex(self,i) + _interViewSpacing.height;
		}

    if (i < numberOfRows)
		{
        range.location = i;

        for ( ; i < numberOfRows; i++)
			{
            if (height > rect.origin.y + rect.size.height)
                break;
            else
                height += _rowHeightAtIndex(self,i) + _interViewSpacing.height;
			}

        if (i < numberOfRows)
            range.length = i - range.location + 1;
        else
            range.length = numberOfRows - range.location;
		}

    return range; // returns 0,0 if not found, not NSNotFound
	}

/*****************************************************************************\
|* Return a range indicating which columns are within a given rect
\*****************************************************************************/
- (NSRange) columnsInRect:(NSRect)rect
	{
    NSRange range 				= NSMakeRange(0, 0);
    NSInteger numberOfColumns	= self.numberOfColumns;
    float width 				= 0.f;

	NSInteger i;
	for (i = 0; i < numberOfColumns; i++)
		{
		width += _tableColumns[i].width + _interViewSpacing.width;

        if (width > rect.origin.x)
            break;
		}

    if (i < numberOfColumns)
		{
        range.location = i;

        for ( ; i < numberOfColumns; i++)
			{
            if (width > NSMaxX(rect))
                break;
			width += _tableColumns[i].width + _interViewSpacing.width;
			}

        if (i < numberOfColumns)
            range.length = i - range.location + 1;
        else
            range.length = numberOfColumns - range.location;
		}

    return range; // returns 0,0 if not found, not NSNotFound
	}

/*****************************************************************************\
|* Return the row at a given point
\*****************************************************************************/
- (NSInteger) rowAtPoint:(NSPoint)p
	{
    NSInteger row = -1;
    NSRange range = [self rowsInRect:NSMakeRect(p.x, p.y, 0.f, 0.f)];
    if (range.length != 0)
        row = range.location;

    return row;
	}

/*****************************************************************************\
|* Return the column at a given point
\*****************************************************************************/
- (NSInteger) columnAtPoint:(NSPoint)p
	{
    NSInteger column = -1;
    NSRange range 	 = [self columnsInRect:NSMakeRect(p.x, p.y, 0., 0.)];
    if (range.length != 0)
        column = range.location;

    return column;
	}

/*****************************************************************************\
|* Return the frame of the view at a given row,column intersection
\*****************************************************************************/
- (NSRect)frameOfViewAtColumn:(NSInteger)column row:(NSInteger)row
	{
	NSRect frame;

	if ( (column < 0) || (column > self.numberOfColumns)
	   ||(row < 0) || (row > self.numberOfRows))
    return NSZeroRect;

	frame.origin.x = 0.;
	for (NSInteger i = 0; i < column; i++)
		frame.origin.x += _tableColumns[i].width + _interViewSpacing.width;

	frame.origin.y = 0.;
	for (NSInteger i = 0; i < row; i++)
		frame.origin.y += _rowHeightAtIndex(self,i) + _interViewSpacing.height;

	frame.size.width  = _tableColumns[column].width + _interViewSpacing.width;
	frame.size.height = _rowHeightAtIndex(self,row) + _interViewSpacing.height;

	return frame;
	}

/*****************************************************************************\
|* Make sure we tile the view when a datasource is set
\*****************************************************************************/
- (void) setDataSource:dataSource
	{
	_dataSource = dataSource;
	[self tile];
	}

/*****************************************************************************\
|* Properly replace the delegate, invalidating any old notifications etc.
\*****************************************************************************/
- (void) setDelegate:(id<NSTableViewDelegate>)delegate
	{
	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;

    NotifyMap notes[] =
		{
			{ AZTableViewSelectionDidChangeNotification,
			  @selector(tableViewSelectionDidChange:) },
			{ AZTableViewColumnDidMoveNotification,
			  @selector(tableViewColumnDidMove:) },
			{ AZTableViewColumnDidResizeNotification,
			  @selector(tableViewColumnDidResize:) },
			{ AZTableViewSelectionIsChangingNotification,
			  @selector(tableViewSelectionIsChanging:) },
			{ nil, NULL }
		};

    if (_delegate != nil)
        for (int i = 0; notes[i].name != nil; ++i)
            [nc removeObserver:_delegate name:notes[i].name object:self];

    _delegate=delegate;

    for (int i = 0; notes[i].name != nil; ++i)
        if ([_delegate respondsToSelector:notes[i].selector])
            [nc addObserver:_delegate
				   selector:notes[i].selector
					   name:notes[i].name
					 object:self];
	}

/*****************************************************************************\
|* Install the headerview and link it to ourselves
\*****************************************************************************/
- (void) setHeaderView:(AZTableHeaderView *)headerView
	{
    _headerView = headerView;
    _headerView.tableView = self;
    [self.enclosingScrollView tile];
	}

/*****************************************************************************\
|* Install the cornerview and retile if necessary
\*****************************************************************************/
- (void) setCornerView:(AZTableCornerView *)cornerView
	{
	_cornerView = cornerView;
    [self.enclosingScrollView tile];
	}

/*****************************************************************************\
|* Change the default row height
\*****************************************************************************/
- (void) setRowHeight:(float)height
	{
    NSInteger numberOfRows = self.numberOfRows;

    if (height > 0.f)
        _rowHeight = height;
    else
        // Cocoa doesn't even NSLog() here, instead the table isn't drawn.
        _rowHeight = 0.f;

    for (NSInteger i = 0; i < _rowHeightsCount; i++)
		_rowHeights[i] = _rowHeight;

    [self tile];
	}

/*****************************************************************************\
|* Change the inter-view spacing and re-display
\*****************************************************************************/
-(void)setInterViewSpacing:(NSSize)size
	{
    _interViewSpacing = size;
    [self setNeedsDisplay:YES];
	}

/*****************************************************************************\
|* Change the way we render grids and re-display
\*****************************************************************************/
- (void) setGridStyleMask:(NSInteger)gridStyle
	{
	_gridStyleMask = gridStyle;
	[self setNeedsDisplay:YES];
	}

/*****************************************************************************\
|* Change the way we render selection and re-display
\*****************************************************************************/
- (void) setSelectionHighlightStyle:(NSInteger)value
	{
	_selectionHighlightStyle=value;
	[self setNeedsDisplay:YES];
	}

/*****************************************************************************\
|* Add/remove a table column
\*****************************************************************************/
-(void)addTableColumn:(AZTableColumn *)column
	{
    [_tableColumns addObject:column];
    [column setTableView:self];
    [self reloadData];
    [_headerView setNeedsDisplay:YES];
	}

-(void)removeTableColumn:(AZTableColumn *)column
	{
    [column setTableView:nil];
    [_tableColumns removeObject:column];
    [self reloadData];
    [_headerView setNeedsDisplay:YES];
	}

// MARK: Private methods and helpers

/*****************************************************************************\
|* Return the row height at a given row's index
\*****************************************************************************/
static float _rowHeightAtIndex(AZTableView *self, NSInteger index)
	{
	if (index < self->_rowHeightsCount)
		return self->_rowHeights[index];

	return self->_rowHeight;
	}


/*****************************************************************************\
|* Get an object value from the datasource
\*****************************************************************************/
-(id) _dataSourceObjectValueForColumn:(AZTableColumn *)col row:(NSInteger)row
	{
	SEL getter = @selector(tableView:objectValueForTableColumn:row:);

	if (_dataSource!=nil && [_dataSource respondsToSelector:getter]==YES)
		return [_dataSource tableView:self
			objectValueForTableColumn:col
								  row:row];

	// Apple AppKit only logs here, so we do the same.
	SDL_Log("data source %s does not respond to "
			"tableView:objectValueForTableColumn:row:",
			_dataSource.description.UTF8String);
	return nil;
	}

/*****************************************************************************\
|* Find the adjusted frame for a view
\*****************************************************************************/
-(NSRect)_adjustedFrame:(NSRect)frame forView:(AZView *)view
	{
	frame.origin.x    += _interViewSpacing.width - 1.;
	frame.origin.y    += _interViewSpacing.height;
	frame.size.width  -= _interViewSpacing.width;
	frame.size.height -= _interViewSpacing.height;

	if ([view isKindOfClass:[AZTextField class]])
      frame.size.height--;
	else
		{
		frame.origin.x--;
		frame.origin.y--;
		}

	if (frame.origin.x < 0.f) 		frame.origin.x = 0.f;
	if (frame.origin.y < 0.f) 		frame.origin.y = 0.f;
	if (frame.size.width < 0.f) 	frame.size.width = 0.f;
	if (frame.size.height < 0.f) 	frame.size.height = 0.f;

	return frame;
	}

/*****************************************************************************\
|* Limited editing, we only support AZTextField editing
\*****************************************************************************/
-(void)editColumn:(NSInteger)column row:(NSInteger)row select:(BOOL)select
	{
	if (_editingView)
		[self _textDidEndEditing:nil];

	NSInteger numberOfRows		= self.numberOfRows;
	NSInteger numberOfCols		= self.numberOfColumns;

	/*************************************************************************\
	|* Check the column is valid
	\*************************************************************************/
	if ((column < 0) || (column >= numberOfCols))
		{
		SDL_Log("Cannot edit in nonexistent table column %d", (int)column);
		return;
		}

	AZView * editingView			= nil;
	AZTableColumn *editingColumn	= _tableColumns[column];

	/*************************************************************************\
	|* Check the row is valid
	\*************************************************************************/
	if (row < 0 || row >= numberOfRows)
		{
		SDL_Log("Cannot edit in nonexistent table row %d", (int)row);
		return;
		}
   
	/*************************************************************************\
	|* Check other criteria
	\*************************************************************************/
	if (!editingColumn.editable)
		return;
   
	if ([self delegateShouldEditTableColumn:editingColumn row:row] == NO)
		return;
   
	if ([self dataSourceCanSetObjectValue] == NO)
		{
		SDL_Log("data source does not respond to "
				"tableView:setObjectValue:forTableColumn:row:");
		return;
		}

	editingView 	= [self preparedViewAtColumn:column row:row];

	_editingView 	= nil;
	_editedColumn 	= column;
	_editedRow 		= row;
	_editingBorder 	= [self frameOfViewAtColumn:column row:row];

	_editingFrame 	= [self _adjustedFrame:_editingBorder forView:editingView];
	_editingBorder.origin.x--;
	_editingBorder.origin.y--;
	_editingBorder.size.width++;
	_editingBorder.size.height++;
	if ([editingView isKindOfClass:AZTextField.class])
		{
		AZTextField *tf = (AZTextField *)editingView;
		_editingView = tf;

		[tf setIsOpaque:YES];
		[tf setBackgroundColour:self.backgroundColour];
		[tf setEnabled:YES];

		if (select == YES)
			[tf selectAll];

		[self.window setFirstResponder:tf];
		[self setNeedsDisplay:YES];
		}
	}

/*****************************************************************************\
|* KVO-compliant (in case we ever get there) setter
\*****************************************************************************/
-(void)_setSelectedRowIndexes:(NSIndexSet *)value
	{
	_selectedRowIndexes = value;

	if ((_selectedRowIndexes.count == 0) && (!_allowsEmptySelection))
		_selectedRowIndexes = [[NSIndexSet alloc] initWithIndex:0];

   
	if ((_selectedRowIndexes.count > 0) && (_selectedColumns.count > 0))
		{
		// selecting a row deselects the previously selected column
		[_selectedColumns removeAllObjects];
		[self setNeedsDisplay:YES];
		[_headerView setNeedsDisplay:YES];
		}

	[self noteSelectionDidChange];
	}

/*****************************************************************************\
|* Implement row selection, optionally by extending the selection
\*****************************************************************************/
- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend
	{
	NSInteger index;
	NSIndexSet * newIndexes = nil;
	BOOL changed 			= NO;
	NSInteger numRows 		= self.numberOfRows;

	// Mac OS X doesn't raise an exception if one of the indices
	// is out of range. Instead, the selection is left untouched.
	BOOL found = (indexes.firstIndex != NSNotFound);
	BOOL oub   = (indexes.firstIndex < 0) || (indexes.lastIndex > numRows);
	if (found && oub)
		return;

	// Selecting a row deselects all columns.
	if (_selectedColumns.count)
		{
		[_selectedColumns removeAllObjects];
		[self setNeedsDisplay:YES];
		[_headerView setNeedsDisplay:YES];
		changed = YES;
		}

	if (extend)
		{
		NSMutableIndexSet * mutableIndexes = [NSMutableIndexSet new];
		[mutableIndexes addIndexes:_selectedRowIndexes];
		[mutableIndexes addIndexes:indexes];
		newIndexes = [[NSIndexSet alloc] initWithIndexSet:mutableIndexes];
		}
	else
		newIndexes = indexes;

   // Find the changed rows and mark them for redraw.
   NSInteger i = _selectedRowIndexes.firstIndex;
   if (i == NSNotFound)
		i = [newIndexes firstIndex];
   else
		{
		NSInteger try = newIndexes.firstIndex;
		if (try != NSNotFound && try < i)
			i = try;
		}

	NSInteger last = [_selectedRowIndexes lastIndex];
	if (last == NSNotFound)
		last = newIndexes.lastIndex;
	else
		{
		NSInteger try = newIndexes.lastIndex;
		if (try != NSNotFound && try > last)
			last = try;
		}

	// If i is valid, last is valid as well.
	if (i != NSNotFound)
		for ( ; i <= last; i++)
			{
			BOOL inSelected = [_selectedRowIndexes containsIndex:i];
			BOOL inNew		= [newIndexes containsIndex:i];
			if (inSelected != inNew)
				{
				if (_editedRow == i && _editingView != nil)
					[self textDidEndEditing:nil];

				[self setNeedsDisplay:YES];
				changed = YES;
				// NSLog(@"NSTableView row %d for redraw.", i);
				}
			}

	if (changed)
		[self _setSelectedRowIndexes:newIndexes];
	}

/*****************************************************************************\
|* Get the first (possibly only) selected row, or return -1
\*****************************************************************************/
- (NSInteger) selectedRow
	{
	NSInteger row = [_selectedRowIndexes firstIndex];

	if (row == NSNotFound)
		return -1;

	return row;
	}

/*****************************************************************************\
|* Get the first (possibly only) selected column, or return -1
\*****************************************************************************/
-(NSInteger) selectedColumn
	{
    if (_selectedColumns.count == 0)
     return -1;

    return [_tableColumns indexOfObject:[_selectedColumns objectAtIndex:0]];
	}

/*****************************************************************************\
|* Return number of selected rows/cols. Ronson woodseal, eat your heart out
\*****************************************************************************/
- (NSInteger) numberOfSelectedRows
	{
    return _selectedRowIndexes.count;
	}

- (NSInteger) numberOfSelectedColumns
	{
    return _selectedColumns.count;
	}

/*****************************************************************************\
|* Is a row/column selected
\*****************************************************************************/
- (BOOL) isRowSelected:(NSInteger)row
	{
    return [_selectedRowIndexes containsIndex:row];
	}

- (BOOL) isColumnSelected:(NSInteger)col
	{
    return [_selectedColumns containsObject:[_tableColumns objectAtIndex:col]];
	}

/*****************************************************************************\
|* Get the indices of the selected columns
\*****************************************************************************/
- (NSIndexSet *) selectedColumnIndexes
	{
	NSMutableIndexSet *result 	= [NSMutableIndexSet new];
	NSInteger count				= _selectedColumns.count;

	for (NSInteger i=0; i<count; i++)
		{
		AZTableColumn *col 	= [_selectedColumns objectAtIndex:i];
    	NSInteger index		= [_tableColumns indexOfObjectIdenticalTo:col];
		[result addIndex:index];
		}
   
	return result;
	}

/*****************************************************************************\
|* Select a row, optionally extending the selection
\*****************************************************************************/
- (void) selectRow:(NSInteger)row byExtendingSelection:(BOOL)extend
	{
	NSIndexSet *set = nil;
	if (extend)
		{
		NSInteger startRow 	= [self selectedRow];
		NSInteger endRow	= row;

		if (startRow > endRow)
			{
			endRow 		= startRow;
			startRow	= row;
			}

		NSRange range = NSMakeRange(startRow, endRow-startRow+1);
		set 		  = [NSIndexSet indexSetWithIndexesInRange:range];
		[self selectRowIndexes:set byExtendingSelection:NO];
		}
	else
		{
		set = [NSIndexSet indexSetWithIndex:row];
		[self selectRowIndexes:set byExtendingSelection:NO];
		}
	}

/*****************************************************************************\
|* Select a column, optionally extending the selection
\*****************************************************************************/
-(void)selectColumn:(NSInteger)column byExtendingSelection:(BOOL)extend
	{
    AZTableColumn *tableColumn = [_tableColumns objectAtIndex:column];
    
    // selecting a column deselects all rows
    [self selectRowIndexes:[NSIndexSet new] byExtendingSelection:NO];

    if (extend == NO)
        [_selectedColumns removeAllObjects];

    if ([_selectedColumns containsObject:tableColumn] == NO)
        if ([self delegateShouldSelectTableColumn:tableColumn] == YES)
            [_selectedColumns addObject:tableColumn];

    [self noteSelectionDidChange];
    [self setNeedsDisplay:YES];
    [_headerView setNeedsDisplay:YES];
	}

/*****************************************************************************\
|* Deselect a row
\*****************************************************************************/
- (void) deselectRow:(NSInteger)row
	{
    NSIndexSet* selectedRowIndexes = self.selectedRowIndexes;

    if ([selectedRowIndexes containsIndex:row])
		{
		NSMutableIndexSet *newSelection=[selectedRowIndexes mutableCopy];
     
		[newSelection removeIndex:row];
		[self selectRowIndexes:newSelection byExtendingSelection:NO];
		}
	}

/*****************************************************************************\
|* Deselect a column
\*****************************************************************************/
- (void) deselectColumn:(NSInteger)column
	{
	AZTableColumn *col = [_tableColumns objectAtIndex:column];

    if ([_selectedColumns containsObject:col])
		{
        [_selectedColumns removeObject:col];
        [self setNeedsDisplayInRect:[self rectOfColumn:column]];
        [_headerView setNeedsDisplay:YES];
		}
	}

/*****************************************************************************\
|* (De)Select all
\*****************************************************************************/
- (void) selectAll:(id)sender
	{
	NSRange range		= NSMakeRange(0, self.numberOfRows);
	NSIndexSet *rows	= [NSIndexSet indexSetWithIndexesInRange:range];
    [self selectRowIndexes:rows byExtendingSelection:NO];
	}

- (void) deselectAll:(id)sender
	{
    [self selectRowIndexes:[NSIndexSet new] byExtendingSelection:NO];
    [_selectedColumns removeAllObjects];
	}

/*****************************************************************************\
|* Scroll a row/column to be visible
\*****************************************************************************/
-(void)scrollRowToVisible:(NSInteger)index
	{
    [self scrollRectToVisible:[self rectOfRow:index]];
	}

-(void)scrollColumnToVisible:(NSInteger)index
	{
    [self scrollRectToVisible:[self rectOfColumn:index]];
	}

/*****************************************************************************\
|* Handle row-height changes. This also resizes the row heights cache
|* size as appropriate.
\*****************************************************************************/
- (void) noteHeightOfRowsWithIndexesChanged:(NSIndexSet *)indexSet
	{
	NSInteger rowCount = self.numberOfRows;
	BOOL found = (indexSet.firstIndex != NSNotFound);
	BOOL oub   = (indexSet.firstIndex <0) || (indexSet.lastIndex >= rowCount);
	if (found && oub)
		{
		SDL_Log("Index set %s out of range (valid are 0 to %ld).",
				indexSet.description.UTF8String, (long)rowCount);
		return;
		}

   _rowHeights = realloc(_rowHeights, sizeof(float) * rowCount);

   NSInteger row = indexSet.firstIndex;
   SEL getter    = @selector(tableView:heightOfRow:);

	if (_delegate != nil && [_delegate respondsToSelector:getter] == YES)
		{
		while (row != NSNotFound)
			{
			_rowHeights[row] = [_delegate tableView:self heightOfRow:row];
			row				 = [indexSet indexGreaterThanIndex:row];
			}
		}
	else
		{
		while (row != NSNotFound)
			{
			_rowHeights[row] = _rowHeight;
			row				 = [indexSet indexGreaterThanIndex:row];
			}
		}
	}

/*****************************************************************************\
|* Handle number-of-rows changes. Calls into row-height changes to establish
|* the row-cache for the new values
\*****************************************************************************/
- (void) noteNumberOfRowsChanged
	{
    NSSize size 			= self.frame.size;
    NSSize headerSize 		= _headerView.frame.size;

	// Set to <0 to force a re-count
    _numberOfRows 			= -1;
    NSInteger numberOfRows	= [self numberOfRows];

    // There isn't much point in trying to validate the heights of
    // visible rows only, as the often used -rectOfColumn: needs them all.
    NSRange rowRange		= NSMakeRange(0, numberOfRows);
    NSIndexSet *rows 		= [NSIndexSet indexSetWithIndexesInRange:rowRange];
    [self noteHeightOfRowsWithIndexesChanged:rows];

    // if there's any editing going on, we'd better stop it.
    if (_editingView != nil)
		[self textDidEndEditing:nil];

    if (numberOfRows > 0)
        size.width = [self rectOfRow:0].size.width;

    if (_tableColumns.count > 0)
        size.height = [self rectOfColumn:0].size.height;

    headerSize.width = size.width;

    [self setFrameSize:size];
    [_headerView setFrameSize:headerSize];

    NSMutableIndexSet *selection = _selectedRowIndexes.mutableCopy;
    NSInteger count 			 = selection.count;
    NSUInteger indexes[count];
    [selection getIndexes:indexes maxCount:count inIndexRange:NULL];
    
    while (--count >= 0)
		if (indexes[count] >= numberOfRows)
			[selection removeIndex:indexes[count]];

	// Do not change the selection if it didnt change. _setSelectedRowIndexes
	// posts a notification and doing it unnecessarily can cause performance
	// and behavior problems. For example, if there is no selection in a newly
	// created tableview and you post the notification indirectly with
	// setDataSource:, an application which expects a non-empty selection
	// will have problems.
	//
	// FIXME: investigate whether _setSelectedRowIndexes: should do this check.
	if (![selection isEqualToIndexSet:_selectedRowIndexes])
		[self _setSelectedRowIndexes:selection];
	}

/*****************************************************************************\
|* Something changed. Figure it out...
\*****************************************************************************/
-(void)reloadData
	{
    [self noteNumberOfRowsChanged];
    [self setNeedsDisplay:YES];
    [_headerView setNeedsDisplay:YES];
	}

/*****************************************************************************\
|* Lay out the view
\*****************************************************************************/
-(void)tile
	{
    [self sizeLastColumnToFit];
    [self noteNumberOfRowsChanged];

    NSRect rect 	= _headerView.frame;
    rect.size.width = self.frame.size.width;
    [_headerView setFrameSize:rect.size];

	float height 	= _rowHeight + _interViewSpacing.height;
    [[self enclosingScrollView] setVerticalLineScroll:height];

    [self setNeedsDisplay:YES];
    [_headerView setNeedsDisplay:YES];
	}

/*****************************************************************************\
|* Use up all the space by resizing the last column
\*****************************************************************************/
- (void) sizeLastColumnToFit
	{
    AZClipView *clipView = (AZClipView *)self.superview;

    if ([clipView isKindOfClass:AZClipView.class])
		{
        NSSize size 	= clipView.bounds.size;
        NSInteger count = _tableColumns.count;
        float lastWidth = size.width - (count * _interViewSpacing.width);

        AZTableColumn *lastColumn = _tableColumns.lastObject;

        for (NSInteger i = 0; i < count-1; ++i)
            lastWidth -= _tableColumns[i].width;

        if (lastWidth > 0)
            lastColumn.width = lastWidth;
        else if (lastWidth < 0)
            lastColumn.width = lastColumn.width + lastWidth;

        [self setNeedsDisplay:YES];
		}
	}


- (AZView *) preparedViewAtColumn:(NSInteger)columnNumber row:(NSInteger)row
	{
	AZTableColumn *column 	= [_tableColumns objectAtIndex:columnNumber];
	AZControl *dataView 	= (AZControl *)[column dataViewForRow:row];

	//[dataView setControlView:self];

    id value = [self dataSourceObjectValueForTableColumn:column row:row];
    if ([dataView isKindOfClass:AZPopupButton.class])
        [(AZPopupButton *)dataView selectItemAtIndex: [value intValue]];
	else
        {
        [dataView setObjectValue:value];
		[dataView setNeedsDisplay:YES];
		}

	SEL textColour = @selector(setTextColour:);
	if ([dataView respondsToSelector:textColour])
		{
		AZTextField *tf = (AZTextField *)dataView;

		if ([self isRowSelected:row] || [self isColumnSelected:columnNumber])
			{
			// so the selection shows properly, dont just set the colour
			// so custom background works
			[tf setIsOpaque:NO];
			[tf setTextColour:AZColour.selectedTextColour];
			}
		else
			[tf setTextColour:AZColour.textColour];
		}
   
	//[column prepareCell:dataCell inRow:row];

	SEL willShow = SELECTOR(@"tableView:willDisplayCell:forTableColumn:row:");
	if ([_delegate respondsToSelector:willShow])
		[_delegate tableView:self
			 willDisplayView:dataView
			  forTableColumn:column
						 row:row];

	return dataView;
	}

// MARK: Drawing

/*****************************************************************************\
|* Top-level view drawing routine
\*****************************************************************************/
- (void) drawInRect:(NSRect)clipRect withPainter:(AZPainter *)painter
	{
	NSRange visibleRows;
	NSInteger row;
	NSInteger numberOfRows = self.numberOfRows;

	[self drawBackgroundInClipRect:clipRect withPainter:painter];

	if (numberOfRows > 0)
		{
		[self highlightSelectionInClipRect:clipRect withPainter:painter];

		visibleRows = [self rowsInRect:clipRect];
		if (visibleRows.length > 0)
			{
			row = visibleRows.location;

			// FIXME: Always drawing entire rows is inefficient.
			//        Should draw visible cells, only.
			while ((row < NSMaxRange(visibleRows)) && (row < numberOfRows))
				[self drawRow:row++ clipRect:clipRect withPainter:painter];
			}
		}
   
	if ([self gridStyleMask])
		[self drawGridInClipRect:clipRect withPainter:painter];

	if(_draggingRow >= 0)
		{
		int W = (int) self.bounds.size.width;

		if ([self numberOfRows] == 0)
			[painter lineAtX:0 y:0 toX:W y:0 colour:AZColour.blackColour];
		else
			{
			if (_draggingRow == self.numberOfRows)
				{
				NSRect rowRect = NSIntersectionRect(
									[self rectOfRow: _draggingRow-1],
									self.visibleRect);
				[painter lineAtX:0
							   y:NSMaxY(rowRect)
							 toX:NSWidth(rowRect)
							   y:NSMaxY(rowRect)
						  colour:AZColour.blackColour];
				}
			else
				{
				NSRect rowRect = NSIntersectionRect(
									[self rectOfRow: _draggingRow],
									self.visibleRect);
				[painter lineAtX:0
							   y:NSMinY(rowRect)
							 toX:NSWidth(rowRect)
							   y:NSMinY(rowRect)
						  colour:AZColour.blackColour];
				}
			}
		}
	}

/*****************************************************************************\
|* Actually draw the highlight
\*****************************************************************************/
- (void) _drawHighlightedSelectionInRect:(NSRect)rect withPainter:(AZPainter *)P
	{
	[P rectangleWithRect:rect filled:YES colour:AZColour.selectedControlColour];
	}

/*****************************************************************************\
|* Highlight the selection within a rectangle
\*****************************************************************************/
- (void)highlightSelectionInClipRect:(NSRect)rect withPainter:(AZPainter *)P
	{
    NSInteger numberOfRows = self.numberOfRows;
    NSInteger numberOfCols = _tableColumns.count;

    for (NSInteger column = 0; column < numberOfCols; ++column)
		for (NSInteger row = 0; row < numberOfRows; ++row)
			if ([self isColumnSelected:column] || [self isRowSelected:row])
				if (!(row == _editedRow && column == _editedColumn))
					{
					NSRect r = [self frameOfViewAtColumn:column row:row];
					[self _drawHighlightedSelectionInRect:r withPainter:P];
					}
	}


/*****************************************************************************\
|* Draw a row within a rectangle
\*****************************************************************************/
- (void)drawRow:(NSInteger)row clipRect:(NSRect)rect withPainter:(AZPainter *)P
	{
    // draw only visible columns.
    NSRange visibleColumns 		= [self columnsInRect:rect];
    NSInteger drawColumn 		= visibleColumns.location;
    NSInteger numberOfRows		= self.numberOfRows;

    if (row < 0 || row >= numberOfRows)
		{
		SDL_Log("invalid row %ld (valid = 0..%ld) in drawRow:clipRect:",
				(long)row, (long)numberOfRows-1);
		return;
		}

	for(;drawColumn < NSMaxRange(visibleColumns); drawColumn++)
		{
		BOOL isEdit = (row == _editedRow) && (drawColumn == _editedColumn);
		if (isEdit && (_editingView != nil))
			{
			[P rectangleWithRect:_editingBorder
						  filled:YES
						  colour:self.backgroundColour];
			[_editingView setNeedsDisplay:YES];
			}
		else
			{
			AZView *dataView = [self preparedViewAtColumn:drawColumn row:row];
			[dataView setNeedsDisplay:YES];
			}
		}
	}

/*****************************************************************************\
|* Draw the background within a rectangle
\*****************************************************************************/
- (void)drawBackgroundInClipRect:(NSRect)rect withPainter:(AZPainter *)P
	{
	NSArray *rowColours		= AZColour.controlAlternatingRowBackgroundColours;
	NSInteger colourCount  	= rowColours.count;

	if (colourCount == 0 || !_alternatesRowColours)
		[P rectangleWithRect:rect filled:YES colour:self.backgroundColour];

	else if (colourCount == 1)
		[P rectangleWithRect:rect filled:YES colour:rowColours[0]];

	else
		{
        NSRange rangeOfRows = [self rowsInRect:rect];
        NSRect rectToFill 	= rect;
        float heightFilled 	= 0.f;
		NSInteger max 		= rangeOfRows.location + rangeOfRows.length;

		NSInteger i;
        for (i = rangeOfRows.location; i < max; i++)
			{
            rectToFill 			= [self rectOfRow:i];
			AZColour *colour	= rowColours[i % colourCount];
			[P rectangleWithRect:rectToFill filled:YES colour:colour];

			// This is for beyond the loop.
            rectToFill.origin.y += rectToFill.size.height;
            heightFilled = rectToFill.origin.y;
			}

        if (_rowHeight > 0.f)
			{
            rectToFill.size.height = _rowHeight + _interViewSpacing.height;
            while (heightFilled < rect.size.height)
				{
				AZColour *colour	= rowColours[i % colourCount];
				[P rectangleWithRect:rectToFill filled:YES colour:colour];

                heightFilled 		+= rectToFill.size.height;
                rectToFill.origin.y += rectToFill.size.height;
                i++;
				}
			}
		}
	}

/*****************************************************************************\
|* Draw the grid within a rectangle
\*****************************************************************************/
- (void)drawGridInClipRect:(NSRect)rect withPainter:(AZPainter *)P
	{
	if (IS_GRID_STYLE(_gridStyleMask, AZTableViewSolidVerticalGridLineMask))
		{
        NSRange rangeOfColumns = [self columnsInRect:rect];
        NSInteger n = rangeOfColumns.location + rangeOfColumns.length;
        for (NSInteger i = rangeOfColumns.location; i < n; i++)
			{
            NSRect columnRect = [self rectOfColumn:i];
            float x = NSMaxX(columnRect) + ((i < n-1) ? -0.5 : 0.5);
            float y1 = rect.origin.y;
			float y2 = y1 + NSHeight(rect);
			[P lineAtX:x y:y1 toX:x y:y2 colour:self.gridColour];
			}
		}

	if (IS_GRID_STYLE(_gridStyleMask, AZTableViewSolidHorizontalGridLineMask))
		{
        NSRange rangeOfRows = [self rowsInRect:rect];
        NSInteger n 		= rangeOfRows.location + rangeOfRows.length;
        float y				= -0.5;

        for (NSInteger i = rangeOfRows.location; i < n; i++)
			{
            NSRect rowRect = [self rectOfRow:i];
            float x1 	= rect.origin.x;
            y 			= NSMaxY(rowRect) - 0.5;
			float x2	= x1 + rect.size.width;
			[P lineAtX:x1 y:y toX:x2 y:y colour:self.gridColour];
			}

        if (_rowHeight > 0.0)
			{
            while (y < rect.size.height)
				{
                y 		   += _rowHeight + _interViewSpacing.height;
				float x1	= rect.origin.x;
				float x2	= x1 + rect.size.width;
				[P lineAtX:x1 y:y toX:x2 y:y colour:self.gridColour];
				}
			}
		}
	}


/*****************************************************************************\
|* Find the width of all the columns. Can't use rectOfRow because empty
|* tableviews will explode
\*****************************************************************************/
- (float) _displayWidthOfColumns
	{
    NSInteger count = _tableColumns.count;
    float result = 0;

    for (NSInteger i = 0; i < count; ++i)
        result += _tableColumns[i].width + _interViewSpacing.width;

    return result;
	}

// MARK: AZView...

/*****************************************************************************\
|* We need to resize everything
\*****************************************************************************/
-(void)resizeWithOldSuperviewSize:(NSSize)oldSize
	{
    NSSize size = self.frame.size;

    if (size.width < self.superview.bounds.size.width)
		{
		size.width = self.superview.bounds.size.width;
		[self setFrameSize:size];
		}

	if (self.autoresizeAllColumnsToFit)
		{
        float delta 	= self.enclosingScrollView.contentSize.width
						- [self _displayWidthOfColumns];
        NSInteger count = _tableColumns.count;

        for (NSInteger i = 0; i < count; ++i)
			{
            AZTableColumn *column = _tableColumns[i];
            [column setWidth:column.width + floor((delta/count))];
			}
		}
    else
        [self sizeLastColumnToFit];

	[self tile];
	}


/*****************************************************************************\
|* Check if we should select a column
\*****************************************************************************/
- (BOOL) delegateShouldSelectTableColumn:(AZTableColumn *)tableColumn
	{
	SEL shouldSelect = SELECTOR(@"tableView:shouldSelectTableColumn:");
    if ([_delegate respondsToSelector:shouldSelect])
        return [_delegate tableView:self shouldSelectTableColumn:tableColumn];

	// Default to YES
    return YES;
	}

/*****************************************************************************\
|* Check if we should select a row
\*****************************************************************************/
- (BOOL) delegateShouldSelectRow:(NSInteger)row
	{
	SEL shouldSelect = SELECTOR(@"tableView:shouldSelectRow:");
    if ([_delegate respondsToSelector:shouldSelect])
        return [_delegate tableView:self shouldSelectRow:row];

	// Default to YES
    return YES;
	}

/*****************************************************************************\
|* Set the object value back into the data-source
\*****************************************************************************/
-(void)dataSourceSetObjectValue:object
				 forTableColumn:(AZTableColumn *)tableColumn
							row:(NSInteger)row
	{
	SEL shouldSet = SELECTOR(@"tableView:setObjectValue:forTableColumn:row:");
	if([_dataSource respondsToSelector:shouldSet])
		[_dataSource tableView:self
			    setObjectValue:object
			    forTableColumn:tableColumn
						   row:row];
	}


/*****************************************************************************\
|* Abort editing
\*****************************************************************************/
-(BOOL)abortEditing
	{
    //[super abortEditing];
    _editingView = nil;
    [self setNeedsDisplayInRect:NSInsetRect(_editingBorder, -1, -1)];
    _editingFrame 	= NSMakeRect(-1,-1,-1,-1);
    _editedRow		= -1;
    _editedColumn	= -1;
    return NO;
	}

/*****************************************************************************\
|* A text-editing widget ended editing, or we did to ourselves
\*****************************************************************************/
-(void) textDidEndEditing:(NSNotification *)note
	{
    AZTableColumn *editedColumn 				= _tableColumns[_editedColumn];
    NSDictionary<NSString *, NSNumber*> *info 	= note.userInfo;

    NSInteger textMovement 	= info[AZTextMovementUserInfoKey].integerValue;
    NSInteger numberOfRows	= self.numberOfRows;

    //[_editingView endEditing:_currentEditor];

    if (_editedRow >= 0 && _editedRow < numberOfRows)
        if ([self dataSourceCanSetObjectValue])
            [self dataSourceSetObjectValue:[_editingView objectValue]
							forTableColumn:editedColumn
									   row:_editedRow];

    [self abortEditing];
    [self.window makeFirstResponder:nil];

	/*************************************************************************\
	|* Return key goes to the next row down
	\*************************************************************************/
    if (textMovement == AZReturnTextMovement)
		{
        NSInteger nextRow = _editedRow + 1;
        if (nextRow >= numberOfRows)
            nextRow = 0;

		[self selectRow:nextRow byExtendingSelection:NO];
        [self editColumn:_editedColumn row:nextRow select:YES];
		}

 	/*************************************************************************\
	|* Tab key goes to the next available editable view rightwards
	\*************************************************************************/
	else if (textMovement == AZTabTextMovement)
		{
        NSInteger nextColumn 	= _editedColumn;
        NSInteger nextRow 		= _editedRow;

        do
			{
			nextColumn++;
			if (nextColumn >= _tableColumns.count)
				{
				nextColumn=0;
				nextRow++;
				if (nextRow >= numberOfRows)
					nextRow=0;
				}

			if ([_tableColumns[nextColumn] editable])
				break;
			}
		while(YES);

        [self selectRow:nextRow byExtendingSelection:NO];
        [self editColumn:nextColumn row:nextRow select:YES];
		}

	/*************************************************************************\
	|* shift-Tab key goes to the next available editable view leftwards
	\*************************************************************************/
    else if (textMovement == AZBacktabTextMovement)
		{
        NSInteger prevColumn 	= _editedColumn-1;
        NSInteger prevRow 		= _editedRow;

        if (prevColumn < 0)
			{
            prevColumn = _tableColumns.count - 1;
            prevRow -= 1;
            if (prevRow < 0)
                prevRow = numberOfRows - 1;
			}

        [self selectRow:prevRow byExtendingSelection:NO];
        [self editColumn:prevColumn row:prevRow select:YES];
		}

	/*************************************************************************\
	|* Give up
	\*************************************************************************/
    else
		{
        _editedColumn = -1;
        _editedRow = -1;
		}
	}

/*****************************************************************************\
|* Ask the delegate if we should edit this table row/col combo
\*****************************************************************************/
- (BOOL)delegateShouldEditTableColumn:(AZTableColumn *)col row:(NSInteger)row
	{
	SEL shouldEdit = SELECTOR(@"tableView:shouldEditTableColumn:row:");
    if ([_delegate respondsToSelector:shouldEdit])
        return [_delegate tableView:self
			  shouldEditTableColumn:col
								row:row];

	// Default to YES
    return YES;
	}

/*****************************************************************************\
|* Ask the delegate if we can change the selection
\*****************************************************************************/
- (BOOL) delegateSelectionShouldChange
	{
	SEL shouldChange = SELECTOR(@"selectionShouldChangeInTableView:");
    if ([_delegate respondsToSelector:shouldChange])
        return [_delegate selectionShouldChangeInTableView:self];
    
	// Default to YES
    return YES;
	}

/*****************************************************************************\
|* Notify that the selection is changing
\*****************************************************************************/
- (void) noteSelectionIsChanging
	{
	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
    [nc postNotificationName:AZTableViewSelectionIsChangingNotification
                      object:self];
	}

/*****************************************************************************\
|* Notify that the selection actually changed
\*****************************************************************************/
- (void) noteSelectionDidChange
	{
	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
    [nc postNotificationName:AZTableViewSelectionDidChangeNotification
                      object:self];
	}
	
/*****************************************************************************\
|* Notify that the column resized, giving the old width for context
\*****************************************************************************/
- (void) noteColumnDidResizeWithOldWidth:(float)oldWidth
	{
 	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
	[nc postNotificationName:AZTableViewColumnDidResizeNotification
					  object:self
				    userInfo:@{@"AZOldWidth" : @(oldWidth)}];
	}

/*****************************************************************************\
|* Determine if the dataSource can set values as well as provide them
\*****************************************************************************/
- (BOOL) dataSourceCanSetObjectValue
	{
	SEL canWrite = SELECTOR(@"tableView:setObjectValue:forTableColumn:row:");
    return [_dataSource respondsToSelector:canWrite];
	}


// MARK: Event handling

@end
