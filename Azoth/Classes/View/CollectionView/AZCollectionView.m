//
//  AZCollectionView.m
//  Azoth
//
//  Created by Simon Gornall on 1/7/25.
//

#include <SDL3/SDL.h>

#import "AZClipView.h"
#import "AZCollectionView.h"
#import "AZCollectionViewDelegate.h"
#import "AZColour.h"
#import "AZCVGroup.h"
#import "AZCVLayoutItem.h"
#import "AZCVLayoutManager.h"
#import "AZDraggingItem.h"
#import "AZDraggingSession.h"
#import "AZEvent.h"
#import "AZGeometry.h"
#import "AZImage.h"
#import "AZMenu.h"
#import "AZNotifications.h"
#import "AZPainter.h"
#import "AZPasteboard.h"
#import "AZScrollView.h"
#import "AZViewController.h"
#import "AZWindow.h"

/*****************************************************************************\
|* "Private" Properties
\*****************************************************************************/
@interface AZCollectionView()

// What the user has been typing
@property (nonatomic, copy) NSString *					accumulatedKeyStrokes;

// Which view controllers are reusable
@property (strong, nonatomic)
NSMutableArray<AZViewController *> *					reusableVCs;

// Which group view controllers are visible
@property (strong, nonatomic)
NSMutableDictionary<NSNumber*,AZViewController*> *		visibleGroupVCs;

// Mouse dragging support
@property (assign, nonatomic) NSPoint					atDown;
@property (assign, nonatomic) NSPoint					atDragged;
@property (assign, nonatomic) NSRect					previousFrameBounds;
@property (assign, nonatomic) BOOL						isDragging;
@property (assign, nonatomic) BOOL						firstDrag;
@property (assign, nonatomic) BOOL						selectionChangedDisabled;

// Selection management
@property (assign, nonatomic) NSUInteger				lastSelectionIndex;
@property (nonatomic, copy) NSIndexSet *				originalSelection;
@property (assign, nonatomic) NSInteger				 	dragHoverIndex;

// The current offset of the tableview
@property (assign, nonatomic) NSPoint		 			offset;

@end

@implementation AZCollectionView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super initWithFrame:frame])
		{
		[self _commonCollectionViewInit];
		}
	return self;
	}

/*****************************************************************************\
|* And from a NIB
\*****************************************************************************/
- (instancetype) initWithDictionary:(NSDictionary *)info
	{
	if (self = [super initWithDictionary:info])
		{
		[self _commonCollectionViewInit];
		}
	return self;
	}

/*****************************************************************************\
|* Initialisation common to both -withFrame and -withDictionary
\*****************************************************************************/
- (void) _commonCollectionViewInit
	{
    _reusableVCs     			= NSMutableArray.new;
	_visibleVCs 			    = NSMutableDictionary.new;
    _contentArray               = NSArray.new;
    _selection      	      	= NSMutableIndexSet.new;
    _dragHoverIndex             = NSNotFound;
    _accumulatedKeyStrokes      = NSString.new;
    _numberOfPreRenderedRows    = 3;
    _layoutManager              = [AZCVLayoutManager managerWithCV:self];
    _visibleGroupVCs 			= NSMutableDictionary.new;
	_atDown = _atDragged		= NSZeroPoint;

    [self addObserver:self
		   forKeyPath:@"backgroundColor"
			  options:0
			  context:nil];

    AZClipView *clipView = self.enclosingScrollView.contentView;
    [clipView setPostsBoundsNotifications:YES];

    NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
    [nc addObserver:self
		   selector:@selector(scrollViewDidScroll:)
			   name:AZViewBoundsDidChangeNotification
			 object:clipView];

    [nc addObserver:self
		   selector:@selector(viewDidResize)
			   name:AZViewFrameDidChangeNotification
			 object:self];
	}

/*****************************************************************************\
|* Clean up
\*****************************************************************************/
- (void) dealloc
	{
	[self removeObserver:self
			  forKeyPath:@"backgroundColor"];

    NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
	[nc removeObserver:self];

	for (AZCVGroup *group in _groups)
		[group removeObserver:self forKeyPath:@"isCollapsed"];
	}

/*****************************************************************************\
|* Set the "dataSource". There is no real datasource, it's just helpful to
|* have the key available in case its set in IB. Any set on the datasource
|* will actually set the delegate
\*****************************************************************************/
- (void) setDataSource:(id<AZCollectionViewDelegate>)datasource
	{
	_delegate = datasource;
	}


/*****************************************************************************\
|* KVO handling
\*****************************************************************************/
- (void) observeValueForKeyPath:(NSString *)keyPath
					   ofObject:(id)object
						 change:(NSDictionary *)change
						context:(void *)context
	{
	if ([keyPath isEqualToString:@"backgroundColor"])
		[self setNeedsDisplay:YES];

	else if ([keyPath isEqualToString:@"isCollapsed"])
		{
		[self softReloadDataWithCompletionBlock:
			^{
			[self performSelector:@selector(scrollViewDidScroll:)];
			}];
		}

	else
		[super observeValueForKeyPath:keyPath
							 ofObject:object
							   change:change
							  context:context];
	}

// Large background management

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
|* Emulate 'scrollToPoint' in the clipview
\*****************************************************************************/
- (void) scrollToPoint:(NSPoint)point
	{
	_offset = point;
	}


// MARK: Drawing

/*****************************************************************************\
|* We are opaque
\*****************************************************************************/
- (BOOL)isOpaque
	{
	return YES;
	}

/*****************************************************************************\
|* Should we make an attempt to draw selections or leave them to the delegate
\*****************************************************************************/
- (BOOL)shouldDrawSelections
	{
	SEL drawSel = SELECTOR(@"collectionViewShouldDrawSelections:");
	if ([_delegate respondsToSelector:drawSel])
		return [_delegate collectionViewShouldDrawSelections:self];

	return YES;
	}

