//
//  AZTableView.m
//  Azoth
//
//  Created by Simon Gornall on 12/27/24.
//
#import <SDL3/SDL.h>

#import <Azoth/AZApplication.h>
#import "AZClipView.h"
#import "AZColour.h"
#import "AZEvent.h"
#import "AZImage.h"
#import "AZNotifications.h"
#import "AZPainter.h"
#import "AZRenderer.h"
#import "AZScrollView.h"
#import "AZTableColumn.h"
#import "AZTableHeaderView.h"
#import "AZTableRowRecord.h"
#import "AZTableView.h"
#import "AZTypes.h"
#import "AZView+Internal.h"
#import "AZWindow.h"
#import "AZZib.h"

#define DEFAULT_ROWHEIGHT		(30.f)
#define HEADER_ROWHEIGHT		(25.f)


#define DATASOURCE(src) id<AZTableViewDataSource> src = 					\
						(id<AZTableViewDataSource>)self.dataSource

#define DELEGATE(dlg) 	id<AZTableViewDelegate> dlg = 						\
						(id<AZTableViewDelegate>)self.delegate

/*****************************************************************************\
|* Define the UI
\*****************************************************************************/
enum
	{
	STATE_N	= 0,				// Normal
	STATE_H,					// Highlighted

	STATE_NUM
	};

static NSRect		_rA[STATE_NUM];
static NSInteger   	_ui[STATE_NUM];

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

// IndexSet of selection on mousedown
@property(strong, nonatomic) NSIndexSet *							draggedSet;

// Whether we've ever been tiled
@property(assign, nonatomic) BOOL									tiled;
@end

@implementation AZTableView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
-initWithFrame:(NSRect)frame
	{
    if (self = [super initWithFrame:frame])
		{
		[self _commonTableInit];
		}
    return self;
	}

/*****************************************************************************\
|* Configuration via dictionary. This is called by the NIB loader, but is a
|* valid way to create the view
\*****************************************************************************/
- (instancetype) initWithDictionary:(NSDictionary *)info;
	{
	if (self = [super initWithDictionary:info])
		{
		[self _commonTableInit];

		_usesHeader 	= [info[kZibHasHeaderView] isEqualToString:@"YES"];

		BOOL multi		= [info[kZibSelectMultiple] isEqualToString:@"YES"];
		_allowsMultipleSelection = multi;

		NSNumber *rh	= (NSNumber *) info[kZibRowHeight];
		if (rh)
			_rowHeight	= rh.intValue;

		NSArray *cols 	= nil;
		id element 		= info[kZibColumns];
		if ([element isKindOfClass:NSArray.class])
			cols = element;
		else
			cols = @[element];

		int idx = 0;
		for (NSDictionary *colInfo in cols)
			{
			NSString *ident = colInfo[kZibIdentifier];
			if (ident == nil)
				ident = [NSString stringWithFormat:@"column%d", idx];

			AZTableColumn *col = [[AZTableColumn alloc] initWithIdentifier:ident];

			NSNumber *v = (NSNumber *) colInfo[kZibMaxWidth];
			if (v)
				[col setMaxWidth:v.floatValue];

			v = (NSNumber *) colInfo[kZibMinWidth];
			if (v)
				[col setMinWidth:v.floatValue];

			v = (NSNumber *) colInfo[kZibWidth];
			if (v)
				[col setWidth:v.floatValue];
			idx ++;

			[self addTableColumn:col];
			}

		}
	return self;
	}
	
/*****************************************************************************\
|* Common initialisation between -withFrame and -withDictionary
\*****************************************************************************/
- (void) _commonTableInit
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
	self.backgroundColour 		= AZColour.controlBackground;
	self.isOpaque				= YES;
	_gridColour 				= AZColour.grid;
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
	_tiled						= NO;
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
				DATASOURCE(src);

				// Apple AppKit only logs here, so we do the same.
				SDL_Log("data source %s does not respond to "
						"numberOfRowsInTableView:",
						src.description.UTF8String);
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
		range.length = last - row;
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
    if (range.location != NSNotFound)
        row = range.location;

    return row;
	}

// MARK: Text input
/*****************************************************************************\
|* Accept first responder if asked
\*****************************************************************************/
- (BOOL) acceptsFirstResponder
	{
	return YES;
	}

/*****************************************************************************\
|* There's nothing to do if we resign first-responder
\*****************************************************************************/
- (BOOL) resignFirstResponder
	{
	return YES;
	}


// MARK: Events

/*****************************************************************************\
|* We got a key event, see if the delegate is interested
\*****************************************************************************/
- (BOOL) keyDown:(AZEvent *)e
	{
	BOOL handled 	= NO;
	SEL keySel 		= SELECTOR(@"tableView:keyDown:");
	if ([_delegate respondsToSelector:keySel])
		handled = [_delegate tableView:self keyDown:e];
	return handled;
	}

