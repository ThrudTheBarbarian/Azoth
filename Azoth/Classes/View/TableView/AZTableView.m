//
//  AZTableView.m
//  Azoth
//
//  Created by Simon Gornall on 12/27/24.
//
#import <SDL3/SDL.h>

#import "AZApp.h"
#import "AZClipView.h"
#import "AZColour.h"
#import "AZEvent.h"
#import "AZNotifications.h"
#import "AZPainter.h"
#import "AZRenderer.h"
#import "AZScrollView.h"
#import "AZTableColumn.h"
#import "AZTableHeaderView.h"
#import "AZTableRowRecord.h"
#import "AZTableView.h"
#import "AZView+Internal.h"

#define DEFAULT_ROWHEIGHT		(30.f)
#define HEADER_ROWHEIGHT		(25.f)

/*****************************************************************************\
|* Define the UI
\*****************************************************************************/
enum
	{
	STATE_N	= 0,				// Normal
	STATE_H,					// Highlighted

	STATE_NUM
	};

static NSRect	_rT[STATE_NUM];
static NSRect	_rM[STATE_NUM];
static NSRect	_rB[STATE_NUM];


/*****************************************************************************\
|* "private" methods / properties
\*****************************************************************************/
@interface AZTableView()

// Offsets and heights of the rows in the table
@property(strong, nonatomic) NSMutableArray<AZTableRowRecord *> *	rowRecords;

// Pool of cached views
@property(strong, nonatomic)
NSMutableDictionary<NSString*, NSMutableSet<AZView *> *> *			pool;

// The indexes of rows which we are currently showing
@property (strong, nonatomic, nullable) NSMutableIndexSet* 			visibleRows;

// The current offset of the tableview
@property (assign, nonatomic) NSPoint		 						offset;

// The View being used as an editor
@property(strong, nonatomic) AZControl *							editingView;

// row edited
@property(assign, nonatomic, readonly) NSInteger					editedRow;

// row clicked on
@property(assign, nonatomic, readonly) NSInteger					clickedRow;


@end

@implementation AZTableView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
-initWithFrame:(NSRect)frame
	{
    if (self = [super initWithFrame:frame])
		{
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken,
			^{
			[self _fetchRects];
			});

		_rowHeight 					= DEFAULT_ROWHEIGHT;
		_spacing 					= NSMakeSize(3.0,1.0);
		_offset				 		= NSMakePoint(0,0);

		// the default isn't actually given in the spec, but this seems
		// more like default behavior
		_autoresizeColumns 			= YES;

		_tableColumns 				= [NSMutableArray  new];
		self.backgroundColour 		= AZColour.controlBackgroundColour;
		_gridColour 				= AZColour.gridColour;
		_gridStyleMask 				= AZTableViewSolidGridLineMask;
		_alternateRowColours 		= NO;
		_usesHeader					= NO;
		_headerView				 	= nil;
		_pool 						= [NSMutableDictionary new];
		_visibleRows			 	= [NSMutableIndexSet new];
		_selectedRowIndexes 		= [NSIndexSet new];
		_editedRow 					= -1;
		_allowsMultipleSelection 	= YES;
		_allowsEmptySelection 		= YES;
		}
    return self;
	}


/*****************************************************************************\
|* Clean up on dealloc
\*****************************************************************************/
- (void) dealloc
	{
	[NSNotificationCenter.defaultCenter removeObserver:self];
	}

// MARK: Rows and columns

/*****************************************************************************\
|* Return the number of rows
\*****************************************************************************/
- (NSInteger) numberOfRows:(BOOL)recount
	{
	if (recount)
		_numberOfRows = -1;
	return [self numberOfRows];
	}

