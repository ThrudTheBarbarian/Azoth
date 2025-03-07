//
//  AZCVGroup.m
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/7/25.
//

#import "AZCVGroup.h"

@implementation AZCVGroup

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
+ (instancetype) groupWithTitle:(NSString *)title range:(NSRange)range
	{
	AZCVGroup *group = AZCVGroup.new;
	group.title = title;
	group.itemRange = range;
	return group;
	}

/*****************************************************************************\
|* Debugging
\*****************************************************************************/
- (NSString *)description
	{
	return [NSString stringWithFormat:@"Group: %@ %@",
			_title, NSStringFromRange(_itemRange)];
	}

@end
