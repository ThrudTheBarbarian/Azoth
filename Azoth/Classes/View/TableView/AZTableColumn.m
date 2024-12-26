//
//  AZTableColumn.m
//  Azoth
//
//  Created by Simon Gornall on 12/25/24.
//

#import "AZTableColumn.h"
#import "AZTableHeaderView.h"
#import "AZTextField.h"

/*****************************************************************************\
|* "private" methods / properties
\*****************************************************************************/
@interface AZTableColumn()

// Prepare the view at a given row
- (void) _prepareView:(AZView *)view inRow:(NSInteger)row;

// Sort the column
- (void) _sort;
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

		NSRect standardFrame = NSMakeRect(0, 0, 100, 20);
        _headerView = [[AZTableHeaderView alloc] initWithFrame:standardFrame];
        _dataView 	= [[AZTextField alloc] initWithFrame:standardFrame];
		}
    return self;
	}

@end
