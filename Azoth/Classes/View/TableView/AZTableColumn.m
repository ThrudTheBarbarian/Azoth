//
//  AZTableColumn.m
//  Azoth
//
//  Created by Simon Gornall on 12/25/24.
//

#import <SDL3/SDL.h>

#import "AZTableColumn.h"
#import "AZTableHeaderView.h"
#import "AZTableView.h"
#import "AZTextField.h"

/*****************************************************************************\
|* "private" methods / properties
\*****************************************************************************/
@interface AZTableColumn()
@end

@implementation AZTableColumn

/*****************************************************************************\
|* Initialise: NSOutlineView needs to programmatically instantiated as IB/WOF4
|* doesn't have an editor for it.. a
\*****************************************************************************/
- (instancetype) initWithIdentifier:(NSObject *)identifier
	{
	if (self = [super init])
		{
		_identifier = identifier;
		_width		= 100.f;
		_minWidth	= 10.f;
		_maxWidth	= FLT_MAX;
		_resizable	= YES;
		_editable	= YES;

		NSRect standardFrame = NSMakeRect(0, 0, 100, 20);
        _headerView = [[AZTableHeaderView alloc] initWithFrame:standardFrame];
        _dataView 	= [[AZTextField alloc] initWithFrame:standardFrame];
		}
    return self;
	}


/*****************************************************************************\
|* Constrain the width when setting
\*****************************************************************************/
-(void)setWidth:(float)width
	{
    if (width > _maxWidth)
        width = _maxWidth;
    else if (width < _minWidth)
        width = _minWidth;
	_width = width;
	}

/*****************************************************************************\
|* When asked for a view for a given row, we in turn ask the delegate to
|* provide the view. The client, in its own turn, ought to ask the tableview
|* for a view with a given identifer, and (if one is available in the pool) an
|* already-extant view that isn't being used will be returned. This can then
|* be configured as needs be.
|*
|* If there isn't one available in the pool, the delegate should make a view
|* of its own, and it will be placed into the pool for next time around.
\*****************************************************************************/
- (nullable AZView *) dataViewForRow:(NSInteger)row
	{
	AZView *view = nil;

	id<AZTableViewDelegate> delegate = _tableView.delegate;
	SEL getView = SELECTOR(@"tableView:viewForTableColumn:row:");
	if ([delegate respondsToSelector:getView])
		view = [delegate tableView:_tableView viewForTableColumn:self row:row];
	else
		SDL_Log("TableView delegate does not supply views!");

	return view;
	}

@end
