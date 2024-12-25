//
//  ColouredView.m
//  AZDemo
//
//  Created by Simon Gornall on 12/24/24.
//

#import "ColouredView.h"

@implementation ColouredView

- (instancetype) initWithFrame:(NSRect)frame colour:(AZColour *)colour
	{
	if (self = [super init])
		{
		self.backgroundColour = colour;
		}
	return self;
	}

@end
