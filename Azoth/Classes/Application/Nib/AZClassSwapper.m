//
//  AZClassSwapper.m
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import "AZClassSwapper.h"

@implementation AZClassSwapper

/*****************************************************************************\
|* The simplest way to do the replacement accurately
\*****************************************************************************/
+ allocWithKeyedUnarchiver:(NSKeyedUnarchiver *)keyed
	{
	NSString *className = [keyed decodeObjectForKey:@"NSClassName"];
	Class class			= NSClassFromString([self toAZ:className]);

	if (class == Nil)
		[NSException raise:NSInvalidArgumentException
					format:@"Unable to find class %@", className];

	return [class alloc];
	}

/*****************************************************************************\
|* Change the namespace
\*****************************************************************************/
+ (NSString *) toAZ:(NSString *)name
	{
	if ([name hasPrefix:@"NS"])
		name = [NSString stringWithFormat:@"AZ%@", [name substringFromIndex:2]];
	return name;
	}

@end
