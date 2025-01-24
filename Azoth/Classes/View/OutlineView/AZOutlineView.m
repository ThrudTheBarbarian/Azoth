//
//  AZOutlineView.m
//  Azoth
//
//  Created by Simon Gornall on 12/31/24.
//

#import <SDL3/SDL.h>

#import "AZButton.h"
#import "AZColour.h"
#import "AZEvent.h"
#import "AZNotifications.h"
#import "AZPainter.h"
#import "AZObject.h"
#import "AZOutlineItemView.h"
#import "AZOutlineView.h"
#import "AZTableColumn.h"
#import "AZTableView+Private.h"
#import "AZTypes.h"

#define ROWHEIGHT		(25.f)

#define DATASOURCE(src) id<AZOutlineViewDataSource> src = 					\
						(id<AZOutlineViewDataSource>)self.dataSource

#define DELEGATE(dlg) 	id<AZOutlineViewDelegate> dlg = 					\
						(id<AZOutlineViewDelegate>)self.delegate

/*****************************************************************************\
|* "Private" Properties
\*****************************************************************************/
@interface AZOutlineView()
// Various maps from one thing to another. The only one that holds the actual
// item is 'rowToItem', since the others all reference the pointer-to-the-item
// as a string value. NSMutableDictionary doesn't like having an NSObject* key
// because it needs an id<NSCopying>. Strings work...

@property(strong, nonatomic)
NSMutableDictionary<NSNumber*, NSObject*> *					rowToItem;

@property(strong, nonatomic)
NSMutableDictionary<NSString*, NSNumber*> *					itemToRow;

@property(strong, nonatomic)
NSMutableDictionary<NSString*, NSObject*> *					itemToParent;

@property(strong, nonatomic)
NSMutableDictionary<NSString*, NSNumber*> *					itemToLevel;

@property(strong, nonatomic)
NSMutableDictionary<NSString*, NSNumber*> *					itemToState;

@property(strong, nonatomic)
NSMutableDictionary<NSString*, NSNumber*> *					itemToNumChildren;

// The number of rows we have cached
@property(assign, nonatomic) NSInteger						numberOfCachedRows;

// The item last clicked
@property(strong, nonatomic) NSObject *						clickedItem;

// The width of the column
@property(assign, nonatomic) float							columnWidth;

@end



@implementation AZOutlineView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super initWithFrame:frame])
		{
		[self _commonOutlineInit];
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
		[self _commonOutlineInit];
		}
	return self;
	}

/*****************************************************************************\
|* Common initialisation between -withFrame and -withDictionary
\*****************************************************************************/
- (void) _commonOutlineInit
	{
	_rowToItem				= [NSMutableDictionary new];
	_itemToRow				= [NSMutableDictionary new];
	_itemToParent			= [NSMutableDictionary new];
	_itemToLevel			= [NSMutableDictionary new];
	_itemToState			= [NSMutableDictionary new];
	_itemToNumChildren		= [NSMutableDictionary new];

	_indentPerLevel			= 10;
	_autoresizeOutline		= YES;

	self.backgroundColour 	= AZColour.controlBackground;
	self.isOpaque			= YES;

	[self _invalidateRowCache];
	}

/*****************************************************************************\
|* Clean up on dealloc
\*****************************************************************************/
- (void) dealloc
	{
	[NSNotificationCenter.defaultCenter removeObserver:self];
	}


/*****************************************************************************\
|* Return the item at a given row
\*****************************************************************************/
- (nullable NSObject *) itemAtRow:(NSInteger)row
	{
	return _rowToItem[@(row)];
	}

/*****************************************************************************\
|* Get the row for an item
\*****************************************************************************/
- (NSInteger) rowForItem:(NSObject *)item
	{
	return _itemToRow[TO_KEY(item)].integerValue;
	}

/*****************************************************************************\
|* Get the parent for a given item
\*****************************************************************************/
- (NSObject *) parentForItem:(NSObject *)item
	{
	return _itemToParent[TO_KEY(item)];
	}

/*****************************************************************************\
|* Is an item expandable
\*****************************************************************************/
- (BOOL) isExpandable:(NSObject *)item
	{
	DATASOURCE(src);
    return [src outlineView:self isItemExpandable:item];
	}

