//
//  AZControl.m
//  Azoth
//
//  Created by Simon Gornall on 12/15/24.
//

#import "AZControl.h"

@implementation AZControl

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super initWithFrame:frame])
		{
		self.stringValue 	= @"";
		self.state		 	= ControlStateNormal;
		}
	return self;
	}

@end
