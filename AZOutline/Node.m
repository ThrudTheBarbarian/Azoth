//
//  Node.m
//  AZOutline
//
//  Created by Simon Gornall on 12/31/24.
//

#import "Node.h"

@implementation Node

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithName:(NSString *)name
	{
	if (self = [super init])
		{
		_name = name;
		_kids = [NSMutableArray new];
		}
	return self;
	}

+ (Node *) nodeWithName:(NSString *)name
	{
	return [[Node alloc] initWithName:name];
	}

- (BOOL) hasKids
	{
	return _kids.count > 0;
	}

@end