/*****************************************************************************\
|* Is the item expanded
\*****************************************************************************/
- (BOOL) isItemExpanded:(NSObject *)item
	{
	return _itemToState[TO_KEY(item)].boolValue;
	}

/*****************************************************************************\
|* What indentation level is the item at
\*****************************************************************************/
- (NSInteger) levelForItem:(NSObject *)item
	{
	return _itemToLevel[TO_KEY(item)].integerValue;
	}

/*****************************************************************************\
|* What indentation level is a given row at
\*****************************************************************************/
- (NSInteger) levelForRow:(NSInteger)row;
	{
	return [self levelForItem:[self itemAtRow:row]];
	}

/*****************************************************************************\
|* Add/remove a table column
\*****************************************************************************/
-(void)addTableColumn:(AZTableColumn *)column
	{
	if (_outlineColumn == nil)
		_outlineColumn = column;
	[super addTableColumn:column];
	}

/*****************************************************************************\
|* The mouse button was clicked
\*****************************************************************************/
- (BOOL) rightMouseDown:(AZEvent *)e
	{
	SEL rightDown = SELECTOR(@"outlineView:rightClickAt:inView:row:item:");
	if ([self.delegate respondsToSelector:rightDown])
		{
		AZView *view	= self;
		NSPoint at 		= [self convertPoint:e.locationInWindow fromView:nil];

		// The point will be invalid if the click happens outside of the
		// bounds of the outlineview, but inside the bounds of its parent
		// clipview, so attempt to recover in this case.
		BOOL pointValid = NO;
		if ((at.x > 0) && (at.x < self.bounds.size.width))
			if ((at.y > 0) && (at.y < self.bounds.size.height))
				pointValid = YES;
		if (!pointValid)
			{
			[self rebuildTransforms];
			at = [self.superview convertPoint:e.locationInWindow fromView:nil];
			view = self.superview;
			}
			
		NSInteger row	= [self rowAtPoint:at];
		NSObject *item	= [self itemAtRow:row];
		[self.delegate outlineView:self
					  rightClickAt:at
							inView:view
							   row:row
							  item:item];
		}
	return YES;
	}

// MARK: View management

/*****************************************************************************\
|* Embed a view representing a row within an AZOutlineItemView so we can
|* have disclosure triangles etc.
\*****************************************************************************/
- (AZView *) embedInItemView:(AZView *)view
	{
	NSRect frame = NSMakeRect(0,0,_outlineColumn.width, view.frame.size.height);
	AZView *host = [AZOutlineItemView itemViewWithView:view andFrame:frame];
	return host;
	}


// MARK: Item collapse/expand/reload

/*****************************************************************************\
|* Expand an item, optionally expanding the children too
\*****************************************************************************/
- (void)expandItem:(id)item expandChildren:(BOOL)expandChildren
	{
	NSMutableArray *items = [self _selectedItems];

	if ([self _delayResizeButExpandItem:item expandChildren:expandChildren])
		{
		[self noteNumberOfRowsChanged];

		if (self.autoresizeOutline)
			{
			[self _tightenUpColumn:_outlineColumn forItem:item];
			if ([_outlineColumn width] < [_outlineColumn minWidth])
				[_outlineColumn setWidth:[_outlineColumn minWidth]];
			}

		NSIndexSet *selection = [self _selectionFromItems:items];
		[self selectRowIndexes:selection byExtendingSelection:NO];
		[self setNeedsDisplay:YES];
		}
	}

- (void)expandItem:(id)item
	{
    [self expandItem:item expandChildren:NO];
	}


/*****************************************************************************\
|* Get a list of items which are the current selection
\*****************************************************************************/
- (NSMutableArray *) _selectedItems
	{
	NSIndexSet * selectedRows = [self selectedRowIndexes];
	NSMutableArray *items = [NSMutableArray new];
	NSInteger index = selectedRows.firstIndex;
	while (index != NSNotFound)
		{
		[items addObject:[self itemAtRow:index]];
		index = [selectedRows indexGreaterThanIndex:index];
		}
	return items;
	}

