//
//  AZCustomResource.m
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import <SDL3/SDL.h>

#import "AZClassSwapper.h"
#import "AZCustomResource.h"
#import "AZImage.h"

@implementation AZCustomResource

/*****************************************************************************\
|* Create the instance using a coder
\*****************************************************************************/
- (instancetype) initWithCoder:(NSCoder *)coder
	{
	if (coder.allowsKeyedCoding)
		{
		NSKeyedUnarchiver *keyed = (NSKeyedUnarchiver *)coder;
    
		NSString *name	= [keyed decodeObjectForKey:@"NSClassName"];
		_className		= [AZClassSwapper toAZ:name];
		_resourceName	= [keyed decodeObjectForKey:@"NSResourceName"];
		}
   else
		[NSException raise:NSInvalidArgumentException
					format:@"-[%@ %@] can not decode from a %@",
					self.class.description,
					NSStringFromSelector(_cmd),
					[coder class]];

	return self;
	}

/*****************************************************************************\
|* Configuration...
\*****************************************************************************/
-awakeAfterUsingCoder:(NSCoder *)coder
	{
	if ([_className isEqualToString:@"AZImage"])
		{
		AZImage *image = [AZImage imageNamed:_resourceName];

		if ([_resourceName hasSuffix:@"Template"])
			[image setIsTemplate:YES];

		if (image != nil)
			return image;
		}

	SDL_Log("Could not find image named '%s'", _resourceName.UTF8String);
	return [AZImage imageWithSize:NSMakeSize(1,1)];
	}

@end
