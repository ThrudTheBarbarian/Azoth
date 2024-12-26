//
//  AZTableCornerView.m
//  Azoth
//
//  Created by Simon Gornall on 12/25/24.
//

#import "AZTableCornerView.h"

@implementation AZTableCornerView

- (void)drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[painter rectangleWithButton:self.bounds withClip:self.bounds];
	}

@end