/*****************************************************************************\
|* We got a key event, see if the delegate is interested
\*****************************************************************************/
- (BOOL) keyUp:(AZEvent *)e
	{
	BOOL handled 	= NO;
	SEL keySel 		= SELECTOR(@"tableView:keyUp:");
	if ([_delegate respondsToSelector:keySel])
		handled = [_delegate tableView:self keyUp:e];
	return handled;
	}

/*****************************************************************************\
|* The mouse button was clicked
\*****************************************************************************/
- (BOOL) mouseDown:(AZEvent *)e
	{
    NSPoint at 		= [self convertPoint:e.locationInWindow fromView:nil];
    _clickedRow		= [self rowAtPoint:at];
	_draggedSet		= _selectedRowIndexes.copy;

	if ((_clickedRow >= 0) && (_clickedRow < self.numberOfRows))
		{
		if ([_selectedRowIndexes containsIndex:_clickedRow])
			[self deselectRow:_clickedRow];
		else
			[self selectRow:_clickedRow byExtendingSelection:_allowsMultipleSelection];
		}

	// If we got a mousedown, claim first responder
	[self.window makeFirstResponder:self];

	return YES;
	}

/*****************************************************************************\
|* Handle dragging the selection
\*****************************************************************************/
- (BOOL) mouseDragged:(AZEvent *)e
	{
    NSPoint at 		= [self convertPoint:e.locationInWindow fromView:nil];
	NSInteger row	= [self rowAtPoint:at];

	NSRange range	= NSMakeRange(NSNotFound, 0);
	if (row > _clickedRow)
		range = NSMakeRange(_clickedRow, row - _clickedRow);
	else if (row < _clickedRow)
		range = NSMakeRange(row, _clickedRow - row +1);

	if (range.length > 0)
		{
		_selectedRowIndexes = _draggedSet;

		if (self.allowsMultipleSelection)
			{
			NSIndexSet *changes = [NSIndexSet indexSetWithIndexesInRange:range];
			[self toggleRowIndexes:changes];
			}
		else
			[self toggleRow:row byExtendingSelection:NO];

		[self noteSelectionIsChanging];
		}
	return YES;
	}

/*****************************************************************************\
|* Handle mouse-up. Just clean up
\*****************************************************************************/
- (BOOL) mouseUp:(AZEvent *)e
	{
	_draggedSet = nil;
	return YES;
	}


// MARK: Layout and redraw

/*****************************************************************************\
|* Tile the view
\*****************************************************************************/
- (void) tile
	{
	_tiled = YES;
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
	if (!self.tiled)
		[self tile];
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

		id<AZRenderer> azr	= self.window.renderer;

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
				NSRect dst = NSMakeRect(bx, by, bw, bh);
				[azr blit9WayFrom:_ui[state]
							  src:NSMakeRect(0,0,6,_rA[state].size.height)
							scale:1.f
							 left:2.f
							right:4.f
							  top:1.f
						   bottom:1.f
						      dst:dst];
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

/*****************************************************************************\
|* Return the frame of the view at a given row,column intersection
\*****************************************************************************/
- (NSRect)frameOfViewAtColumn:(NSInteger)column row:(NSInteger)row
	{
	if ( (column < 0) || (column > self.numberOfColumns)
	   ||(row < 0) || (row > self.numberOfRows))
		return NSZeroRect;

	NSRect frame = NSMakeRect(0,0,0,0);

	for (NSInteger i = 0; i < column; i++)
		frame.origin.x += _tableColumns[i].width + _spacing.width;

	AZTableRowRecord *rec = _rowRecords[row];
	frame.origin.y = rec.start;

	frame.size.width  = _tableColumns[column].width + _spacing.width;
	frame.size.height = rec.height;

	return frame;
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

	[self _updateSelectionIndices:newIndexes];
	}

/*****************************************************************************\
|* Toggle a set of selected rows, optionally add to the selection
\*****************************************************************************/
- (void)toggleRowIndexes:(NSIndexSet *)indexes
	{
	NSInteger numRows 		= self.numberOfRows;

	// Mac OS X doesn't raise an exception if one of the indices
	// is out of range. Instead, the selection is left untouched.
	BOOL found = (indexes.firstIndex != NSNotFound);
	BOOL oub   = (indexes.firstIndex < 0) || (indexes.lastIndex > numRows);
	if (found && oub)
		return;

	NSMutableIndexSet * newIndexes = [NSMutableIndexSet new];
	[newIndexes addIndexes:_selectedRowIndexes];

	NSInteger index = indexes.firstIndex;
	while (index != NSNotFound)
		{
		if ([newIndexes containsIndex:index])
			[newIndexes removeIndex:index];
		else
			[newIndexes addIndex:index];
		index = [indexes indexGreaterThanIndex:index];
		}

	[self _updateSelectionIndices:newIndexes];
	}

/*****************************************************************************\
|* Toggle a single row
\*****************************************************************************/
- (void) toggleRow:(NSInteger)row byExtendingSelection:(BOOL)extend
	{
	if ([_selectedRowIndexes containsIndex:row])
		{
		if (extend)
			[self toggleRowIndexes:[NSIndexSet indexSetWithIndex:row]];
		else
			{
			_selectedRowIndexes = [NSIndexSet new];
			[self setNeedsDisplay:YES];
			}
		}
	else
		[self selectRow:row byExtendingSelection:extend];
	}

/*****************************************************************************\
|* Internal method to do the housekeeping after a selection change
\*****************************************************************************/
- (void) _updateSelectionIndices:(NSIndexSet *)newIndexes
	{
	BOOL changed = NO;

	// Make sure the delegate is allowing us to make changes at all...
	if (![self delegateSelectionShouldChange])
		return;


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
				}
			}

	if (changed)
		{
		// Verify that each of the selections is ok to change
		NSMutableIndexSet *verified = [NSMutableIndexSet new];

		NSInteger index = newIndexes.firstIndex;
		while (index != NSNotFound)
			{
			if ([self delegateShouldSelectRow:index])
				[verified addIndex:index];
			index = [newIndexes indexGreaterThanIndex:index];
			}
			if (verified.count || (newIndexes.count == 0))
			{
			// Let the delegate know that we're about to change
			[self noteSelectionWillChange];

			// Then do the selection
			[self _setSelectedRowIndexes:verified];
			}
		}
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



