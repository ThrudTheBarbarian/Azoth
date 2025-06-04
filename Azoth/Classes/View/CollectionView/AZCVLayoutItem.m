//
//  AZCVLayoutItem.m
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
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