- (NSInteger) numberOfRows
	{
    if (_numberOfRows < 0)
		{
		if (_dataSource == nil)
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
|* Add/remove a table column
\*****************************************************************************/
-(void)addTableColumn:(AZTableColumn *)column
	{
    [_tableColumns addObject:column];
    [column setTableView:self];
	}

-(void)removeTableColumn:(AZTableColumn *)column
	{
    [column setTableView:nil];
    [_tableColumns removeObject:column];
	}

/*****************************************************************************\
|* Return the number of columns
\*****************************************************************************/
-(NSInteger) numberOfColumns
	{
    return _tableColumns.count;
	}

/*****************************************************************************\
|* Return a range indicating which rows are within a given rect
\*****************************************************************************/
- (NSRange) rowsInRect:(NSRect)rect
	{
    NSRange range 			= NSMakeRange(0, 0);
    NSInteger numberOfRows	= self.numberOfRows;
	float height 			= rect.origin.y;
	NSInteger row 			= -1;

    for (NSInteger i = 0; i < numberOfRows; i++)
		{
		AZTableRowRecord *rec = _rowRecords[i];
		if ((rec.start <= height) && (rec.start + rec.height > height))
			{
			row = i;
			break;
			}
		}

    if (row >= 0)
		{
        range.location = row;
		NSInteger last = row;

        for (NSInteger i = row; i < numberOfRows; i++)
			{
			AZTableRowRecord *rec = _rowRecords[i];
			if ((rec.start <= height) && (rec.start + rec.height > height))
				{
				last = i;
				break;
				}
			}
		range.length = last - row + 1;
		}
	else
		range = NSMakeRange(NSNotFound, 0);

    return range;
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


// MARK: Events

/*****************************************************************************\
|* The mouse button was clicked
\*****************************************************************************/
- (BOOL) mouseDown:(AZEvent *)e
	{
    NSPoint at 		= [self convertPoint:e.locationInWindow fromView:nil];
    _clickedRow		= [self rowAtPoint:at];

	if ((_clickedRow >= 0) && (_clickedRow < self.numberOfRows))
		{
		if ([_selectedRowIndexes containsIndex:_clickedRow])
			[self deselectRow:_clickedRow];
		else
			[self selectRow:_clickedRow byExtendingSelection:_allowsMultipleSelection];
		}

	return YES;
	}


// MARK: Layout and redraw

/*****************************************************************************\
|* Tile the view
\*****************************************************************************/
- (void) tile
	{
	if (self.autoresizeColumns)
		{
		int num = (int) _tableColumns.count;

		int width = (self.bounds.size.width - (num-1) * _spacing.width)  / num;
		for (AZTableColumn *col in _tableColumns)
			col.width = width;
		}
	else
		[self sizeLastColumnToFit];
	[self.headerView setNeedsDisplay:YES];
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
        float lastWidth = size.width - (count * _spacing.width);

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

/*****************************************************************************\
|* Tell the tableview to reload its data
\*****************************************************************************/
- (void) reloadData
	{
    [self _returnNonVisibleRowsToThePool: nil];
    [self _generateHeightAndOffsetData];
    [self _layoutTableRows];
	}

/*****************************************************************************\
|* Emulate 'scrollToPoint' in the clipview
\*****************************************************************************/
- (void) scrollToPoint:(NSPoint)point
	{
	_offset = point;
	[self reloadData];
	[self setNeedsDisplay:YES];
	}

/*****************************************************************************\
|* Return the size of the texture to create. This is used when the view could
|* possibly grow outside of the size-limit of a GPU texture - eg when inside
|* an enormous scrollview. In that instance, it ought to implement the clipView
|* delegate -scrollToPoint:(NSPoint) to get where it is "scrolled" to, and
|* handle drawing specially with a window-sized texture rather than a backing-
|* sized texture. By default this method just returns the view's frame.size
\*****************************************************************************/
- (NSSize) textureSize
	{
	AZScrollView *sv = self.enclosingScrollView;
	if (sv)
		return sv.frame.size;
	return self.frame.size;
	}

/*****************************************************************************\
|* The companion method is -(BOOL)directRendering which turns off the view
|* translation and will always render from 0,0->W,H (where W,H are taken from
|* -(NSSize)textureSize. The default return from this method is NO
\*****************************************************************************/
- (BOOL) directRendering
	{
	return YES;
	}

/*****************************************************************************\
|* Draw the background
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[super drawInRect:dirtyRect withPainter:painter];
	[self drawRowBackgroundsWithPainter:painter];
	if (self.gridStyleMask)
		[self drawGridWithPainter:painter];
	}

/*****************************************************************************\
|* Draw the row background
\*****************************************************************************/
- (void) drawRowBackgroundsWithPainter:(AZPainter *)painter
	{
	if (_numberOfRows > 0)
		{
		float y 	= _rowRecords[0].start - _offset.y;
		float yMax 	= self.textureSize.height;
		float w		= self.bounds.size.width;

		AZRenderer *azr = AZRenderer.renderer;
		NSInteger ui	= AZApp.sharedInstance.ui;

		int idx = 0;
		while ((y < yMax) && (idx < _numberOfRows))
			{
			y = _rowRecords[idx].start - _offset.y - _spacing.height/2.f;
			float bx = 0;
			float by = y;
			float bw = w;
			float bh = _rowRecords[idx].height;
			if (by+bh >= 0)
				{
				int state	= [_selectedRowIndexes containsIndex:idx];
				NSRect sT	= _rT[state];
				NSRect sM	= _rM[state];
				NSRect sB	= _rB[state];

				NSRect dT	= {bx, by, bw, sT.size.height};

				NSRect dM	= {bx,
							   by+sT.size.height,
							   bw,
							   bh - sT.size.height - sB.size.height};

				NSRect dB	= {bx,
							   by+dM.size.height,
							   bw,
							   sB.size.height};

				[azr tileFrom:ui src:sT dst:dT];
				[azr tileFrom:ui src:sM dst:dM];
				[azr tileFrom:ui src:sB dst:dB];
				}
			idx ++;
			}
		}
	}

/*****************************************************************************\
|* Draw the grid. Note that this takes into account the offset of the
|* enclosing scrollview (well, clipview of the scrollview) so the co-ordinates
|* in local space are mapped correctly when blitted into global space.
\*****************************************************************************/
- (void) drawGridWithPainter:(AZPainter *)painter
	{
	if (_numberOfRows > 0)
		{
		if (_gridStyleMask & AZTableViewSolidVerticalGridLineMask)
			{
			float x 	= - _offset.x;
			float xMax	= self.bounds.size.width;
			float y		= self.bounds.origin.y;
			float h		= self.bounds.size.height;
			int idx		= 0;
			while ((x < xMax) && (idx < self.numberOfColumns))
				{
				if (x >= 0)
					[painter lineAtX:x y:y toX:x y:h colour:self.gridColour];
				x += _tableColumns[idx].width + _spacing.width/2;
				idx ++;
				}
			}

		if (_gridStyleMask & AZTableViewSolidHorizontalGridLineMask)
			{
			float y 	= _rowRecords[0].start - _offset.y - _spacing.height/2.f;
			float yMax 	= self.textureSize.height;
			float w		= self.bounds.size.width;

			int idx = 0;
			while ((y < yMax) && (idx < _numberOfRows))
				{
				y = _rowRecords[idx].start - _offset.y - _spacing.height/2.f;
				if (y >= 0)
					[painter lineAtX:0 y:y toX:w y:y colour:self.gridColour];

				idx ++;
				}
			}
		}
	}


// MARK: Selection

/*****************************************************************************\
|* Number of rows selected (invalidates the single-row property)
\*****************************************************************************/
- (NSInteger) numberOfSelectedRows
	{
    return _selectedRowIndexes.count;
	}

/*****************************************************************************\
|* Is a particular row selected
\*****************************************************************************/
- (BOOL)isRowSelected:(NSInteger)row
	{
    return [_selectedRowIndexes containsIndex:row];
	}

/*****************************************************************************\
|* Set a set of selected rows, optionally add to the selection
\*****************************************************************************/
- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend
	{
	NSIndexSet * newIndexes = nil;
	BOOL changed 			= NO;
	NSInteger numRows 		= self.numberOfRows;

	// Mac OS X doesn't raise an exception if one of the indices
	// is out of range. Instead, the selection is left untouched.
	BOOL found = (indexes.firstIndex != NSNotFound);
	BOOL oub   = (indexes.firstIndex < 0) || (indexes.lastIndex > numRows);
	if (found && oub)
		return;

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
|* Internal housekeeping setter that other methods call
\*****************************************************************************/
-(void)_setSelectedRowIndexes:(NSIndexSet *)value
	{
	_selectedRowIndexes = value;

	if ((_selectedRowIndexes.count == 0) && (!_allowsEmptySelection))
		_selectedRowIndexes = [[NSIndexSet alloc] initWithIndex:0];

	[self noteSelectionDidChange];
	}



// MARK: Send notifications

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
|* Select a row, optionally extending the selection
\*****************************************************************************/
- (void) selectRow:(NSInteger)row byExtendingSelection:(BOOL)extend
	{
	NSIndexSet *set = nil;
	if (extend)
		{
		set = [NSIndexSet indexSetWithIndex:row];
		[self selectRowIndexes:set byExtendingSelection:YES];
		}
	else
		{
		set = [NSIndexSet indexSetWithIndex:row];
		[self selectRowIndexes:set byExtendingSelection:NO];
		}
	}



// MARK: Editing...

/*****************************************************************************\
|* A text-editing widget ended editing, or we did to ourselves
\*****************************************************************************/
-(void) textDidEndEditing:(NSNotification *)note
	{
#if 0
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
#endif
	}



// MARK: View pool management

/*****************************************************************************\
|* Return an AZView from the pool of views we have, or nil if there's none
|* left of that type. If we don't find one, we create the set for next time
|* around...
\*****************************************************************************/
- (nullable AZView *) dequeueViewWithIdentifier:(NSString *)identifier
	{
	AZView *view = nil;

	NSMutableSet *set = _pool[identifier];
	if (set)
		{
		view = set.anyObject;
		if (view)
			[set removeObject:view];
		}
	else
		_pool[identifier] = [NSMutableSet new];

	return view;
	}

/*****************************************************************************\
|* Allow the table columns to repopulate the pool. Views should be in the
|* column's cache, or in the pool, but not in both. The column will return
|* the views to the pool when the tableview's -tile method is called
\*****************************************************************************/
- (void) addToPool:(NSArray<AZView *> *)views
	{
	for (AZView *view in views)
		{
		NSString *identifier = [view identifier];
		NSMutableSet *set 	 = _pool[identifier];

		if (set == nil)
			{
			set = [NSMutableSet new];
			_pool[identifier] = set;
			}
		[set addObject:view];
		}
	}

/*****************************************************************************\
|* Enable the header views. Can be called simply by setting a title on a column
\*****************************************************************************/
- (void) setUsesHeader:(BOOL)usesHeader
	{
	if (usesHeader != _usesHeader)
		{
		_usesHeader = usesHeader;
		if (_usesHeader == YES)
			[self _makeHeaderViewIfNeeded];

		[self tile];
		}
	}

// MARK: Private methods

/*****************************************************************************\
|* Make the header view if it's currently nil. Note that we don't need to add
|* the headerview to the tableview, it's the scrollview that manages it, and
|* the scrollview will query for a non-nil header-view.
\*****************************************************************************/
- (void) _makeHeaderViewIfNeeded
	{
	if (_headerView == nil)
		{
		NSRect bounds	= self.bounds;
		NSRect frame 	= NSMakeRect(0, 0, NSWidth(bounds), HEADER_ROWHEIGHT);
		_headerView 	= [[AZTableHeaderView alloc] initWithFrame:frame];
		_headerView.autoresizingMask = AZViewWidthSizable;
		_headerView.tableView = self;
		}
	}

/*****************************************************************************\
|* Figure out which rows we can return to the pool
\*****************************************************************************/
- (void) _returnNonVisibleRowsToThePool:(NSMutableIndexSet*)current
	{
    [self.visibleRows removeIndexes:current];
	for (AZTableColumn *col in _tableColumns)
		[col returnViewsInSet:self.visibleRows];
    self.visibleRows = current;
	}

/*****************************************************************************\
|* Figure out how tall each row is, and what the row offset is
\*****************************************************************************/
- (void) _generateHeightAndOffsetData
	{
	SEL perRow = SELECTOR(@"tableView:heightOfRow:");
	BOOL checkHeightForEachRow = [_delegate respondsToSelector:perRow];

    NSMutableArray* newRecords 	= [NSMutableArray new];
	NSInteger numberOfRows 		= [self numberOfRows:YES];

    float currentOffsetY 		= 0.f;
    AZTableRowRecord* record	= nil;
    for (NSInteger row = 0; row < numberOfRows; row++)
		{
        record 			= [AZTableRowRecord new];
        float rowHeight	= checkHeightForEachRow
						? [_delegate tableView:self heightOfRow:row]
						: _rowHeight;

        record.height	= rowHeight + _spacing.height;
		record.start 	= currentOffsetY + _spacing.height;
        currentOffsetY 	= currentOffsetY + rowHeight + _spacing.height;

        [newRecords insertObject:record atIndex: row];
		}

    _rowRecords = newRecords;

	[self setFrameSize:NSMakeSize(self.bounds.size.width, currentOffsetY)];
	}

/*****************************************************************************\
|* Find the row index for a given Y co-ordinate, within a range
\*****************************************************************************/
- (NSInteger) findRowForOffsetY:(float)yPosition inRange:(NSRange)range
	{
	NSInteger row = 0;

	NSInteger max = self.rowRecords.count;
    if (max > 0)
		{
		AZTableRowRecord* record = [AZTableRowRecord new];
		record.start 			 = yPosition;

    	row  = [_rowRecords indexOfObject:record
							inSortedRange:NSMakeRange(0, max)
								  options:NSBinarySearchingInsertionIndex
						  usingComparator:
							^NSComparisonResult(AZTableRowRecord* row1,
												AZTableRowRecord* row2)
								{
								if (row1.start < row2.start)
									return NSOrderedAscending;
								return NSOrderedDescending;
								}];
		}
	return (row == 0) ? 0 : row-1;
	}

/*****************************************************************************\
|* Lay out the views so they make a table
\*****************************************************************************/
- (void) _layoutTableRows
	{
	AZClipView *clipview		= self.enclosingClipView;
    float currentStartY 		= clipview.scrollPoint.y;
    float currentEndY 			= currentStartY + clipview.frame.size.height;

	NSInteger max 				= self.rowRecords.count;
	NSRange range				= NSMakeRange(0, max);
    NSInteger rowToDisplay 		= [self findRowForOffsetY:currentStartY
												  inRange:range];

    NSMutableIndexSet* visible	= [NSMutableIndexSet new];

    int x, y, rowHeight, viewHeight;
    do
		{
        [visible addIndex: rowToDisplay];
		x 	= 0;
        y 	= _rowRecords[rowToDisplay].start;
        rowHeight 	= _rowRecords[rowToDisplay].height;
		viewHeight 	= rowHeight - _spacing.height;

		for (AZTableColumn *col in _tableColumns)
			{
			AZView *view = [col dataViewForRow:rowToDisplay];
			view.postFrameNotifications = NO;
			NSRect frame = NSMakeRect(x, y, col.width, viewHeight);
			[view setFrame:frame];
			x += col.width + _spacing.width;

			[self addSubview:view];
			}
        rowToDisplay++;
		}
    while ((y + rowHeight < currentEndY) && (rowToDisplay < max));

    [self _returnNonVisibleRowsToThePool: visible];
	}

/*****************************************************************************\
|* Populate the rectangles from the UI texture atlas
\*****************************************************************************/
- (void) _fetchRects
	{
	AZApp *app		= AZApp.sharedInstance;

	_rM[STATE_N]   = [app srcRectFor:@"tableview-rowview"];
	_rM[STATE_H]   = [app srcRectFor:@"menu-bar-window-background-selected"];

	// Split by height so we can tile any row-height
	for (int i=0; i<STATE_NUM; i++)
		{
		_rT[i] = _rM[i];
		_rB[i] = _rM[i];

		_rT[i].size.height = 5;

		_rB[i].size.height = 5;
		_rB[i].origin.y += (_rM[i].size.height - 5);

		_rM[i].size.height -= 10;
		_rM[i].origin.y += 5;
		}
	}

@end
