//
//  MainView.m
//  AZFullscreen
//
//  Created by Simon Gornall on 3/11/25.
//

#import "MainView.h"

@implementation MainView

- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	AZColour *red = AZColour.red;
	[painter rectangleWithRect:self.bounds colour:red];
	[painter lineAtX:0 y:0 toX:1919 y:1079];
	[painter lineAtX:1919 y:0 toX:0 y:1079];
	}

@end
