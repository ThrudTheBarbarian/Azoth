//
//  NSBundle+ZIB.m
//  Azoth
//
//  Created by Simon Gornall on 1/3/25.
//

#import "AZZib.h"
#import "NSBundle+ZIB.h"

AZZibOptionsKey const AZZibExternalObjects = @"AZ:ExternalObjects";

@implementation NSBundle (ZIB)

/*****************************************************************************\
|* Load a named ZIB, assigning ownership of the 'owner' field to the passed
|* object, with a class check, and accepting options to replace the placeholder
|* objects with real concrete ones.
|*
|* Returns an array to the top-level objects in the ZIB, not including the
|* owner or any replaced-placeholder objects.
\*****************************************************************************/
- (NSArray *)loadNibNamed:(NSString *)name
                    owner:(NSObject *)owner 
                  options:(NSDictionary<AZZibOptionsKey, id> *)options
	{
	NSArray *results = [NSArray array];

	AZZib *zib = [AZZib zibWithFile:name];
	[zib inflateWithOwner:owner andOptions:options];

	return results;
	}

@end