/*****************************************************************************\
|* Create an indexset for items
\*****************************************************************************/
- (NSIndexSet *) _selectionFromItems:(NSArray *)items
	{
	NSMutableIndexSet *set = NSMutableIndexSet.new;
	for (NSObject *item in items)
		{
		NSInteger row = [self rowForItem:item];
		[set addIndex:row];
		}
	return set;
	}

/*****************************************************************************\
|* Collapse an item, optionally collapsing the children too
\*****************************************************************************/
- (void)collapseItem:(NSObject *)item collapseChildren:(BOOL)collapseChildren
	{
    BOOL collapseThisItem 			= YES;
	NSNotificationCenter *nc		= NSNotificationCenter.defaultCenter;

	NSMutableArray *items 			= [self _selectedItems];

	DELEGATE(dlg);
    if ([dlg respondsToSelector:@selector(outlineView:shouldCollapseItem:)])
        if ([dlg outlineView:self shouldCollapseItem:item] == NO)
            collapseThisItem = NO;

    if (collapseThisItem)
		{
 		NSDictionary *info = @{@"NSObject" : item};
        [nc postNotificationName:AZOutlineViewItemWillCollapseNotification
						  object:self
						userInfo:info];

		_itemToState[TO_KEY(item)] = @(NO);
        [self _invalidateRowCache];
        [self noteNumberOfRowsChanged];

        [nc postNotificationName:AZOutlineViewItemDidCollapseNotification
						  object:self
						userInfo:info];
		}

    if (collapseChildren)
		{
		DATASOURCE(src);
        NSInteger numKids = [self numberOfChildrenOfItem:item andReload:YES];

        for (NSInteger i = 0; i < numKids; ++i)
			{
            NSObject *child = [src outlineView:self child:i ofItem:item];
            [self collapseItem:child collapseChildren:YES];
			}
		}

    if (_autoresizeOutline)
		[self _tightenUpColumn:_outlineColumn];

	if (collapseThisItem)
		{
		NSIndexSet *selection = [self _selectionFromItems:items];
		[self selectRowIndexes:selection byExtendingSelection:NO];
		}
		
	[self setNeedsDisplay:YES];
	}

- (void)collapseItem:(NSObject *)item
	{
    [self collapseItem:item collapseChildren:NO];
	}


/*****************************************************************************\
|* Reload all the data
\*****************************************************************************/
- (void) reloadData
	{
	[self _resetMaps];
	[self _invalidateRowCache];
	[super reloadData];
	[self _configureItemViews];
	}

/*****************************************************************************\
|* Reload the data for an item, and optionally children of that item. This is
|* a fudge because it really just forces a reload via display
\*****************************************************************************/
- (void)reloadItem:(NSObject *)item reloadChildren:(BOOL)reloadChildren
	{
    [self _resetMaps];
    [self _invalidateRowCache];
    [self noteNumberOfRowsChanged];
    [self setNeedsDisplay:YES];
	}

-(void)reloadItem:(id)item
	{
    [self reloadItem:item reloadChildren:NO];
	}

/*****************************************************************************\
|* Figure out the number of rows
\*****************************************************************************/
-(NSInteger)numberOfRows
	{
	if (_numberOfCachedRows == 0)
		[self _loadRootItem];

	return _numberOfCachedRows;
	}


// MARK: datasource/delegate

/*****************************************************************************\
|* Properly replace the data-source
\*****************************************************************************/
- (void) setDataSource:(id<AZOutlineViewDataSource>)dataSource
	{
    SEL requiredSelectors[] =
		{
        @selector(outlineView:child:ofItem:),
        @selector(outlineView:isItemExpandable:),
        @selector(outlineView:numberOfChildrenOfItem:),
        NULL
        };

	BOOL ok = YES;
	if (dataSource)
		for (int i = 0; requiredSelectors[i] != NULL; ++i)
			if (![dataSource respondsToSelector:requiredSelectors[i]])
				{
				ok = NO;
				SDL_Log("AZOutlineViewDataSource does not respond to %s",
						NSStringFromSelector(requiredSelectors[i]).UTF8String);
				}

	if (ok)
		super.dataSource = dataSource;
	}

