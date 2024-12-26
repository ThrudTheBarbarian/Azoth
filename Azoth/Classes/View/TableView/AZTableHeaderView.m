//
//  AZTableHeaderView.m
//  Azoth
//
//  Created by Simon Gornall on 12/25/24.
//

#import <SDL3/SDL.h>

#import "AZTableColumn.h"
#import "AZTableHeaderView.h"
#import "AZTableView.h"
#import "AZWindow.h"

@interface AZTableView(NSTableView_private)
-(void)noteColumnDidResizeWithOldWidth:(float)oldWidth;
@end


@implementation AZTableHeaderView

/*****************************************************************************\
|* The size of the rectangle for the header view of a given column
\*****************************************************************************/
- (NSRect) headerRectOfColumn:(NSInteger)column
	{
    NSArray<AZTableColumn *> * cols = _tableView.tableColumns;
    NSRect headerRect 				= self.bounds;
    NSSize sz 					= _tableView.interViewSpacing;

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
    NSSize spacing 					= _tableView.interViewSpacing;

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
 #if 0
/*****************************************************************************\
|* We got a mouse click in the header view
\*****************************************************************************/
- (BOOL) mouseDown:(struct SDL_MouseButtonEvent *)e
	{
 	NSArray<AZTableColumn *> *cols 	= _tableView.tableColumns;
	NSPoint location 				= (NSPoint){e->x, e->y};
	location						= [self convertPoint:location fromView:nil];

    NSInteger col 					= [self columnAtPoint:location];
	id<NSTableViewDelegate>delegate	= _tableView.delegate;

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
            if (NSPointInRect(location, [self _resizeRectBeforeColumn:i]))
				{
                AZTableColumn *resizingColumn 	= [cols objectAtIndex:i-1];
                float resizedColumnWidth 		= [resizingColumn width];

                if (![resizingColumn resizable])
                    return NO;

                _resizedColumn = i - 1;
				location = [self convertPoint:(NSPoint){e->x,e->y} fromView:nil];
                do
					{
					// greatly simplified code...
                    NSPoint newPoint;
                    NSRect newRect;
                    int q;
                    float newWidth=newPoint.x;

                    theEvent=[[self window] nextEventMatchingMask:NSLeftMouseUpMask|NSLeftMouseDraggedMask];
                    newPoint=[self convertPoint:[theEvent locationInWindow] fromView:nil];

                    newWidth=newPoint.x;
                    for (q = 0; q < _resizedColumn; ++q) {
                        newWidth -= [[[_tableView tableColumns] objectAtIndex:q] width];
                        newWidth -= [_tableView intercellSpacing].width;
                    }

                    [resizingColumn setWidth:newWidth];

                    [_tableView tile];
                    newRect.origin=[_tableView convertPoint:newPoint fromView:self];
                    newRect.size=NSMakeSize(10,10);
                    [_tableView scrollRectToVisible:newRect];
                    
                    location=newPoint;
                } while ([theEvent type] != NSLeftMouseUp);

                [[self window] invalidateCursorRectsForView:self];

                [_tableView noteColumnDidResizeWithOldWidth:resizedColumnWidth];
         
                _resizedColumn = -1;
                return;
            }
        }
    }
	
    if ([_tableView allowsColumnSelection]) {
        if ([theEvent modifierFlags] & NSAlternateKeyMask) {		// extend/change selection
            if ([_tableView isColumnSelected:clickedColumn])		// deselect previously selected?
                [_tableView deselectColumn:clickedColumn];
            else if ([_tableView allowsMultipleSelection] == YES) {
                [_tableView selectColumn:clickedColumn byExtendingSelection:YES];	// add to selection
            }
        }
        else if ([theEvent modifierFlags] & NSShiftKeyMask) {
            int startColumn = [_tableView selectedColumn];
            int endColumn = clickedColumn;

            if (startColumn == -1)
                startColumn = 0;
            if (startColumn > endColumn) {
                endColumn = startColumn;
                startColumn = clickedColumn;
            }

            [_tableView deselectAll:nil];
            while (startColumn <= endColumn)
                [_tableView selectColumn:startColumn++ byExtendingSelection:YES];
        }
        else
            [_tableView selectColumn:clickedColumn byExtendingSelection:NO];
    }
	
	[[[_tableView tableColumns] objectAtIndex:clickedColumn] _sort];
}
#endif

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