/*****************************************************************************\
|* Should we make an attempt to draw hover or leave them to the delegate
\*****************************************************************************/
- (BOOL)shouldDrawHover
	{
	SEL hoverSel = SELECTOR(@"collectionViewShouldDrawHover:");
	if ([_delegate respondsToSelector:hoverSel])
		return [_delegate collectionViewShouldDrawHover:self];

    return YES;
	}

/*****************************************************************************\
|* Main drawing routine
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	AZColour *bg = self.backgroundColour
				 ? self.backgroundColour
				 : AZColour.white;

	[painter rectangleWithRect:dirtyRect filled:YES colour:bg];

	if ((_selection.count > 0) && self.shouldDrawSelections)
		{
		for (NSNumber *number in _visibleVCs)
			if ([_selection containsIndex:number.integerValue])
				{
				NSRect frame = _visibleVCs[number].view.frame;
				[self _drawItemSelectionInRect:frame withPainter:painter];
				}
		}
  
	if (_dragHoverIndex != NSNotFound && [self shouldDrawHover])
		{
		NSRect frame = _visibleVCs[@(_dragHoverIndex)].view.frame;
		[self _drawItemSelectionInRect:frame withPainter:painter];
		}
	}

/*****************************************************************************\
|* Draw selection in a rect
\*****************************************************************************/
- (void) _drawItemSelectionInRect:(NSRect)aRect withPainter:(AZPainter*)painter
	{
	aRect.origin.x -= _offset.x;
	aRect.origin.y -= _offset.y;

	[painter rectangleWithRect:aRect
						radius:10
						filled:YES
						colour:AZColour.grey75];
	}



// MARK: Delegate call wrappers

/*****************************************************************************\
|* Tell the delegate something has been selected, if it cares
\*****************************************************************************/
- (void) delegateUpdateSelectionForItemAtIndex:(NSUInteger)index
	{
	SEL selSel = SELECTOR(@"collectionView:updateVCAsSelected:forItem:");
	if ([_delegate respondsToSelector:selSel])
		[_delegate collectionView:self
			   updateVCAsSelected:[self viewControllerForItemAtIndex:index]
						  forItem:[_contentArray objectAtIndex:index]];
	}

/*****************************************************************************\
|* Tell the delegate something has been deselected, if it cares
\*****************************************************************************/
- (void) delegateUpdateDeselectionForItemAtIndex:(NSUInteger)index
	{
	SEL deselSel = SELECTOR(@"collectionView:updateVCAsDeselected:forItem:");
	if ([_delegate respondsToSelector:deselSel])
		[_delegate collectionView:self
			   updateVCAsDeselected:[self viewControllerForItemAtIndex:index]
						  forItem:[_contentArray objectAtIndex:index]];
	}

/*****************************************************************************\
|* Tell the delegate the selection changed, if it cares
\*****************************************************************************/
- (void) delegateCollectionViewSelectionDidChange
	{
	SEL chgSel = SELECTOR(@"collectionViewSelectionDidChange:");
	if ((!_selectionChangedDisabled) && [_delegate respondsToSelector:chgSel])
		{
		[[NSRunLoop currentRunLoop] cancelPerformSelector:chgSel
												   target:_delegate
												 argument:self];
		[(id)_delegate performSelector:chgSel
							withObject:self
							afterDelay:0.f];
		}
	}

/*****************************************************************************\
|* Tell the delegate an item was selected
\*****************************************************************************/
- (void) delegateDidSelectItemAtIndex:(NSUInteger)index
	{
	SEL selSel = SELECTOR(@"collectionView:didSelectItem:withVC:");
	if ([_delegate respondsToSelector:selSel])
		[_delegate collectionView:self
					didSelectItem:[_contentArray objectAtIndex:index]
						   withVC:[self viewControllerForItemAtIndex:index]];
	}

/*****************************************************************************\
|* Tell the delegate an item was deselected
\*****************************************************************************/
- (void) delegateDidDeselectItemAtIndex:(NSUInteger)index
	{
	SEL selSel = SELECTOR(@"collectionView:didDeselectItem:withVC:");
	if ([_delegate respondsToSelector:selSel])
		[_delegate collectionView:self
				  didDeselectItem:[_contentArray objectAtIndex:index]
						   withVC:[self viewControllerForItemAtIndex:index]];
	}

/*****************************************************************************\
|* Tell the delegate an item was deselected
\*****************************************************************************/
- (void)delegateViewControllerBecameInvisibleAtIndex:(NSUInteger)index
	{
	SEL selGone = SELECTOR(@"collectionView:VCNoLongerVisible:");
	if ([_delegate respondsToSelector:selGone])
		[_delegate collectionView:self
				VCNoLongerVisible:[self viewControllerForItemAtIndex:index]];
	}


/*****************************************************************************\
|* Required delegate method - tell the collection view what the cell size is
\*****************************************************************************/
- (NSSize)cellSize
	{
	return [_delegate cellSizeForCollectionView:self];
	}


/*****************************************************************************\
|* Required delegate method if groups are used - tell the collection view what
|* the group header height is
\*****************************************************************************/
- (NSUInteger)groupHeaderHeight
	{
	return [_delegate groupHeaderHeightForCollectionView:self];
	}


// MARK: Index management

/*****************************************************************************\
|* Return the indexes of any items within a given rect
\*****************************************************************************/
- (NSIndexSet *)indexesOfItemsInRect:(NSRect)r
	{
	NSArray *itemLayouts = [_layoutManager itemLayouts];
	return [itemLayouts indexesOfObjectsWithOptions:NSEnumerationConcurrent
										   passingTest:
				^BOOL(id itemLayout, NSUInteger idx, BOOL *stop)
					{
					return NSIntersectsRect([itemLayout itemRect], r);
					}];
	}


/*****************************************************************************\
|* Return the indexes of any content-rects within a given rect
\*****************************************************************************/
- (NSIndexSet *)indexesOfItemContentRectsInRect:(NSRect)r
	{
	NSArray *itemLayouts = [_layoutManager itemLayouts];
	return [itemLayouts indexesOfObjectsWithOptions:NSEnumerationConcurrent
										   passingTest:
				^BOOL(id itemLayout, NSUInteger idx, BOOL *stop)
					{
					return NSIntersectsRect([itemLayout itemContentRect], r);
					}];
	}