// MARK: Send/Receive notifications

/*****************************************************************************\
|* Properly replace the delegate, invalidating any old notifications etc.
\*****************************************************************************/
- (void) setDelegate:(id)delegate
	{
	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;

    AZNotifyMap notes[] =
		{
			{ AZTableViewSelectionDidChangeNotification,
			  @selector(tableViewSelectionDidChange:) },
			{ AZTableViewColumnDidMoveNotification,
			  @selector(tableViewColumnDidMove:) },
			{ AZTableViewColumnDidResizeNotification,
			  @selector(tableViewColumnDidResize:) },
			{ AZTableViewSelectionIsChangingNotification,
			  @selector(tableViewSelectionIsChanging:) },
			{ AZTableViewSelectionWillChangeNotification,
			  @selector(tableViewSelectionWillChange:) },
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
	[self _generateHeightAndOffsetData];

    // if there's any editing going on, we'd better stop it.
    if (_editingView != nil)
		[self textDidEndEditing:nil];

    if (numberOfRows > 0)
        size.width = [self _rectOfRow:0].size.width;

    if (_tableColumns.count > 0)
        size.height = [self _rectOfColumn:0].size.height;

    headerSize.width = size.width;

	if (size.width < self.frame.size.width)
		size.width = self.frame.size.width;
		
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
|* Notify that the selection will change
\*****************************************************************************/
- (void) noteSelectionWillChange
	{
	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
    [nc postNotificationName:AZTableViewSelectionWillChangeNotification
                      object:self];
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
			[self selectRowIndexes:set
			  byExtendingSelection:self.allowsMultipleSelection];
		}
	else
		{
		set = [NSIndexSet indexSetWithIndex:row];
		[self selectRowIndexes:set byExtendingSelection:NO];
		}
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

	// Sanity check, because we'll probably crash later...
	if (_delegate == nil)
		SDL_Log("No delegate set on %s",
				self.class.description.UTF8String);
				
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
	SEL willDisplay = SELECTOR(@"tableView:willDisplayView:forTableColumn:row:");

	// Sanity check
	if (rowToDisplay >= _rowRecords.count)
		{
		//SDL_Log("No data to display in %s", self.class.description.UTF8String);
		return;
		}
    int x, y, rowHeight, viewHeight;
    do
		{
        [visible addIndex: rowToDisplay];
		x 	= 0;
        y 	= _rowRecords[rowToDisplay].start;
        rowHeight 	= _rowRecords[rowToDisplay].height;
		viewHeight 	= rowHeight- _spacing.height;

		for (AZTableColumn *col in _tableColumns)
			{
			AZView *view = [col dataViewForRow:rowToDisplay];
			view.postsFrameNotifications = NO;
			NSRect frame = NSMakeRect(x, y, col.width, viewHeight);
			[view setFrame:frame];
			x += col.width + _spacing.width;

			if ([_delegate respondsToSelector:willDisplay])
				[_delegate tableView:self
					 willDisplayView:view
					  forTableColumn:col
								 row:rowToDisplay];

			[self addSubview:view];
			}
        rowToDisplay++;
		}
    while ((y + rowHeight < currentEndY) && (rowToDisplay < max));

    [self _returnNonVisibleRowsToThePool: visible];
	}

/*****************************************************************************\
|* Populate the rectangles from the UI texture atlas.
\*****************************************************************************/
- (void) _fetchRects
	{
	_rA[STATE_N]   	= [AZApp srcRectFor:@"tableview-rowview" in:kUiMap];
	_rA[STATE_H]   	= [AZApp srcRectFor:@"menu-bar-window-background-selected"
									 in:kUiMap];

	/*************************************************************************\
	|* Use the single-pixel-wide strips above to make 9-way-tileable textures
	|* to use to render any-size table-row backgrounds
	\*************************************************************************/
	NSSize nSz			= NSMakeSize(1, _rA[STATE_N].size.height);
	NSSize hSz			= NSMakeSize(1, _rA[STATE_H].size.height);

	id<AZRenderer> azr	= self.window.renderer;
	_ui[STATE_N] 		= [azr createTextureOfSize:nSz];
	_ui[STATE_H] 		= [azr createTextureOfSize:hSz];

	[azr setTexture:_ui[STATE_N] blendMode:SDL_BLENDMODE_NONE];
	[azr setTexture:_ui[STATE_H] blendMode:SDL_BLENDMODE_NONE];

	/*************************************************************************\
	|* Fill the texture data
	\*************************************************************************/
	NSInteger ui	= [AZApp textureFor:kUiMap];
	[azr lockFocusOn:_ui[STATE_N]];
	NSRect src = _rA[STATE_N];
	src.size.height = 3;
	[azr blitFrom:ui src:src dst:NSMakeRect(0,0,1,3)];

	src.origin.y = _rA[STATE_N].size.height - 3;
	[azr blitFrom:ui src:src dst:NSMakeRect(0,nSz.height-3,1,3)];

	src.origin.y = 3;
	src.size.height = _rA[STATE_N].size.height - 6;
	[azr tileFrom:ui src:src dst:NSMakeRect(0,3,1,nSz.height-6)];
	[azr unlockFocus];

	[azr lockFocusOn:_ui[STATE_H]];
	src = _rA[STATE_H];
	src.size.height = 3;
	[azr blitFrom:ui src:src dst:NSMakeRect(0,0,1,3)];

	src.origin.y = _rA[STATE_H].size.height - 3;
	[azr blitFrom:ui src:src dst:NSMakeRect(0,nSz.height-3,1,3)];

	src.origin.y = 3;
	src.size.height = _rA[STATE_H].size.height - 6;
	[azr tileFrom:ui src:src dst:NSMakeRect(0,3,1,nSz.height-6)];
	[azr unlockFocus];
	}

/*****************************************************************************\
|* Return the rect for a given row
\*****************************************************************************/
- (NSRect) _rectOfRow:(NSInteger)row
	{
    if (row < 0 || row >= self.numberOfRows)
        return NSZeroRect;

	NSRect rect;
	AZTableRowRecord *rec 	= _rowRecords[row];
	rect.origin.y 			= rec.start;
    rect.origin.x 			= 0.f;
	rect.size.width 		= 0.f;
	rect.size.height		= rec.height;

	NSInteger count 		= _tableColumns.count;
	for (NSInteger i = 0; i < count; i++)
		rect.size.width += _tableColumns[i].width + _spacing.width;

    return rect;
	}

/*****************************************************************************\
|* Return the rect for a given column
\*****************************************************************************/
- (NSRect) _rectOfColumn:(NSInteger)column
	{
    NSInteger numberOfRows 	= self.numberOfRows;
    NSInteger numberOfCols 	= _tableColumns.count;
    NSRect rect 			= self.bounds;

    if (column < 0 || column >= numberOfCols)
		{
        SDL_Log("_rectOfColumn: invalid index %d (valid {%d, %d})",
				(int)column, 0, (int)numberOfCols);
		return NSZeroRect;
		}

	rect.origin.y 			= 0.;
    rect.size.width 		= _tableColumns[column].width + _spacing.width;
	rect.origin.x 			= 0.;
    for (NSInteger i = 0; i < column; i++)
        rect.origin.x += _tableColumns[i].width + _spacing.width;

	AZTableRowRecord *rec 	= _rowRecords[numberOfRows-1];
	rect.size.height 		= rec.height + rec.start + _spacing.height;
	rect.size.height 		= MAX(NSHeight(rect),
								  self.superview.bounds.size.height);
    return rect;
	}

@end
