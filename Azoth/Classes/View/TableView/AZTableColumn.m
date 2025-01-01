//
//  AZTableColumn.m
//  Azoth
//
//  Created by Simon Gornall on 12/25/24.
//

#import <SDL3/SDL.h>

#import "AZApp.h"
#import "AZFont.h"
#import "AZOutlineView.h"
#import "AZTableColumn.h"
#import "AZTableHeaderView.h"
#import "AZTableView.h"
#import "AZTextField.h"
#import "AZView.h"

/*****************************************************************************\
|* "private" methods / properties
\*****************************************************************************/
@interface AZTableColumn()

// Cache of all the views (by row-number) in our column
@property(strong, nonatomic)
NSMutableDictionary<NSNumber *,AZView *> *							cache;
@end

@implementation AZTableColumn

/*****************************************************************************\
|* Initialise: NSOutlineView needs to programmatically instantiated as IB/WOF4
|* doesn't have an editor for it.. a
\*****************************************************************************/
- (instancetype) initWithIdentifier:(NSString *)identifier
	{
	if (self = [super init])
		{
		_identifier 	= identifier;
		_width			= 100.f;
		_minWidth		= 10.f;
		_maxWidth		= FLT_MAX;
		_resizable		= YES;
		_editable		= YES;
		_cache			= [NSMutableDictionary new];
		_title 			= @"";
		}
    return self;
	}


/*****************************************************************************\
|* Constrain the width when setting
\*****************************************************************************/
-(void) setWidth:(float)width
	{
    if (width > _maxWidth)
        width = _maxWidth;
    else if (width < _minWidth)
        width = _minWidth;
	_width = width;
	}

// MARK: Headers

/*****************************************************************************\
|* If a column has a title set on it, then make sure the parent table enables
|* headers
\*****************************************************************************/
- (void) setTitle:(NSString *)title
	{
	_title 					= title;
	_tableView.usesHeader 	= YES;
	}

/*****************************************************************************\
|* The width of the header, using the current font
\*****************************************************************************/
- (NSInteger) headerWidth
	{
	AZFont *font = AZApp.sharedInstance.controlFont;
	return [font textWidthFor:_title];
	}

// MARK: Pool management

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
	/*************************************************************************\
	|* First check to see if its in the cache
	\*************************************************************************/
	AZView *view = [_cache objectForKey:@(row)];

	/*************************************************************************\
	|* If we can't find it in the cache, ask the delegate to provide one
	\*************************************************************************/
	if (view == nil)
		{
		SEL getView = nil;
		id dlg 		= _tableView.delegate;
		if ([dlg conformsToProtocol:@protocol(AZOutlineViewDelegate)])
			getView = SELECTOR(@"outlineView:viewForTableColumn:row:");
		else
			getView = SELECTOR(@"tableView:viewForTableColumn:row:");

		id<AZTableViewDelegate> delegate = _tableView.delegate;
		if ([delegate respondsToSelector:getView])
			{
			view = [delegate tableView:_tableView
					viewForTableColumn:self
								   row:row];
			_cache[@(row)] = view;
			}
		else
			SDL_Log("Delegate does not supply views via %s!",
					NSStringFromSelector(getView).UTF8String);
		}

	return view;
	}

/*****************************************************************************\
|* Return any cached rows to the pool
\*****************************************************************************/
- (void) returnViewsInSet:(NSIndexSet *)set
	{
	NSMutableArray<AZView *> *views = [NSMutableArray new];

	[set enumerateIndexesUsingBlock:
		^(NSUInteger row, BOOL * _Nonnull stop)
			{
			AZView *view = _cache[@(row)];
			if (view)
				{
				[views addObject:view];
				[view removeFromSuperview];
				[_cache removeObjectForKey:@(row)];
				}
			}];

	[_tableView addToPool:views];
	}


@end