/*****************************************************************************\
|* Return an NSRange for the visible items
\*****************************************************************************/
- (NSRange)rangeOfVisibleItems
	{
	NSIndexSet *visible = [self indexesOfItemsInRect:[self visibleRect]];
	NSInteger first		= visible.firstIndex;
	return NSMakeRange(first, visible.lastIndex - first);
	}

/*****************************************************************************\
|* Return an NSRange for the visible items, including the pre-rendered overflow
\*****************************************************************************/
- (NSRange)rangeOfVisibleItemsWithOverflow
	{
	NSRange range 		 = self.rangeOfVisibleItems;
	NSInteger extraItems = _layoutManager.maximumNumberOfItemsPerRow
						 * _numberOfPreRenderedRows;
	NSInteger min 		 = range.location;
	NSInteger max 		 = range.location + range.length;

	min 				 = MAX(0, min - extraItems);
	max 				 = MIN(_contentArray.count, max+extraItems);
	return NSMakeRange(min, max-min);
	}


/*****************************************************************************\
|* Return what is selected atm
\*****************************************************************************/
- (NSIndexSet *)selectionIndexes
	{
	return _selection;
	}

// MARK: Querying ViewControllers

/*****************************************************************************\
|* The indexes of visible view controllers
\*****************************************************************************/
- (NSIndexSet *)indexesOfViewControllers
	{
	NSMutableIndexSet *set = NSMutableIndexSet.new;
	for (NSNumber *number in _visibleVCs.allKeys)
		[set addIndex:number.integerValue];
	return set;
	}

/*****************************************************************************\
|* ... as an array
\*****************************************************************************/
- (NSArray<AZViewController *> *) visibleVCArray
	{
	return _visibleVCs.allValues;
	}

/*****************************************************************************\
|* The indexes of invisible view controllers
\*****************************************************************************/
- (NSIndexSet *)indexesOfInvisibleViewControllers
	{
	NSRange visibleRange = [self rangeOfVisibleItemsWithOverflow];
	return [self.indexesOfViewControllers indexesPassingTest:
		^BOOL(NSUInteger idx, BOOL *stop)
			{
			return !NSLocationInRange(idx, visibleRange);
			}];
	}

/*****************************************************************************\
|* the view-controller for an item at a given index
\*****************************************************************************/
- (AZViewController *)viewControllerForItemAtIndex:(NSUInteger)index
	{
	return _visibleVCs[@(index)];
	}



// MARK: Swapping ViewControllers in and out

/*****************************************************************************\
|* We can recycle this view controller, so move it to the reusable list
\*****************************************************************************/
- (void)removeViewControllerForItemAtIndex:(NSUInteger)idx
	{
	AZViewController *vc = _visibleVCs[@(idx)];
	[vc.view removeFromSuperview];

	[self delegateUpdateDeselectionForItemAtIndex:idx];
	[self delegateViewControllerBecameInvisibleAtIndex:idx];

	[_reusableVCs addObject:vc];
	[_visibleVCs removeObjectForKey:@(idx)];
	}

/*****************************************************************************\
|* Recycle all the invisible view controllers
\*****************************************************************************/
- (void) removeInvisibleViewControllers
	{
	[self.indexesOfInvisibleViewControllers enumerateIndexesUsingBlock:
		^(NSUInteger idx, BOOL *stop)
			{
			[self removeViewControllerForItemAtIndex:idx];
			}];
	}

/*****************************************************************************\
|* Get a view controller that we can re-use, either from the pool, or by
|* asking the delegate for one
\*****************************************************************************/
- (AZViewController *) emptyViewControllerForInsertion
	{
	if (_reusableVCs.count > 0)
		{
    	AZViewController *vc = _reusableVCs.lastObject;
		[_reusableVCs removeLastObject];
		return vc;
		}

    return [_delegate reusableVCForCollectionView:self];
	}

/*****************************************************************************\
|* Add a view-controller (therefore a view) for an item that doesn't have one
\*****************************************************************************/
- (void) addMissingViewControllerForItemAtIndex:(NSUInteger)idx
									  withFrame:(NSRect)r
	{
	if (idx < _contentArray.count)
		{
		AZViewController *vc = [self emptyViewControllerForInsertion];
		[_visibleVCs setObject:vc forKey:@(idx)];

		id itemToLoad = [_contentArray objectAtIndex:idx];
		[_delegate collectionView:self
					   willShowVC:vc
						  forItem:itemToLoad];

		[vc.view setFrame:r];
		[vc.view setAutoresizingMask:AZViewMaxXMargin | AZViewMaxYMargin];
		[self addSubview:vc.view];
		if ([_selection containsIndex:idx])
			[self delegateUpdateSelectionForItemAtIndex:idx];
		}
	}

/*****************************************************************************\
|* Add any missing group-headers
\*****************************************************************************/
- (void)addMissingGroupHeaders
	{
	if (_groups.count > 0)
		{
		NSInteger groupHeight = self.groupHeaderHeight;
		SEL topSel = SELECTOR(@"topOffsetForItemsInCollectionView:");
		__block float top  = 0;

		[_groups enumerateObjectsUsingBlock:
			^(AZCVGroup *group, NSUInteger idx, BOOL *stop)
				{
				NSInteger gAt 		= [group itemRange].location;
				NSRect gRect  		= [_layoutManager rectOfItemAtIndex:gAt];

				NSRect groupRect	= NSMakeRect(0,
												 NSMinY(gRect)-groupHeight,
												 NSWidth(self.visibleRect),
												 groupHeight);
				if ((idx == 0) && (!group.isCollapsed))
					if ([_delegate respondsToSelector:topSel])
						{
						top = [_delegate topOffsetForItemsInCollectionView:self];
						groupRect.origin.y -= top;
						}

				BOOL visible = NSIntersectsRect(groupRect, self.visibleRect);
				AZViewController *gvc = _visibleVCs[@(idx)];

				[gvc.view setFrame:groupRect];
				if (visible && !gvc)
					{
					gvc = [_delegate collectionView:self headerForGroup:group];
					[self addSubview:gvc.view];
					[_visibleGroupVCs setObject:gvc forKey:@(idx)];
					[gvc.view setFrame:groupRect];
					}
				else if (!visible && gvc)
					{
					[gvc.view removeFromSuperview];
					[_visibleGroupVCs removeObjectForKey:@(idx)];
					}
				}];
		}
	}

