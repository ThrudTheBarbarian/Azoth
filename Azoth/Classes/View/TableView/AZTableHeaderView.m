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



@end
