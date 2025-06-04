//
//  AZTableCornerView.m
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import "AZTableCornerView.h"

@implementation AZTableCornerView

- (void)drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[painter rectangleWithButton:self.bounds withClip:self.bounds];
	}

@end
