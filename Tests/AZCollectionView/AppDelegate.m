//
//  AppDelegate.m
//  AZCollectionView
//
//  Created by Simon Gornall on 1/8/25.
//

#import <SDL3/SDL.h>

#import "AppDelegate.h"
#import "CVItemViewController.h"

@interface AppDelegate ()
@property(strong, nonatomic) NSMutableArray<AZImage *> *		images;
@property(strong, nonatomic) AZCollectionView *					collection;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)n
	{
	_images = NSMutableArray.new;

	/*************************************************************************\
	|* Create some random image-views to act as content
	\*************************************************************************/
	NSArray<NSString *> *systemImages = AZApp.systemSymbolNames;
	NSArray<NSString *> *sorted = [systemImages sortedArrayUsingComparator:
		^NSComparisonResult(NSString *s1, NSString *s2)
			{
			return [s1 compare:s2];
			}];
	int numImages = (int) systemImages.count;
	for (int i=0; i<numImages; i++)
		{
		NSString *name		= sorted[i];
		AZImage *img		= [AZImage imageWithSystemSymbolName:name];
		img.identifier		= name;
		[_images addObject:img];
		}
	SDL_Log("Added %d images", numImages);

	/*************************************************************************\
	|* Set up the UI for this application
	\*************************************************************************/
	AZView *cv		= [AZWindow contentViewForWindow:AZApp.window];
	[cv setIdentifier:@"content-view"];

	/*************************************************************************\
	|* Create the collection view
	\*************************************************************************/
	NSRect frame 	= NSInsetRect(cv.frame, 20, 20);
	NSRect bounds 	= frame;
	bounds.origin = (NSPoint){0,0};
	_collection = [[AZCollectionView alloc] initWithFrame:bounds];
	_collection.delegate = self;
	_collection.backgroundColour = [AZColour colourNamed:@"snow"];
	[_collection registerForDraggedTypes:@[AZPasteboardTypeImage]];

	/*************************************************************************\
	|* Add it to a scrollview
	\*************************************************************************/
	AZScrollView *sv = [[AZScrollView alloc] initWithFrame:frame];
	[sv setHasVerticalScroller:YES];
	[sv setHasHorizontalScroller:NO];
	[sv setBorderType: AZLineBorder];
	[sv setDocumentView:_collection];
	sv.autoresizingMask = AZViewHeightSizable|AZViewWidthSizable;

	/*************************************************************************\
	|* Add the scrollview to the contentview
	\*************************************************************************/
	[cv addSubview:sv];

	/*************************************************************************\
	|* Tell the collection view to load up its data
	\*************************************************************************/
	[_collection reloadDataWithItems:_images emptyCaches:NO];
	}

// MARK: AZCollectionView

/*****************************************************************************\
|* Return the size of a given cell
\*****************************************************************************/
- (NSSize) cellSizeForCollectionView:(AZCollectionView *)cv
	{
	return NSMakeSize(160, 97);
	}

/*****************************************************************************\
|* Create a view-controller for the cell, these will be recycled as needed
|* as views go off-screen
\*****************************************************************************/
- (AZViewController *) reusableVCForCollectionView:(AZCollectionView *)cv
	{
	CVItemViewController *vc = nil;

	NSBundle *bundle = [NSBundle bundleForClass:self.class];
	vc = [[CVItemViewController alloc] initWithNibName:@"item" bundle:bundle];
	vc.view.backgroundColour = AZColour.clear;
	vc.label.alignment = AZTextAlignmentCenter;
		vc.image.backgroundColour = AZColour.clear;
	return vc;
	}

/*****************************************************************************\
|* Because they're being recycled, we need to be able to reconfigure the VC
|* when it's about to be displayed
\*****************************************************************************/
- (void) collectionView:(AZCollectionView *)cv
			 willShowVC:(AZViewController *)vc
			    forItem:(id)anItem
	{
	CVItemViewController *ctrl 	= (CVItemViewController *)vc;
	AZImage *img				= (AZImage *)anItem;

	ctrl.view.backgroundColour	= AZColour.clear;
	ctrl.image.image 			= img;
	ctrl.label.stringValue 		= img.identifier;
	}

/*****************************************************************************\
|* Allow drag
\*****************************************************************************/
- (BOOL) collectionView:(AZCollectionView *)cv
	canDragItemsAtIndexes:(NSIndexSet *)indexSet
	{
	return YES;
	}

/*****************************************************************************\
|* Allow drop
\*****************************************************************************/
- (BOOL) collectionView:(AZCollectionView *)cv
		   validateDrop:(id<AZDraggingInfo>)info
		  onItemAtIndex:(NSInteger)index
	{
	return YES;
	}

/*****************************************************************************\
|* Pretend to complete the drop
\*****************************************************************************/
- (BOOL) collectionView:(AZCollectionView *)cv
   performDragOperation:(id<AZDraggingInfo>)info
	   onViewController:(AZViewController *)vc
				forItem:(id)item
	{
	AZPasteboard *pb = [AZPasteboard draggingPasteboard];
	NSArray *items = [pb propertyListForType:AZPasteboardTypeImage];

	NSMutableArray *names = NSMutableArray.new;
	for (NSDictionary *item in items)
		{
		NSInteger idx = ((NSString *)item[@"identifier"]).integerValue;
		AZImage *img  = _images[idx];
		[names addObject:img.identifier];
		}

	NSLog(@"dropped %@", names);
	return YES;
	}

@end