/*****************************************************************************\
|* Add any missing view-controllers to the view
\*****************************************************************************/
- (void)addMissingViewControllersToView
	{
	dispatch_async(dispatch_get_main_queue(),
		^{
		NSRange items 	= self.rangeOfVisibleItemsWithOverflow;
		NSIndexSet *set	= [NSIndexSet indexSetWithIndexesInRange:items];
		[set enumerateIndexesUsingBlock:
			^(NSUInteger idx, BOOL *stop)
				{
				if (self.visibleVCs[@(idx)] == nil)
					{
					NSRect frame = [self.layoutManager rectOfItemAtIndex:idx];
					[self addMissingViewControllerForItemAtIndex:idx
													   withFrame:frame];
					}
				}];
		[self addMissingGroupHeaders];
		});
	}

/*****************************************************************************\
|* Move the view controllers to the correct position
\*****************************************************************************/
- (void)moveViewControllersToProperPosition
	{
	for (NSNumber *number in _visibleVCs)
		{
		NSRect r = [_layoutManager rectOfItemAtIndex:number.integerValue];
		if (!NSEqualRects(r, NSZeroRect))
			[_visibleVCs[number].view setFrame:r];
		}
	}



// MARK Selecting and Deselecting Items


/*****************************************************************************\
|* Select a single item
\*****************************************************************************/
- (void)selectItemAtIndex:(NSUInteger)index
	{
	[self selectItemAtIndex:index inBulk:NO];
	}


/*****************************************************************************\
|* Select a single item, and cope with doing this lots of times
\*****************************************************************************/
- (void)selectItemAtIndex:(NSUInteger)index inBulk:(BOOL)bulkSelecting
	{
	if (index >= _contentArray.count)
		return;
    
	AZViewController *vc = [self viewControllerForItemAtIndex:index];
	id item = [_contentArray objectAtIndex:index];

	SEL sel = SELECTOR(@"collectionView:shouldSelectItem:withVC:");
	BOOL maySelectItem = YES;
	if ([_delegate respondsToSelector:sel])
		maySelectItem = [_delegate collectionView:self
								 shouldSelectItem:item
										   withVC:vc];

	if (maySelectItem)
		{
		[_selection addIndex:index];
		[self delegateUpdateSelectionForItemAtIndex:index];
		[self delegateDidSelectItemAtIndex:index];
		if (!bulkSelecting)
			[self delegateCollectionViewSelectionDidChange];
		if (self.shouldDrawSelections)
			{
			NSRect dirty = [_layoutManager rectOfItemAtIndex:index];
			[self setNeedsDisplayInRect:dirty];
			}
		}
  
	if (!bulkSelecting)
		_lastSelectionIndex = index;
	}

/*****************************************************************************\
|* Select an item using an index-set
\*****************************************************************************/
- (void)selectItemsAtIndexes:(NSIndexSet *)indexes;
	{
	[indexes enumerateIndexesUsingBlock:
		^(NSUInteger idx, BOOL *stop)
			{
			[self selectItemAtIndex:idx inBulk:YES];
			}];

	_lastSelectionIndex = [indexes firstIndex];
	[self delegateCollectionViewSelectionDidChange];
	}

/*****************************************************************************\
|* Deselect an item at an index
\*****************************************************************************/
- (void)deselectItemAtIndex:(NSUInteger)index
	{
	[self deselectItemAtIndex:index inBulk:NO];
	}

/*****************************************************************************\
|* Deselect an item at an index, with the expectation that this is one of many
\*****************************************************************************/
- (void)deselectItemAtIndex:(NSUInteger)index inBulk:(BOOL)bulk;
	{
	if (index < _contentArray.count)
		{
		[_selection removeIndex:index];
		if (self.shouldDrawSelections)
			{
			NSRect dirty = [_layoutManager rectOfItemAtIndex:index];
			[self setNeedsDisplayInRect:dirty];
			}

		if (!bulk)
			[self delegateCollectionViewSelectionDidChange];
		[self delegateDidDeselectItemAtIndex:index];
		[self delegateUpdateDeselectionForItemAtIndex:index];
		}
	}

/*****************************************************************************\
|* Deselect an item using an index-set
\*****************************************************************************/
- (void)deselectItemsAtIndexes:(NSIndexSet *)indexes;
	{
	[indexes enumerateIndexesUsingBlock:
		^(NSUInteger idx, BOOL *stop)
			{
			[self deselectItemAtIndex:idx inBulk:YES];
			}];
	[self delegateCollectionViewSelectionDidChange];
	}

/*****************************************************************************\
|* Deselect everything
\*****************************************************************************/
- (void)deselectAllItems;
	{
	[self deselectItemsAtIndexes:_selection];
	}

/*****************************************************************************\
|* Select everything
\*****************************************************************************/
- (void)selectAll:(id)sender
	{
	NSRange range	= NSMakeRange(0, _contentArray.count);
	NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:range];
	[self selectItemsAtIndexes:set];
	}


// MARK: User interaction


/*****************************************************************************\
|* Yes, we can accept keystrokes
\*****************************************************************************/
- (BOOL)acceptsFirstResponder
	{
	return YES;
	}

/*****************************************************************************\
|* Ok, someone else got a chance
\*****************************************************************************/
- (BOOL)resignFirstResponder
	{
	SEL responderSel = SELECTOR(@"collectionViewLostFirstResponder:");
	if ([_delegate respondsToSelector:responderSel])
		[_delegate collectionViewLostFirstResponder:self];
	return [super resignFirstResponder];
	}

