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
#import "AZPainter.h"
#import "AZScrollView.h"
#import "AZTableColumn.h"
#import "AZTableRowRecord.h"
#import "AZTableView.h"
#import "AZView+Internal.h"

#define DEFAULT_ROWHEIGHT		(25.f)

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

@end

@implementation AZTableView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
-initWithFrame:(NSRect)frame
	{
    if (self = [super initWithFrame:frame])
		{
		_rowHeight 					= DEFAULT_ROWHEIGHT;
		_spacing 					= NSMakeSize(3.0,1.0);
		_offset				 		= NSMakePoint(0,0);

		// the default isn't actually given in the spec, but this seems
		// more like default behavior
		_autoresizeColumns 			= YES;

//		float height				= _rowHeight + _spacing.height;
//		float width					= NSWidth(self.bounds);
//		NSRect headerRect			= NSMakeRect(0,0,width,height);

		_tableColumns 				= [NSMutableArray  new];
		self.backgroundColour 		= AZColour.controlBackgroundColour;
		_gridColour 				= AZColour.gridColour;
		_gridStyleMask 				= AZTableViewSolidGridLineMask;
		_alternateRowColours 		= NO;

		_pool 						= [NSMutableDictionary new];
		_visibleRows			 	= [NSMutableIndexSet new];
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

    //[_headerView setNeedsDisplay:YES];
	}

-(void)removeTableColumn:(AZTableColumn *)column
	{
    [column setTableView:nil];
    [_tableColumns removeObject:column];

    //[_headerView setNeedsDisplay:YES];
	}

/*****************************************************************************\
|* Return the number of columns
\*****************************************************************************/
-(NSInteger) numberOfColumns
	{
    return _tableColumns.count;
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
	if (self.gridStyleMask)
		[self drawGridWithPainter:painter];
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
			float h		= self.bounds.size.height;
			int idx		= 0;
			while ((x < xMax) && (idx < self.numberOfColumns))
				{
				if (x >= 0)
					[painter lineAtX:x y:0 toX:x y:h colour:self.gridColour];
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
					{
					[painter lineAtX:0 y:y toX:w y:y colour:self.gridColour];
					}
				idx ++;
				}
			}
		}
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

// MARK: Private methods

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

    
  //  NSLog(@"laying out %d rows", (int)visible.count);

    [self _returnNonVisibleRowsToThePool: visible];
	}

@end
