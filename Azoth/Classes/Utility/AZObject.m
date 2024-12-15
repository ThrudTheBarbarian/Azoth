//
//  AZObject.m
//  Azoth
//
//  Created by Simon Gornall on 12/13/24.
//

#import "AZObject.h"

@implementation AZObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithPointer:(void *)ptr
	{
	if (self = [super init])
		{
		_ptr 	= ptr;
		_hint 	= @"";
		}
	return self;
	}

- (instancetype) initWithPointer:(void *)ptr andHint:(NSString *)hint
	{
	if (self = [super init])
		{
		_ptr 	= ptr;
		_hint 	= hint ? hint : @"";
		}
	return self;
	}

/*****************************************************************************\
|* ... conveniently
\*****************************************************************************/
+ (AZObject *) objectWithPointer:(void *)ptr
	{
	return [[AZObject alloc] initWithPointer:ptr];
	}

+ (AZObject *) objectWithPointer:(void *)ptr andHint:(NSString *)hint
	{
	return [[AZObject alloc] initWithPointer:ptr andHint:hint];
	}

@end
