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
		}
	return self;
	}

- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	}

@end
