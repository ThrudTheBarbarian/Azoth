//
//  AZNibHelpConnector.m
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import "AZNibHelpConnector.h"
#import "AZTypes.h"

@implementation AZNibHelpConnector


/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
-initWithCoder:(NSCoder *)coder
	{
	if (self = [super initWithCoder:coder])
		{
		if ([coder allowsKeyedCoding])
			{
			if ([coder containsValueForKey: @"NSFile"])
				_file = [coder decodeObjectForKey: @"NSFile"];

			if ([coder containsValueForKey: @"NSMarker"])
				_marker = [coder decodeObjectForKey: @"NSMarker"];
			}
		}
	return self;
	}

/*****************************************************************************\
|* Make the connection
\*****************************************************************************/
-(void)establishConnection
	{
	SEL setToolTip = SELECTOR(@"setToolTip:");
	if ([self.file isEqualToString:@"NSToolTipHelpKey"])
        {
		IMP imp = [self.destination methodForSelector:setToolTip];
		void (*func)(id, SEL, id) = (void *)imp;
		func(self.destination, setToolTip, self.marker);
        }
	}

@end
