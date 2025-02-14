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
		_use 	= 1;
		}
	return self;
	}

- (instancetype) initWithPointer:(void *)ptr andHint:(NSString *)hint
	{
	if (self = [super init])
		{
		_ptr 	= ptr;
		_hint 	= hint ? hint : @"";
		_use 	= 1;
		}
	return self;
	}

- (instancetype) initWithPoint:(NSPoint)p
	{
	if (self = [super init])
		{
		_p 	= p;
		_hint 	= @"";
		_use 	= 1;
		}
	return self;
	}

- (instancetype) initWithPoint:(NSPoint)p andHint:(NSString *)hint
	{
	if (self = [super init])
		{
		_p 		= p;
		_hint 	= hint ? hint : @"";
		_use 	= 1;
		}
	return self;
	}

- (instancetype) initWithRect:(NSRect)r
	{
	if (self = [super init])
		{
		_rect = r;
		_hint = @"";
		_use 	= 1;
		}
	return self;
	}

- (instancetype) initWithRect:(NSRect)r andHint:(NSString *)hint
	{
	if (self = [super init])
		{
		_rect = r;
		_hint = hint ? hint : @"";
		_use 	= 1;
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

+ (AZObject *) objectWithPoint:(NSPoint)p
	{
	return [[AZObject alloc] initWithPoint:p];
	}

+ (AZObject *) objectWithPoint:(NSPoint)p andHint:(NSString *)hint
	{
	return [[AZObject alloc] initWithPoint:p andHint:hint];
	}

+ (AZObject *) objectWithRect:(NSRect)r
	{
	return [[AZObject alloc] initWithRect:r];
	}

+ (AZObject *) objectWithRect:(NSRect)r andHint:(NSString *)hint
	{
	return [[AZObject alloc] initWithRect:r andHint:hint];
	}

/*****************************************************************************\
|* ... implement a shallow copy, so we can act as keys in a dictionary
\*****************************************************************************/
- (nonnull id)copyWithZone:(nullable NSZone *)zone
	{
	AZObject *clone = [AZObject objectWithPointer:_ptr andHint:_hint];
	clone.rect 		= _rect;
	clone.p			= _p;
	return clone;
	}

@end
