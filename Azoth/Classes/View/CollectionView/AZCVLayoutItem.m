//
//  AZCVLayoutItem.m
//  Azoth
//
//  Created by Simon Gornall on 1/7/25.
//

#import "AZCVLayoutItem.h"

@implementation AZCVLayoutItem

/*****************************************************************************\
|* Debugging
\*****************************************************************************/
- (NSString *)description
	{
	return [NSString stringWithFormat:@"Layout: item:%i @ row:%i col:%i",
			(int)_itemIndex, (int)_rowIndex, (int)_colIndex];
	}

@end