/*****************************************************************************\
|* We are #1 for keys
\*****************************************************************************/
- (BOOL)becomeFirstResponder
	{
	SEL responderSel = SELECTOR(@"collectionViewBecameFirstResponder:");
	if ([_delegate respondsToSelector:responderSel])
		[_delegate collectionViewBecameFirstResponder:self];
	return [super becomeFirstResponder];
	}

/*****************************************************************************\
|* Not yet implemented in Azoth, but when (if) it is...
\*****************************************************************************/
- (BOOL)canBecomeKeyView
	{
	return YES;
	}

// MARK: mouse

/*****************************************************************************\
|* Is shift or command being held down right now
\*****************************************************************************/
- (BOOL) shiftOrCommandKeyPressed
	{
	return (AZEvent.modifierFlags & AZShiftKeyMask)
		|| (AZEvent.modifierFlags & AZCommandKeyMask);
	}

/*****************************************************************************\
|* We got a mouse-down event
\*****************************************************************************/
- (BOOL)mouseDown:(AZEvent *)e
	{
	[self.window makeFirstResponder:self];

	_isDragging     = YES;
  	_atDown    		= [self convertPoint:e.locationInWindow fromView:nil];
  	_atDragged 		= _atDown;

	/*************************************************************************\
	|* See if we want to notify the delegate of a click
	\*************************************************************************/
	NSUInteger idx  = [_layoutManager indexOfItemContentRectAtPoint:_atDown];
	SEL didClick	= SELECTOR(@"collectionView:didClickItem:withVC:");
	if (idx != NSNotFound && [_delegate respondsToSelector:didClick])
		[_delegate collectionView:self
					 didClickItem:_contentArray[idx]
						   withVC:_visibleVCs[@(idx)]];

	if ((!self.shiftOrCommandKeyPressed) && ![_selection containsIndex:idx])
		[self deselectAllItems];
	_originalSelection = _selection.copy;

	/*************************************************************************\
	|* See if we want to notify the delegate of a double-click
	\*************************************************************************/
	SEL dblClick 		= SELECTOR(@"collectionView:didDoubleClickVC:");
	BOOL dlgDblClick	= [_delegate respondsToSelector:dblClick];
	if ((e.type == AZLeftMouseDown) && (e.clickCount == 2) && dlgDblClick)
		[_delegate collectionView:self
				 didDoubleClickVC:_visibleVCs[@(idx)]];

	if (self.shiftOrCommandKeyPressed && [_originalSelection containsIndex:idx])
		[self deselectItemAtIndex:idx];
	else
		{
		BOOL cmdKey = AZEvent.modifierFlags & AZCommandKeyMask;

		if (cmdKey || (_originalSelection.count == 0))
			[self selectItemAtIndex:idx];
		else if (AZEvent.modifierFlags & AZShiftKeyMask)
			{
			NSInteger one = _originalSelection.lastIndex;
			NSInteger two = idx;

			if (idx == NSNotFound)
				return NO;

			NSRange range;
			if (two > one)
				range = NSMakeRange(MIN(one,two), 1+MAX(one,two)-MIN(one,two));
			else
				range = NSMakeRange(MIN(one,two), MAX(one,two)-MIN(one,two));

			NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:range];
			[self selectItemsAtIndexes:set];
			}
		}
	return YES;
	}


/*****************************************************************************\
|* The mouse was dragged, check for drag-and-drop or defer to regular routine
\*****************************************************************************/
- (BOOL) mouseDragged:(AZEvent *)e
	{
	// NYI [self autoscroll:anEvent];

	if (_isDragging)
		{
		NSUInteger idx = [_layoutManager indexOfItemContentRectAtPoint:_atDown];
		BOOL dragOk    = [self delegateSupportsDragForItemsAtIndexes:_selection];
		dragOk 		  &= (_originalSelection.count > 0);

		if ((idx != NSNotFound) && (_selection.count > 0) && dragOk)
			{
			NSPoint mouse = [self convertPoint:e.locationInWindow fromView:nil];
			CGFloat distance = sqrt(pow(mouse.x-_atDown.x,2)
								   +pow(mouse.y-_atDown.y,2));
			if (distance > 3)
				[self initiateDraggingSessionWithEvent:e];
			}
		else
			[self regularMouseDragged:e];
		}
	return YES;
	}

/*****************************************************************************\
|* The mouse was dragged, regular style
\*****************************************************************************/
- (void)regularMouseDragged:(AZEvent *)e
	{
	NSIndexSet *originalSet 	= _selection.copy;
	_selectionChangedDisabled 	= YES;
	BOOL shiftOrCmd				= self.shiftOrCommandKeyPressed;

	[self deselectAllItems];
	if (shiftOrCmd)
		{
		[_originalSelection enumerateIndexesUsingBlock:
			^(NSUInteger idx, BOOL *stop)
				{
				[self selectItemAtIndex:idx];
				}];
		}

	[self setNeedsDisplay:YES];

	_atDragged 			= [self convertPoint:e.locationInWindow fromView:nil];
	NSRect dragRect		= NSRectFromTwoPoints(_atDown, _atDragged);
	NSIndexSet *suggest = [self indexesOfItemContentRectsInRect:dragRect];

	if (!shiftOrCmd)
		{
		NSMutableIndexSet *oldIndexes = _selection.mutableCopy;
		[oldIndexes removeIndexes:suggest];
		[self deselectItemsAtIndexes:oldIndexes];
		}
  
	[suggest enumerateIndexesUsingBlock:
		^(NSUInteger idx, BOOL *stop)
			{
			if (shiftOrCmd)
				{
				if ([_originalSelection containsIndex:idx])
					[self deselectItemAtIndex:idx];
				else
					[self selectItemAtIndex:idx];
				}
			else
				[self selectItemAtIndex:idx];
			}];
  
	[self setNeedsDisplayInRect:dragRect];

	_selectionChangedDisabled = NO;
	if (![_selection isEqual:originalSet])
		//[self performSelector:@selector(delegateCollectionViewSelectionDidChange)];
		[self delegateCollectionViewSelectionDidChange];
	}