/*****************************************************************************\
|* Properly replace the delegate, invalidating any old notifications etc.
\*****************************************************************************/
- (void) setDelegate:(id<AZOutlineViewDelegate>)delegate
	{
	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;

    AZNotifyMap notes[] =
		{
			{ AZOutlineViewItemWillExpandNotification,
			  SELECTOR(@"outlineViewItemWillExpand:") },
			{ AZOutlineViewItemDidExpandNotification,
			  SELECTOR(@"outlineViewItemDidExpand:") },
			{ AZOutlineViewItemWillCollapseNotification,
			  SELECTOR(@"outlineViewItemWillCollapse:") },
			{ AZOutlineViewItemDidCollapseNotification,
			  SELECTOR(@"outlineViewItemDidCollapse:") },
			{ AZOutlineViewColumnDidResizeNotification,
			  SELECTOR(@"outlineViewColumnDidResize:") },
			{ AZOutlineViewSelectionIsChangingNotification,
			  SELECTOR(@"outlineViewSelectionIsChanging:") },
			{ AZOutlineViewSelectionDidChangeNotification,
			  SELECTOR(@"outlineViewSelectionDidChange:") },
			{ nil, NULL }
		};

	DELEGATE(dlg);
    if (dlg != nil)
        for (int i = 0; notes[i].name != nil; ++i)
            [nc removeObserver:dlg name:notes[i].name object:self];

    super.delegate = delegate;

    for (int i = 0; notes[i].name != nil; ++i)
        if ([dlg respondsToSelector:notes[i].selector])
            [nc addObserver:dlg
				   selector:notes[i].selector
					   name:notes[i].name
					 object:self];
	}



/*****************************************************************************\
|* Find the frame of an item's view
\*****************************************************************************/
- (NSRect) frameOfViewAtColumn:(NSInteger)col row:(NSInteger)row
	{
	AZTableColumn *column = [self.tableColumns objectAtIndex:col];
	if (column ==_outlineColumn)
		return [self _adjustedFrameOfViewAtColumn:col row:row];

	return [super frameOfViewAtColumn:col row:row];
	}

/*****************************************************************************\
|* Override table-view because our method is different...
|* Check if we should select a row
\*****************************************************************************/
- (BOOL) delegateShouldSelectRow:(NSInteger)row
	{
	NSObject *item = _rowToItem[@(row)];

	SEL shouldSelect = SELECTOR(@"outlineView:shouldSelectItem:");
    if ([self.delegate respondsToSelector:shouldSelect])
        return [self.delegate outlineView:self shouldSelectItem:item];

	// Default to YES
    return YES;
	}


// MARK: Private methods


/*****************************************************************************\
|* Get the frame of the disclosure triangle at a given row
\*****************************************************************************/
- (NSRect) _frameOfDisclosureViewAtRow:(NSInteger)row
	{
	NSInteger col 	= [self.tableColumns indexOfObjectIdenticalTo:_outlineColumn];
	NSRect result 	= [super frameOfViewAtColumn:col row:row];
	NSInteger level	= [self levelForRow:row];
    float indent 	= level * _indentPerLevel;

	result.size.width = indent;

    if (_indentationFollowsView)
		result.origin.x += result.size.width;

	result.size.width = _indentPerLevel;
	return result;
	}

/*****************************************************************************\
|* Populate the map-tables with the data for an item
\*****************************************************************************/
- (void) loadItem:(NSObject *)item
		   remove:(NSMutableSet *)toRemove
		recursion:(NSInteger)level
	{
    NSInteger numChildren = [self numberOfChildrenOfItem:item andReload:YES];

	DATASOURCE(src);
    for (NSInteger i = 0; i < numChildren; ++i)
		{
        NSObject *child = [src outlineView:self child:i ofItem:item];
		[toRemove removeObject:TO_KEY(child)];

		_rowToItem[@(_numberOfCachedRows)] = child;
		NSString *key = TO_KEY(child);

		_itemToRow[key] 	= @(_numberOfCachedRows);
		_itemToParent[key] 	= item;
		_itemToLevel[key] 	= @(level);

		NSInteger kids = [self numberOfChildrenOfItem:child andReload:YES];
		_itemToNumChildren[key] = @(kids);

        _numberOfCachedRows ++;

		if ([self isItemExpanded:child])
			[self loadItem:child remove:toRemove recursion:level+1];
		}
	}

