//
//  AZCollectionView.m
//  Azoth
//
//  Created by Simon Gornall on 1/7/25.
//

#import "AZClipView.h"
#import "AZCollectionView.h"
#import "AZCollectionViewDelegate.h"
#import "AZColour.h"
#import "AZCVGroup.h"
#import "AZCVLayoutItem.h"
#import "AZCVLayoutManager.h"
#import "AZGeometry.h"
#import "AZNotifications.h"
#import "AZPainter.h"
#import "AZScrollView.h"
#import "AZViewController.h"

/*****************************************************************************\
|* "Private" Properties
\*****************************************************************************/
@interface AZCollectionView()

// Current selection
@property (readonly) NSMutableIndexSet *				selection;

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

// MARK: Drawing

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
				 : AZColour.whiteColour;

	[painter rectangleWithRect:dirtyRect filled:YES colour:bg];

	NSRect frame = NSRectFromTwoPoints(_atDown, _atDragged);
	[painter rectangleWithRect:frame colour:AZColour.grey50Colour];

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
	NSRect inset = NSInsetRect(aRect, 10, 10);
	[painter rectangleWithRect:inset
						radius:10
						filled:YES
						colour:AZColour.grey75Colour];
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
		[vc.view setFrame:r];
		[vc.view setAutoresizingMask:AZViewMaxXMargin | AZViewMaxYMargin];

		id itemToLoad = [_contentArray objectAtIndex:idx];
		[_delegate collectionView:self
					   willShowVC:vc
						  forItem:itemToLoad];

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

@end