/*****************************************************************************\
|* We released the mouse
\*****************************************************************************/
- (BOOL) mouseUp:(AZEvent *)e
	{

  	_atDown    			= NSZeroPoint;
  	_atDragged 			= NSZeroPoint;
	_isDragging			= NO;
	_dragHoverIndex		= NSNotFound;
	_originalSelection	= nil;

	[self setNeedsDisplay:YES];
	return YES;
	}



// MARK: Drag and drop support

/*****************************************************************************\
|* We want to allow copy-drags
\*****************************************************************************/
- (AZDragOperation) draggingSession:(AZDraggingSession *)session
			sourceOperationMaskForDraggingContext:(AZDraggingContext)context
	{
	return AZDragOperationCopy;
	}

/*****************************************************************************\
|* Called when the mouse drags a small way away from one of our items, having
|* previously already selected at least one item.
\*****************************************************************************/
- (void)initiateDraggingSessionWithEvent:(AZEvent *)e
	{
	id<AZPasteboardWriting> writer 			= nil;
	NSMutableArray<AZDraggingItem *> *items = NSMutableArray.new;

	SEL writeSel = SELECTOR(@"collectionView:writerForItem:");
	if ([_delegate respondsToSelector:writeSel])
		{
		SEL imgSel = SELECTOR(@"collectionView:imageForItemAtIndex:");
		if ([_delegate respondsToSelector:imgSel])
			{
			NSInteger index = _originalSelection.firstIndex;
			while (index != NSNotFound)
				{
				AZImage *img 		 = [_delegate collectionView:self
											imageForItemAtIndex:index];
				writer 				 = [_delegate collectionView:self
											writerForItemAtIndex:index];
				AZDraggingItem *item = [AZDraggingItem itemWithPasteboardWriter:img];
				NSRect itemRect 	 = [_layoutManager rectOfItemAtIndex:index];
				itemRect.origin.x 	-= _offset.x;
				itemRect.origin.y 	-= _offset.y;
				item.draggingFrame	 = itemRect;
				item.image			 = img;
				[items addObject:item];
				index = [_originalSelection indexGreaterThanIndex:index];
				}
			}
		else
			{
			SDL_Log("Collection view delegate responds to "
				    "collectionView:writerForItem: but not "
				    "collectionView:imageForItemAtIndex:");
			}
		}
	else
		{
		NSInteger idx = _originalSelection.firstIndex;
		while (idx != NSNotFound)
			{
			AZView *view 		 = [self viewControllerForItemAtIndex:idx].view;
			AZImage *img 		 = view.backingImage;
			img.identifier		 = [NSString stringWithFormat:@"%ld", (long)idx];
			AZDraggingItem *item = [AZDraggingItem itemWithPasteboardWriter:img];
			item.image			 = img;
			NSRect itemRect 	 = [_layoutManager rectOfItemAtIndex:idx];
			itemRect.origin.x 	-= _offset.x;
			itemRect.origin.y 	-= _offset.y;
			[item setDraggingFrame:itemRect];

			[items addObject:item];

			idx = [_originalSelection indexGreaterThanIndex:idx];
			}
		}

	[self beginDraggingSessionWithItems:items event:e source:self];
	}

/*****************************************************************************\
|* Invoked when the dragged image enters destination bounds or frame;
|* delegate returns dragging operation to perform.
\*****************************************************************************/
- (AZDragOperation) draggingEntered:(id<AZDraggingInfo>) sender
	{
	SEL dragEnter = SELECTOR(@"collectionView:draggingEntered:");
	if ([_delegate respondsToSelector:dragEnter])
		return [_delegate collectionView:self draggingEntered:sender];

    return [self draggingUpdated:sender];
	}

/*****************************************************************************\
|* Invoked periodically as the image is held within the destination area
|* allowing modification of the dragging operation or mouse-pointer position.
\*****************************************************************************/
- (AZDragOperation) draggingUpdated:(id<AZDraggingInfo>)sender;
	{
	if (_dragHoverIndex != NSNotFound)
		{
		NSRect where = [_layoutManager rectOfItemAtIndex:_dragHoverIndex];
		[self setNeedsDisplayInRect:where];
		}

	NSPoint mouse 	 = [self convertPoint:sender.draggingLocation fromView:nil];
	NSUInteger index = [_layoutManager indexOfItemAtPoint:mouse];

  	AZDragOperation operation = AZDragOperationNone;
	if ([sender draggingSource] == self)
		{
		if ([_selection containsIndex:index])
			[self setDragHoverIndex:NSNotFound];
		else if ([self _delegateCanDrop:sender onIndex:index])
			{
			[self setDragHoverIndex:index];
			operation = AZDragOperationMove;
			}
		else
			[self setDragHoverIndex:NSNotFound];
		}
	else
		{
		if ([self _delegateCanDrop:sender onIndex:index])
			{
			[self setDragHoverIndex:index];
			operation = AZDragOperationCopy;
			}
		}
  
	if (_dragHoverIndex != NSNotFound)
		{
		NSRect where = [_layoutManager rectOfItemAtIndex:_dragHoverIndex];
		[self setNeedsDisplayInRect:where];
		}
  
	return operation;
	}

/*****************************************************************************\
|* Inform the sender if we want to be updated (other than exit/enter)
\*****************************************************************************/
- (BOOL)wantsPeriodicDraggingUpdates
	{
	return YES;
	}


/*****************************************************************************\
|* Called when a drag operation ends
\*****************************************************************************/
- (void) draggingEnded:(id<AZDraggingInfo>) sender;
	{
	[self concludeDragOperation:sender];
	}

