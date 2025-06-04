//
//  AZTableRowRecord.m
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import "AZTableRowRecord.h"

@implementation AZTableRowRecord

/*****************************************************************************\
|* Debugging
\*****************************************************************************/
- (NSString*) description;
	{
    return [NSString stringWithFormat: @"AZTableRowRecord: start %.2f height: %.2f",
		_start, _height];
	}

@end
