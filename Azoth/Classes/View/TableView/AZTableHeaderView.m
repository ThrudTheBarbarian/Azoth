//
//  AZTableHeaderView.m
//  Azoth
//
//  Created by Simon Gornall on 12/25/24.
//
#if 0
#import <SDL3/SDL.h>

#import "AZEvent.h"
#import "AZTableColumn.h"
#import "AZTableColumn+Private.h"
#import "AZTableHeaderView.h"
#import "AZTableView.h"
#import "AZWindow.h"

@interface AZTableView(NSTableView_private)
-(void)noteColumnDidResizeWithOldWidth:(float)oldWidth;
@end

@interface AZTableHeaderView()
@property(assign, nonatomic) BOOL							activelyResizing;
@property(assign, nonatomic) float							oldColumnWidth;
@property(assign, nonatomic) NSPoint						resizeLocation;
@property(strong, nonatomic) AZTableColumn *				resizingColumn;
@end

@implementation AZTableHeaderView


/*****************************************************************************\
|* The size of the rectangle for the header view of a given column
\*****************************************************************************/
- (NSRect) headerRectOfColumn:(NSInteger)column
	{
    NSArray<AZTableColumn *> * cols = _tableView.tableColumns;
    NSRect headerRect 				= self.bounds;
    NSSize sz 						= _tableView.spacing;

    if (column < 0 || column >= cols.count)
		{
		SDL_Log("headerRectOfColumn: invalid index %d (valid {%d, %d})",
				(int)column, 0, (int)cols.count);
		return headerRect;
		}

    headerRect.size.width = [cols objectAtIndex:column--].width + sz.width;
    while (column >= 0)
        headerRect.origin.x += [cols objectAtIndex:column--].width + sz.width;
    return headerRect;
	}

/*****************************************************************************\
|* Which column occupies a passed-in point
\*****************************************************************************/
- (NSInteger) columnAtPoint:(NSPoint)p
	{
    NSInteger count = _tableView.tableColumns.count;

    for (NSInteger i = 0; i < count; ++i)
        if (NSPointInRect(p, [self headerRectOfColumn:i]))
            return i;

    return NSNotFound;
	}

/*****************************************************************************\
|* Draw in the provided rect
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	NSArray<AZTableColumn *> *cols 	= _tableView.tableColumns;
    NSInteger count 				= cols.count;
    NSRect columnRect 				= self.bounds;
    NSSize spacing 					= _tableView.spacing;

    for (NSInteger i = 0; i < count; ++i)
		{
        AZTableColumn *column = [cols objectAtIndex:i];
        columnRect.size.width 	= column.width + spacing.width;
		NSInteger idx			= [cols indexOfObject:column];
		[column.headerView setHighlighted:[_tableView isColumnSelected:idx]];
		[column.headerView setFrame:columnRect];
		[column.headerView setNeedsDisplay:YES];
        columnRect.origin.x += [column width] + spacing.width;
		}
	}

// Event handling

/*****************************************************************************\
|* We got a mouse click in the header view
\*****************************************************************************/
- (BOOL) mouseDown:(AZEvent *)e
	{
	_activelyResizing 	= NO;

 	NSArray<AZTableColumn *> *cols 	= _tableView.tableColumns;
	_resizeLocation = [self convertPoint:e.locationInWindow fromView:nil];

    NSInteger col 					= [self columnAtPoint:_resizeLocation];
	id<AZTableViewDelegate>delegate	= _tableView.delegate;

	SEL mdSel = @selector(tableView:mouseDownInHeaderOfTableColumn:);
    if ([delegate respondsToSelector:mdSel])
        [delegate tableView:_tableView
				  mouseDownInHeaderOfTableColumn:[cols objectAtIndex:col]];

    if (_tableView.allowsColumnResizing)
		{
        NSInteger count = cols.count;

        // if there is any editing going on, we have to end it. Apple ends
        // editing, sends the setObjectValue, but does NOT select any
        // following cells. sending nil to textDidEndEditing will cause a 0
        // or NSIllegalTextMovement, so no editing chain stuff will happen.
        if ((_tableView.editedColumn != -1) || (_tableView.editedRow) != -1)
            [[self window] endEditingFor:nil];

        for (NSInteger i = 1; i < count; ++i)
			{
            if (NSPointInRect(_resizeLocation, [self _resizeRectBeforeColumn:i]))
				{
                _resizingColumn 	= [cols objectAtIndex:i-1];
                _oldColumnWidth		= [_resizingColumn width];

                if (![_resizingColumn resizable])
                    return NO;

                _resizedColumn 		= i - 1;
				_activelyResizing 	= YES;
				_resizeLocation 	= [self convertPoint:e.locationInWindow
												fromView:nil];
                return YES;
				}
			}
		}
	
    if ([_tableView allowsColumnSelection])
		{
		// extend/change selection
        if (e.modifierFlags & AZAlternateKeyMask)
			{
            // deselect previously selected?
            if ([_tableView isColumnSelected:col])
                [_tableView deselectColumn:col];
            else if ([_tableView allowsMultipleSelection] == YES)
				// add to selection
                [_tableView selectColumn:col byExtendingSelection:YES];

			}
        else if (e.modifierFlags & AZShiftKeyMask)
			{
            NSInteger startColumn 	= _tableView.selectedColumn;
            NSInteger endColumn 	= col;

            if (startColumn == -1)
                startColumn = 0;
            if (startColumn > endColumn)
				{
                endColumn 	= startColumn;
                startColumn = col;
				}

            [_tableView deselectAll:nil];
            while (startColumn <= endColumn)
                [_tableView selectColumn:startColumn++ byExtendingSelection:YES];
			}
        else
            [_tableView selectColumn:col byExtendingSelection:NO];
		}
	
	[[_tableView.tableColumns objectAtIndex:col] _sort];
	return YES;
	}

- (BOOL) mouseDragged:(AZEvent *)e
	{
	if (_activelyResizing)
		{
		// greatly simplified code...
		NSRect newRect;

		NSPoint newPoint=[self convertPoint:[e locationInWindow] fromView:nil];
		float newWidth=newPoint.x;

		for (NSInteger q = 0; q < _resizedColumn; ++q)
			{
			newWidth -= [_tableView.tableColumns objectAtIndex:q].width;
			newWidth -= _tableView.interViewSpacing.width;
			}

		[_resizingColumn setWidth:newWidth];

		[_tableView tile];
		newRect.origin = [_tableView convertPoint:newPoint fromView:self];
		newRect.size = NSMakeSize(10,10);
		[_tableView scrollRectToVisible:newRect];
		_resizeLocation = newPoint;
		return YES;
		}
	return NO;
	}

- (BOOL) mouseUp:(AZEvent *)e
	{
	//[[self window] invalidateCursorRectsForView:self];

	[_tableView noteColumnDidResizeWithOldWidth:_oldColumnWidth];
	_resizedColumn 		= -1;
	_activelyResizing 	= NO;
	return YES;
	}

// MARK: Private methods

/*****************************************************************************\
|* Resize the rect before a given column
\*****************************************************************************/
- (NSRect) _resizeRectBeforeColumn:(NSInteger)column
	{
    NSRect rect = [self headerRectOfColumn:column];
    rect.origin.x -= 2;
    rect.size.width = 6;
    return rect;
	}

@end
#endif