/*****************************************************************************\
|* Invoked when the dragged image exits the destination’s bounds rectangle
\*****************************************************************************/
- (void) draggingExited:(id<AZDraggingInfo>) sender
	{
	NSPoint mouse    = [self convertPoint:sender.draggingLocation fromView:nil];
	NSUInteger index = [_layoutManager indexOfItemAtPoint:mouse];

	if (index == NSNotFound)
		{
		NSRect where = [_layoutManager rectOfItemAtIndex:_dragHoverIndex];
		[self setNeedsDisplayInRect:where];
		[self setDragHoverIndex:NSNotFound];

		SEL dragExit = SELECTOR(@"collectionView:draggingExited:");
		if ([_delegate respondsToSelector:dragExit])
			[_delegate collectionView:self draggingExited:sender];
		}
	}


/*****************************************************************************\
|* Allow a drop to go ahead, let the delegate know
\*****************************************************************************/
- (BOOL) performDragOperation:(id<AZDraggingInfo>) sender;
	{
	AZViewController *vc	= nil;
	id item 				= nil;

	if ((_dragHoverIndex >= 0) && (_dragHoverIndex <_contentArray.count))
		item = _contentArray[_dragHoverIndex];

	SEL dragDo = SELECTOR(@"collectionView:performDragOperation:"
						   "onViewController:forItem:");
	if ([_delegate respondsToSelector:dragDo])
		{
		vc = [self viewControllerForItemAtIndex:_dragHoverIndex];
		return [_delegate collectionView:self
					performDragOperation:sender
						onViewController:vc
								 forItem:item];
		}

    return NO;
	}

/*****************************************************************************\
|* And handle the drop completing, sent if -performDragOperation returns YES
\*****************************************************************************/
- (void) concludeDragOperation:(id<AZDraggingInfo>) sender
	{
	if (_dragHoverIndex != NSNotFound)
		{
		NSRect where = [_layoutManager rectOfItemAtIndex:_dragHoverIndex];
		[self setNeedsDisplayInRect:where];

		[self setDragHoverIndex:NSNotFound];

		SEL dragDone = SELECTOR(@"collectionView:draggingEnded:");
		if ([_delegate respondsToSelector:dragDone])
			[_delegate collectionView:self draggingEnded:sender];
		}
	}

/*****************************************************************************\
|* Set the hover-index for when we're accepting a drop
\*****************************************************************************/
- (void)setDragHoverIndex:(NSInteger)hoverIndex
	{
	AZViewController *vc = nil;

	if (hoverIndex != _dragHoverIndex)
		{
		if (_dragHoverIndex != NSNotFound)
			{
			NSRect where = [_layoutManager rectOfItemAtIndex:_dragHoverIndex];
			[self setNeedsDisplayInRect:where];
			}

		SEL exitSel = SELECTOR(@"collectionView:dragExitedViewController:");
		vc = [self viewControllerForItemAtIndex:_dragHoverIndex];

		if ([_delegate respondsToSelector:exitSel])
			[_delegate collectionView:self dragExitedViewController:vc];

		_dragHoverIndex = hoverIndex;

		SEL enterSel = SELECTOR(@"collectionView:dragEnteredViewController:");
		vc 			 = [self viewControllerForItemAtIndex:_dragHoverIndex];
		if ([_delegate respondsToSelector:enterSel])
			[_delegate collectionView:self dragEnteredViewController:vc];

		if (_dragHoverIndex != NSNotFound)
			{
			NSRect where = [_layoutManager rectOfItemAtIndex:_dragHoverIndex];
			[self setNeedsDisplayInRect:where];
			}
		}
	}

/*****************************************************************************\
|* Do we support drag for a set of indices
\*****************************************************************************/
- (BOOL) delegateSupportsDragForItemsAtIndexes:(NSIndexSet *)indexSet
	{
	SEL dragSel = SELECTOR(@"collectionView:canDragItemsAtIndexes:");
	if ([_delegate respondsToSelector:dragSel])
		return [_delegate collectionView:self canDragItemsAtIndexes:indexSet];
	return NO;
	}

/*****************************************************************************\
|* If the delegate allows us to drop on an item, go for it, otherwise refuse
\*****************************************************************************/
- (BOOL)_delegateCanDrop:(id)draggingInfo onIndex:(NSUInteger)index
	{
	SEL canDrop = SELECTOR(@"collectionView:validateDrop:onItemAtIndex:");
	if ([_delegate respondsToSelector:canDrop])
		return [_delegate collectionView:self
							validateDrop:draggingInfo
						  onItemAtIndex:index];
    return NO;
	}



// MARK: Reloading and Updating the Icon View

/*****************************************************************************\
|* Do a reload just of the visible VCs
\*****************************************************************************/
- (void)softReloadVisibleViewControllers
	{
	NSMutableArray *removeKeys = NSMutableArray.new;

	for (NSNumber *number in _visibleVCs)
		{
		NSUInteger index		= number.integerValue;
		AZViewController *vc	= _visibleVCs[number];

		if (index < _contentArray.count)
			{
			if ([_selection containsIndex:index])
				[self delegateUpdateDeselectionForItemAtIndex:index];

			[_delegate collectionView:self
						   willShowVC:vc
						      forItem:_contentArray[index]];
			}
		else
			{
			if ([_selection containsIndex:index])
				[self delegateUpdateDeselectionForItemAtIndex:index];
      
			[self delegateViewControllerBecameInvisibleAtIndex:index];
			[vc.view removeFromSuperview];
			[_reusableVCs addObject:vc];
			[removeKeys addObject:number];
			}
		}

	[_visibleVCs removeObjectsForKeys:removeKeys];
	}

/*****************************************************************************\
|* Resize the frame to fit the contents
\*****************************************************************************/
- (void)resizeFrameToFitContents
	{
	NSRect frame 						= self.frame;
	frame.size.height 					= self.visibleRect.size.height;

	if (_contentArray.count > 0)
		{
		AZCVLayoutItem *item = [_layoutManager.itemLayouts lastObject];
		frame.size.height 	 = MAX(frame.size.height, NSMaxY(item.itemRect));
		}

	self.frame = frame;
	}

/*****************************************************************************\
|* Add items, optionally clear the cache
\*****************************************************************************/
- (void)reloadDataWithItems:(NSArray *)newContent
				emptyCaches:(BOOL)yn
	{
	[self reloadDataWithItems:newContent
					   groups:nil
				  emptyCaches:yn];
	}

