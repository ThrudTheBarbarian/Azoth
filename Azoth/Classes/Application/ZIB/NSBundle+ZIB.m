//
//  NSBundle+ZIB.m
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <SDL3/SDL.h>

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
- (BOOL)loadZibNamed:(NSString *)zibName
               owner:(id)owner
	 topLevelObjects:(nullable NSMutableArray *)topLevelObjects
	{
	BOOL ok			= NO;
	NSString *path	= [self pathForResource:zibName ofType:@"zib"];
	if (path == nil)
		SDL_Log("NSBundle unable to find zib named %s, bundle=%s",
				zibName.UTF8String, self.description.UTF8String);
	else
		{
		AZZib *zib 	= [AZZib zibWithFile:path];
		ok 			= [zib inflateWithOwner:owner into:topLevelObjects];
		}

	return ok;
	}

@end
