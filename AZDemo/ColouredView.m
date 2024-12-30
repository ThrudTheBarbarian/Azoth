//
//  ColouredView.m
//  AZDemo
//
//  Created by Simon Gornall on 12/24/24.
//


#import "ColouredView.h"

@interface ColouredView()
@property(strong, nonatomic) AZImage *									img;
@end

@implementation ColouredView

- (instancetype) initWithFrame:(NSRect)frame colour:(AZColour *)colour
	{
	if (self = [super initWithFrame:frame])
		{
		self.backgroundColour = colour;

		// Create the image (just a reference to a texture)
		_img = [AZImage imageWithSize:NSMakeSize(100,100)
					   drawingHandler:
					   ^BOOL(NSRect dstRect, AZPainter * _Nonnull P)
			{
			int mx = self.img.width;
			int my = self.img.height;

			// Draw a cross onto the image
			float dx = self.angle/5;

			[P lineAtX:dx y:0 toX:mx-dx y:my colour:AZColour.greenColour];
			[P lineAtX:mx y:0 toX:0 y:my colour:AZColour.blueColour];
			return YES;

			} clearBeforeDraw:YES];

//		int mx = _img.width;
//		int my = _img.height;
//
//		// Draw a cross onto the image
//		AZPainter *P = [_img lockFocus:YES];
//		[P lineAtX:0 y:0 toX:mx y:my colour:AZColour.greenColour];
//		[P lineAtX:mx y:0 toX:0 y:my colour:AZColour.blueColour];

		_angle = 0;
		NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
		[nc addObserver:self selector:@selector(angleChanged:) name:@"slider" object:nil];
		}
	return self;
	}

- (void) angleChanged:(NSNotification *)n
	{
	_angle = ((NSNumber *)n.object).intValue;
	[self setNeedsDisplay:YES];
	}

- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
//		NSLog(@"Drawing image (%d,%d) into view (%@)", (int)_img.width,
//			  (int)_img.height, NSStringFromRect(self.frame));

	//[painter image:_img to:self.visibleRect];

	//[painter image:_img at:NSMakePoint(0,0)];

//	NSRect src = NSMakeRect(_img.width/2 - 50, _img.height/2 - 50, 100, 100);
//	[painter image:_img from:src at:NSMakePoint(10,10)];
//	[painter rectangleWithRect:NSMakeRect(10, 10, 100, 100) colour:AZColour.redColour];

//	NSRect src = NSMakeRect(_img.width/2 - 10, _img.height/2 - 10, 20, 20);
//	NSRect dst = NSMakeRect(10, 10, 100, 100);
//	[painter image:_img from:src to:dst];
//	[painter rectangleWithRect:dst colour:AZColour.redColour];

//	NSRect dst 		= NSMakeRect(100, 100, 100, 100);
//	NSPoint about 	= NSMakePoint(25,0);
//	[painter image:_img at:dst.origin angle:_angle about:about flip:AZFlipNone];
//	NSRect dst 		= NSMakeRect(100, 100, 100, 100);

	NSRect dst 		= NSMakeRect(100, 100, 100, 100);
	NSRect src		= NSMakeRect(25, 25, 50, 50);
	NSPoint about 	= NSMakePoint(10,0);
	[painter image:_img from:src at:dst.origin angle:_angle about:about flip:AZFlipNone];
	[painter rectangleWithRect:dst colour:AZColour.redColour];
	}

@end
