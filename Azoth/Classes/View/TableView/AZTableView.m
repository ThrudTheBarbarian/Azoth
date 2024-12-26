//
//  AZTableView.m
//  Azoth
//
//  Created by Simon Gornall on 12/25/24.
//

#import <SDL3/SDL.h>

#import "AZColour.h"
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
@property(strong, nonatomic) AZView *					editingView;

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

@end
