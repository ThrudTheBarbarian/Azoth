//
//  AppDelegate.m
//  AZImageView
//
//  Created by Simon Gornall on 12/30/24.
//

#import "AppDelegate.h"

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AppDelegate()
@property(strong, nonatomic) AZImageView * 							imageView;
@end

@implementation AppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)notification
	{
	AZApp *app = AZApp.sharedInstance;

	/*************************************************************************\
	|* Set up the UI for this application
	\*************************************************************************/
	AZView *cv		= [AZWindow contentViewForWindow:app.window];
	[cv setIdentifier:@"content-view"];
	[cv setBackgroundColour:[AZColour grey37Colour]];

	/*************************************************************************\
	|* Load the images
	\*************************************************************************/
	_small 		= [AZImage imageWithSystemSymbolName:@"update"];
	_medium		= [AZImage imageNamed:@"medium.png"];
	_large 		= [AZImage imageNamed:@"large.png"];

	/*************************************************************************\
	|* Create the imageview @ 256x256
	\*************************************************************************/
	NSRect frame	= NSMakeRect(16,16,256, 256);
	_imageView 		= [AZImageView imageViewWithImage:_medium inFrame:frame];
	_imageView.backgroundColour = AZColour.whiteColour;
	_imageView.scaling			= AZImageScaleNone;
	[cv addSubview:_imageView];

	/*************************************************************************\
	|* Create a popup for the scaling options
	\*************************************************************************/
	frame 				 = NSMakeRect(300, 16, 150, 25);
	AZPopupButton *scale = [AZPopupButton buttonWithFrame:frame pullsDown:YES];
	[scale addItemsWithTitles:@[@"None", @"Scale down", @"Scale both", @"Fit"]];
	[scale.itemArray[0] setTitle:@"Scaling..."];
	[scale setTarget:self];
	[scale setAction:@selector(chooseScale:)];
	[cv addSubview:scale];

	/*************************************************************************\
	|* Create a popup for the alignment options
	\*************************************************************************/
	frame 				 = NSMakeRect(300, 66, 150, 25);
	AZPopupButton *align = [AZPopupButton buttonWithFrame:frame pullsDown:YES];
	[align addItemsWithTitles:@[@"Top Left", @"Top Middle", @"Top Right",
							    @"Left", @"Center", @"Right",
							    @"Bottom Left", @"Bottom Middle", @"Bottom Right"]];
	[align.itemArray[0] setTitle:@"Alignment..."];
	[align setTarget:self];
	[align setAction:@selector(chooseAlignment:)];
	[cv addSubview:align];

	/*************************************************************************\
	|* Create a popup for the frame style
	\*************************************************************************/
	frame 				 = NSMakeRect(300, 116, 150, 25);
	AZPopupButton *style = [AZPopupButton buttonWithFrame:frame pullsDown:YES];
	[style addItemsWithTitles:@[@"None", @"Photo", @"Gray Bezel",
							    @"Groove", @"Button"]];
	[style.itemArray[0] setTitle:@"Frame style..."];
	[style setTarget:self];
	[style setAction:@selector(chooseStyle:)];
	[cv addSubview:style];

	/*************************************************************************\
	|* Create a popup for the image
	\*************************************************************************/
	frame 				 = NSMakeRect(300, 166, 150, 25);
	AZPopupButton *image = [AZPopupButton buttonWithFrame:frame pullsDown:YES];
	[image addItemsWithTitles:@[@"Small", @"Medium", @"Large"]];
	[image.itemArray[0] setTitle:@"Image..."];
	[image setTarget:self];
	[image setAction:@selector(chooseImage:)];
	[cv addSubview:image];

	}

/*****************************************************************************\
|* Handle changing the image
\*****************************************************************************/
- (void)chooseImage:(AZPopupButton *)style
	{
	AZImage *img = nil;
	switch (style.indexOfSelectedItem)
		{
		case 1:
			img = _small;
			break;

		case 2:
			img = _medium;
			break;

		case 3:
			img = _large;
			break;
		}

	[_imageView setImage:img];
	}

/*****************************************************************************\
|* Handle changing the style
\*****************************************************************************/
- (void)chooseStyle:(AZPopupButton *)style
	{
	AZImageFrameStyle framing = -1;
	switch (style.indexOfSelectedItem)
		{
		case 1:
			framing = AZImageFrameNone;
			break;

		case 2:
			framing = AZImageFramePhoto;
			break;

		case 3:
			framing = AZImageFrameGrayBezel;
			break;

		case 4:
			framing = AZImageFrameGroove;
			break;

		case 5:
			framing = AZImageFrameButton;
			break;
		}

	[_imageView setFrameStyle:framing];
	}

/*****************************************************************************\
|* Handle changing the scale
\*****************************************************************************/
- (void)chooseScale:(AZPopupButton *)scale
	{
	AZImageScaling scaling = -1;
	switch (scale.indexOfSelectedItem)
		{
		case 1:
			scaling = AZImageScaleNone;
			break;

		case 2:
			scaling = AZImageScaleProportionallyDown;
			break;

		case 3:
			scaling = AZImageScaleProportionallyUpOrDown;
			break;

		case 4:
			scaling = AZImageScaleAxesIndependently;
			break;
		}

	[_imageView setScaling:scaling];
	}

/*****************************************************************************\
|* Handle changing the alignment
\*****************************************************************************/
- (void)chooseAlignment:(AZPopupButton *)align
	{
	AZImageAlignment alignment = -1;
	switch (align.indexOfSelectedItem)
		{
		case 1:
			alignment = AZImageAlignTopLeft;
			break;

		case 2:
			alignment = AZImageAlignTop;
			break;

		case 3:
			alignment = AZImageAlignTopRight;
			break;

		case 4:
			alignment = AZImageAlignLeft;
			break;

		case 5:
			alignment = AZImageAlignCenter;
			break;

		case 6:
			alignment = AZImageAlignRight;
			break;

		case 7:
			alignment = AZImageAlignBottomLeft;
			break;

		case 8:
			alignment = AZImageAlignBottom;
			break;

		case 9:
			alignment = AZImageAlignBottomRight;
			break;

		}

	[_imageView setAlignment:alignment];
	}

@end
