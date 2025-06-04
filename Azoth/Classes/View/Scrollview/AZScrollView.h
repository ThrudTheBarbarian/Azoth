//
//  AZScrollView.h
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <Azoth/AZView.h>
#import <Azoth/AZTypes.h>

@class AZColour;
@class AZClipView;
@class AZRulerView;
@class AZScroller;

NS_ASSUME_NONNULL_BEGIN

@interface AZScrollView : AZView

/*****************************************************************************\
|* Lay out the scroll view
\*****************************************************************************/
- (void)tile;

/*****************************************************************************\
|* Class methods: Work out the frame size for a given content size (or vice
|* versa), taking into account whether the scrollers exist or not
\*****************************************************************************/
+ (NSSize) frameSizeForContentSize:(NSSize)contentSize
			 hasHorizontalScroller:(BOOL)hasHorizontalScroller
			   hasVerticalScroller:(BOOL)hasVerticalScroller
						borderType:(AZBorderType)borderType;

+ (NSSize) contentSizeForFrameSize:(NSSize)frameSize
			 hasHorizontalScroller:(BOOL)hasHorizontalScroller
			   hasVerticalScroller:(BOOL)hasVerticalScroller
						borderType:(AZBorderType)borderType;

/*****************************************************************************\
|* Get/Set which class of view will implement the ruler views
\*****************************************************************************/
+ (void) setRulerViewClass:(Class)klass;
+ (Class) rulerViewClass;

/*****************************************************************************\
|* Return the size of the content itself
\*****************************************************************************/
- (NSSize)contentSize;

/*****************************************************************************\
|* Return the visible rectangle of the document view
\*****************************************************************************/
- (NSRect) documentVisibleRect;

/*****************************************************************************\
|* Document view changed, make sure the scrollers update
\*****************************************************************************/
- (void)reflectScrolledClipView:(AZClipView *)clipView;

/*****************************************************************************\
|* Convenience methods to change line/page increments for both axes at once
\*****************************************************************************/
-(void)setLineScroll:(float)value;
-(void)setPageScroll:(float)value;

/*****************************************************************************\
|* Return the header view 
\*****************************************************************************/
- (nullable AZView *) headerView;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The documentview - the view we are actually
// scrolling around
@property(strong, nonatomic) AZView *					documentView;

// The clipview that controls the documentview
@property(strong, nonatomic) AZClipView *				contentView;

// The clipview that controls the headerview
@property(strong, nonatomic, nullable) AZClipView *		headerClipView;

// The corner-view: where scrollers aren't
@property(strong, nonatomic, nullable) AZView *			cornerView;

// The vertical scroller
@property(strong, nonatomic, nullable) AZScroller *		verticalScroller;

// The horizontal scroller
@property(strong, nonatomic, nullable) AZScroller *		horizontalScroller;

// The vertical ruler
@property(strong, nonatomic, nullable) AZRulerView *	verticalRulerView;

// The horizontal ruler
@property(strong, nonatomic, nullable) AZRulerView *	horizontalRulerView;

// The amount to scroll by vertically, 1 line,
// if wanting to specify separately from lineScroll
@property(assign, nonatomic) float 						verticalLineScroll;

// The amount to scroll by vertically, 1 page
// if wanting to specify separately from pageScroll
@property(assign, nonatomic) float 						verticalPageScroll;

// The amount to scroll by horizontally, 1 line
// if wanting to specify separately from lineScroll
@property(assign, nonatomic) float 						horizontalLineScroll;

// The amount to scroll by horizontally, 1 page
// if wanting to specify separately from pageScroll
@property(assign, nonatomic) float 						horizontalPageScroll;

// Whether we have a horizontal scroller
@property(assign, nonatomic) BOOL						hasHorizontalScroller;

// Whether we have a vertical scroller
@property(assign, nonatomic) BOOL						hasVerticalScroller;

// Whether we have a horizontal ruler
@property(assign, nonatomic) BOOL						hasHorizontalRuler;

// Whether we have a vertical ruler
@property(assign, nonatomic) BOOL						hasVerticalRuler;

// Whether we scroll dynamically
@property(assign, nonatomic) BOOL						scrollsDynamically;

// Whether we autohide the scrollers
@property(assign, nonatomic) BOOL						autohidesScrollers;

// Whether we draw the background
@property(assign, nonatomic) BOOL						drawsBackground;

// Are the rulers visible
@property(assign, nonatomic) BOOL						rulersVisible;

// How to draw the borders
@property(assign, nonatomic) AZBorderType				borderType;
@end

NS_ASSUME_NONNULL_END
