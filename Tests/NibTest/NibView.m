//
//  NibView.m
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import "NibView.h"

@implementation NibView

/*****************************************************************************\
|* Configuration via visible frame
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super initWithFrame:frame])
		{
		self.backgroundColour = AZColour.purpleColour;
		}
	return self;
	}

/*****************************************************************************\
|* Configuration via dictionary. This is called by the NIB loader, but is a
|* valid way to create the view
\*****************************************************************************/
- (instancetype) initWithDictionary:(NSDictionary *)info;
	{
	if (self = [super initWithDictionary:info])
		{
		self.backgroundColour = AZColour.purpleColour;
		}
	return self;
	}
@end
