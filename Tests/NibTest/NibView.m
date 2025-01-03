//
//  NibView.m
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import "NibView.h"

@implementation NibView

- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super initWithFrame:frame])
		{
		self.backgroundColour = AZColour.purpleColour;
		}
	return self;
	}
@end
