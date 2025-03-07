//
//  ColouredView.m
//  AZDemo
//
//  Created by ThrudTheBarbarian on 12/24/24.
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
		}
	return self;
	}

- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	int dashes[] = {5,7,9,3};
	NSRect r = NSInsetRect(self.bounds, 5, 5);

	[painter rectangleInRect:r num:4 dashes:dashes inColour:AZColour.green withClip:self.bounds];
	}

@end