/*****************************************************************************\
|* Start populating at root
\*****************************************************************************/
- (void) _loadRootItem
	{
	NSMutableSet *toRemove = [NSMutableSet new];

	for (NSString *key in _itemToState)
		[toRemove addObject:key];

	[self loadItem:nil remove:toRemove recursion:0];

	for (NSString *key in toRemove)
		[_itemToState removeObjectForKey:key];
	}

/*****************************************************************************\
|* Make the column size reflect what's there
\*****************************************************************************/
-(void) _tightenUpColumn:(AZTableColumn *)column forItem:(id)item
	{
	NSInteger rootLevel = [self levelForItem:item];
	NSInteger i 		= [self rowForItem:item]+1;
	NSInteger rowCount	= [self numberOfRows];

	float minWidth			= 0;
	for(; i<rowCount; i++)
		{
		AZOutlineItemView *view	= (AZOutlineItemView*)[column dataViewForRow:i];
		NSObject *item	 		= [self itemAtRow:i];
    	NSInteger level			= [self levelForItem:item];

		if (level <= rootLevel)
			break;

		float width			= view.preferredWidth + level * _indentPerLevel;
		if (width > minWidth)
			minWidth = width;
		}

	[column setMinWidth:minWidth];
	}

-(void)_tightenUpColumn:(AZTableColumn *)column
	{
	[self _tightenUpColumn:column forItem:[self itemAtRow:0]];
	}

/*****************************************************************************\
|* Get the number of children for an item either from the cache or via the
|* delegate
\*****************************************************************************/
- (NSInteger) numberOfChildrenOfItem:(NSObject *)item andReload:(BOOL) reload
	{
	NSInteger result;
   
	if (!reload)
		result = _itemToNumChildren[TO_KEY(item)].integerValue;
	else
		{
		DATASOURCE(src);
		result = [src outlineView:self numberOfChildrenOfItem:item];
		_itemToNumChildren[TO_KEY(item)] = @(result);
		}
	return result;
	}

/*****************************************************************************\
|* Invalidate the row cache
\*****************************************************************************/
- (void) _invalidateRowCache
	{
    _numberOfCachedRows = 0;
	}

/*****************************************************************************\
|* Handle resize
\*****************************************************************************/
- (BOOL) _delayResizeButExpandItem:(NSObject*)item expandChildren:(BOOL)expand
	{
	BOOL noteNumberOfRowsChanged	= NO;
    BOOL expandThisItem 			= YES;
	NSNotificationCenter *nc		= NSNotificationCenter.defaultCenter;

    if (![self isExpandable:item])
		return YES;

	DELEGATE(dlg);
    if ([dlg respondsToSelector:@selector(outlineView:shouldExpandItem:)])
        if ([dlg outlineView:self shouldExpandItem:item] == NO)
            expandThisItem = NO;

    if (expandThisItem)
		{
		NSDictionary *info = @{@"NSObject" : item};
        [nc postNotificationName:AZOutlineViewItemWillExpandNotification
						  object:self
						userInfo:info];

        noteNumberOfRowsChanged			= YES;
		_itemToState[TO_KEY(item)] 	= @(YES);
        [self _invalidateRowCache];

        [nc postNotificationName:AZOutlineViewItemDidExpandNotification
						  object:self
                        userInfo:info];
		}

    if (expand)
		{
		DATASOURCE(src);
		NSInteger numKids = [self numberOfChildrenOfItem:item andReload:YES];

        for (NSInteger i = 0; i < numKids; ++i)
			{
            NSObject *child = [src outlineView:self child:i ofItem:item];

            if ([self _delayResizeButExpandItem:child expandChildren:YES])
				noteNumberOfRowsChanged=YES;
			}
		}

    return YES;
	}

/*****************************************************************************\
|* Re-initialise the maps, apart from the expanded-state one (which we'll
|* keep around and modify on reloadData because items in the table are
|* stable values, and it makes sense to preserve what the user has built)
\*****************************************************************************/
- (void) _resetMaps
	{
	[_rowToItem removeAllObjects];
	[_itemToRow removeAllObjects];
	[_itemToParent removeAllObjects];
	[_itemToLevel removeAllObjects];
	[_itemToNumChildren removeAllObjects];
	}