/*****************************************************************************\
|* Add items, specify groups, optionally clear the cache
\*****************************************************************************/
- (void)reloadDataWithItems:(NSArray *)newContent
					 groups:(NSArray *)newGroups
				emptyCaches:(BOOL)yn
	{
	[self reloadDataWithItems:newContent
					   groups:newGroups
				  emptyCaches:yn
			  completionBlock:^{}];
	}

/*****************************************************************************\
|* Add items, specify groups, run a block when done, optionally clear the cache
\*****************************************************************************/
- (void)reloadDataWithItems:(NSArray *)newContent
					 groups:(NSArray *)newGroups
				emptyCaches:(BOOL)shouldEmptyCaches
		    completionBlock:(dispatch_block_t)completionBlock
	{

	[self deselectAllItems];
	[_layoutManager cancelItemEnumerator];

	if (_delegate == nil)
		return;
  
	NSRect frame	= self.frame;
	NSSize size 	= [_delegate cellSizeForCollectionView:self];
	if ((NSWidth(frame) < size.width) || (NSHeight(frame) < size.height))
		return;
  
	for (AZCVGroup *group in _groups)
		[group removeObserver:self forKeyPath:@"isCollapsed"];
	for (AZCVGroup *group in newGroups)
		[group addObserver:self forKeyPath:@"isCollapsed" options:0 context:nil];

	self.groups       = newGroups;
	self.contentArray = newContent;
  
	for (AZViewController *vc in _visibleGroupVCs.allValues)
		[vc.view removeFromSuperview];
	[_visibleVCs removeAllObjects];
  
	if (shouldEmptyCaches)
		{
		SEL visSel = SELECTOR(@"collectionView:VCNoLongerVisible:");
		for (AZViewController *vc in _visibleVCs.allValues)
			{
			[vc.view removeFromSuperview];
			if ([_delegate respondsToSelector:visSel])
				[_delegate collectionView:self VCNoLongerVisible:vc];
			}
    
		[_reusableVCs removeAllObjects];
		[_visibleVCs removeAllObjects];
		}
	else
		[self softReloadVisibleViewControllers];
  
	[_selection removeAllIndexes];

	NSRect visibleRect = self.visibleRect;
	[_layoutManager enumerateItems:
		^(AZCVLayoutItem *layoutItem)
			{
			NSInteger index = layoutItem.itemIndex;
			NSRect rect		= layoutItem.itemRect;

			AZViewController *vc = [self viewControllerForItemAtIndex:index];
			if (vc)
				{
				[vc.view setFrame:rect];
				[self.delegate collectionView:self
								   willShowVC:vc
									  forItem:[self.contentArray objectAtIndex:index]];
				}
			else if (NSIntersectsRect(visibleRect, rect))
				[self addMissingViewControllerForItemAtIndex:index
												   withFrame:rect];
			}
		completionBlock:
			^{
			[self resizeFrameToFitContents];
			[self addMissingGroupHeaders];
			dispatch_async(dispatch_get_main_queue(), completionBlock);
			}];
	}

/*****************************************************************************\
|* Called when we scroll
\*****************************************************************************/
- (void)scrollViewDidScroll:(NSNotification *)note
	{
	dispatch_async(dispatch_get_main_queue(),
		^{
		[self removeInvisibleViewControllers];
		[self addMissingViewControllersToView];
		});

	SEL scrollSel = SELECTOR(@"collectionViewDidScroll:inDirection:");
	if ([_delegate respondsToSelector:scrollSel])
		{
		if (self.visibleRect.origin.y > _previousFrameBounds.origin.y)
			[_delegate collectionViewDidScroll:self inDirection:AZCVScrollDown];
		else
			[_delegate collectionViewDidScroll:self inDirection:AZCVScrollUp];
		_previousFrameBounds = self.visibleRect;
		}
	[self setNeedsDisplay:YES];
	}

/*****************************************************************************\
|* Called when the view changes size
\*****************************************************************************/
- (void)viewDidResize
	{
	if ((_contentArray.count > 0) && (_visibleVCs.count > 0))
		[self softReloadDataWithCompletionBlock:nil];
	}

/*****************************************************************************\
|* Handle a resize
\*****************************************************************************/
- (void)softReloadDataWithCompletionBlock:(nullable dispatch_block_t)block
	{
	NSSize size 	= [_delegate cellSizeForCollectionView:self];
	NSRect visible	= self.visibleRect;

	if (NSWidth(visible) < size.width || NSHeight(visible) < size.height)
		return;
  
	NSRange range = [self rangeOfVisibleItemsWithOverflow];
	[_layoutManager enumerateItems:
		^(AZCVLayoutItem *layoutItem)
			{
			NSInteger idx 	= layoutItem.itemIndex;
			NSRect rect		= layoutItem.itemRect;

			if (NSLocationInRange(idx, range))
				{
				AZViewController *vc = [self viewControllerForItemAtIndex:idx];
				if (vc)
					[vc.view setFrame:rect];
				else
					[self addMissingViewControllerForItemAtIndex:idx
													   withFrame:rect];
				}
			else
				{
				if ([self viewControllerForItemAtIndex:idx])
					[self removeViewControllerForItemAtIndex:idx];
				}
			}
		completionBlock:^(void)
			{
			[self resizeFrameToFitContents];
			[self addMissingGroupHeaders];
			[self setNeedsDisplay:YES];
			if (block != NULL)
				block();
			}];
	}

/*****************************************************************************\
|* Handle a context-menu option
\*****************************************************************************/
- (AZMenu *) menuForEvent:(AZEvent *)anEvent
	{
	[self mouseDown:anEvent];

	SEL menuSel = SELECTOR(@"collectionView:menuForItemsAtIndexes:");
	if ([_delegate respondsToSelector:menuSel])
		return [_delegate collectionView:self
				   menuForItemsAtIndexes:self.selection];
	return nil;
	}

@end