/*****************************************************************************\
|* Adjust the frame of an item's view
\*****************************************************************************/
- (NSRect) _adjustedFrameOfViewAtColumn:(NSInteger)column row:(NSInteger)row
	{
    NSRect viewRect 			= [super frameOfViewAtColumn:column row:row];
    AZTableColumn *tableColumn 	= [self.tableColumns objectAtIndex:column];
	float W 					= self.spacing.width;

	DELEGATE(dlg);
    if (tableColumn == _outlineColumn)
		{
        AZView *dataView   = [tableColumn dataViewForRow:row];
        float indent 	   = [self levelForRow:row] * _indentPerLevel;
 		float adjIndent	   = indent + self.rowHeight;
        viewRect.origin.x += adjIndent + W;

        // Give the delegate an opportunity to provide the view width.
        SEL width = SELECTOR(@"outlineView:widthOfView:forTableColumn:byItem:");
        float viewWidth;
        if ([dlg respondsToSelector:width])
			viewWidth = [dlg outlineView:self
							 widthOfView:dataView
						  forTableColumn:tableColumn
								  byItem:[self itemAtRow:row]] + W;

        else
			viewWidth = viewRect.size.width - adjIndent;


		// Revisit this if we ever allow editing...
		//
        // since we shrink the cell frame to fit the title, when editing occurs,
        //  we need to pad the frame slightly so that the entire title will be
        // visible in the editing cell (space permitting in the column)
        //if (column == self.editedColumn && row == self.editedRow)
        //     viewWidth += self.editingViewPadding;

        viewRect.size.width = MIN(viewWidth, NSWidth(viewRect) - adjIndent);
		}

    return viewRect;
	}

/*****************************************************************************\
|* Find the frame of an item's view
\*****************************************************************************/
- (void) _drawHighlightedSelectionForColumn:(NSInteger)column
										row:(NSInteger)row
									 inRect:(NSRect)rect
								withPainter:(AZPainter *)painter
	{
	if ([self.tableColumns objectAtIndex:column] == _outlineColumn)
		{
        NSRect newRect = NSInsetRect(rect,1,0);

		int dashes[] = {4,3};
		[painter rectangleInRect:newRect
							 num:2
						  dashes:dashes
						inColour:AZColour.blue
						withClip:self.bounds];
		}
	}

/*****************************************************************************\
|* Update all the row indents for the current table column
\*****************************************************************************/
- (void) _configureItemViews
	{
	AZOutlineItemView *iv;

	for (NSInteger i=0; i<_numberOfCachedRows; i++)
		{
		iv = (AZOutlineItemView *)[_outlineColumn dataViewForRow:i];
		NSObject *item  	= _rowToItem[@(i)];
		NSString *key 		= TO_KEY(item);
		NSInteger level 	= _itemToLevel[key].integerValue;
		BOOL hasChildren	= _itemToNumChildren[key].integerValue > 0;
		BOOL isOpen			= _itemToState[key].boolValue;

		[iv indentBy:level * _indentPerLevel];
		[iv setIsOpen:isOpen];
		[iv setHasChildren:hasChildren];
		[iv setItem:item];
		[iv setTarget:self];
		[iv setAction:@selector(_itemDisclosureClicked:)];
		if (i == self.selectedRow)
			[iv setSelected:YES];
		}
	}

/*****************************************************************************\
|* One of our items has been clicked on
\*****************************************************************************/
- (void) _itemDisclosureClicked:(AZOutlineItemView *)view
	{
	AZOutlineItemViewReason reason = view.reason;
	NSString *key = TO_KEY(view.item);

	if (reason == AZOutlineViewItemDisclosed)
		{
		if (_itemToState[key].boolValue)
			{
			[self collapseItem:view.item];
			[self reloadData];
			}
		else if (_itemToNumChildren[key].integerValue > 0)
			{
			[self expandItem:view.item];
			[self reloadData];
			}
		}
	else if (reason == AZOutlineViewItemSelected)
		{
		NSInteger row = _itemToRow[key].integerValue;
		[self selectRow:row byExtendingSelection:NO];
		[self reloadData];
		}
	}

@end
