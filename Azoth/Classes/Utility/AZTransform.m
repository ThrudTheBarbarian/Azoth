//
//  AZTransform.m
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <SDL3/SDL.h>

#import "AZTransform.h"

@implementation AZTransform
/*****************************************************************************\
|* Basic init, create an identity matrix
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
		_a 	= 1.f;
		_b 	= 0.f;
		_c 	= 0.f;
		_d 	= 1.f;
		_tx	= 0.f;
		_ty = 0.f;
		}
	return self;
	}
	
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithA:(float)a
						 b:(float)b
						 c:(float)c
						 d:(float)d
					    tx:(float)tx
					    ty:(float)ty
	{
	if (self = [super init])
		{
		_a 	= a;
		_b 	= b;
		_c 	= c;
		_d 	= d;
		_tx	= tx;
		_ty = ty;
		}
	return self;
	}

/*****************************************************************************\
|* Conveniently...
\*****************************************************************************/
+ (AZTransform *) transformWithA:(float)a
							   b:(float)b
							   c:(float)c
							   d:(float)d
							   tx:(float)tx
							   ty:(float)ty
	{
	return [[AZTransform alloc] initWithA:a b:b c:c d:d tx:tx ty:ty];
	}

/*****************************************************************************\
|* Or as an identity - this is the default initialisation state
\*****************************************************************************/
+ (AZTransform *) identity
	{
	return [AZTransform new];
	}

/*****************************************************************************\
|* Or as a rotation transform
\*****************************************************************************/
+ (AZTransform *) rotation:(float)radians
	{
	return [[AZTransform alloc] initWithA:SDL_cos(radians)
									   b:SDL_sin(radians)
									   c:-SDL_sin(radians)
									   d:SDL_cos(radians)
									   tx:0.f
									   ty:0.f];
	}

/*****************************************************************************\
|* Or as a scaling transform
\*****************************************************************************/
+ (AZTransform *) scaleX:(float)sx y:(float)sy
	{
	return [[AZTransform alloc] initWithA:sx b:0.f c:0.f d:sy tx:0.f ty:0.f];
	}

/*****************************************************************************\
|* Or as a translation transform
\*****************************************************************************/
+ (AZTransform *) translateX:(float)tx y:(float)ty
	{
	return [[AZTransform alloc] initWithA:1.f b:0.f c:0.f d:1.f tx:tx ty:ty];
	}

/*****************************************************************************\
|* Determine if this is an identity matrix
\*****************************************************************************/
- (BOOL) isIdentity
	{
	if ((_a == 1.f) && (_d == 1.f) && (_b == 0.f) && (_c == 0.f))
		if ((_tx == 0.f) && (_ty == 0.f))
			return YES;
	return NO;
	}

/*****************************************************************************\
|* Operation: append a transform onto this one
\*****************************************************************************/
- (AZTransform *) concat:(AZTransform *)other
	{
	AZTransform *result = [AZTransform new];

	result.a 	= _a * other.a + _b * other.c;
	result.b 	= _a * other.b + _b * other.d;
	result.c 	= _c * other.a + _d * other.c;
	result.d 	= _c * other.b + _d * other.d;
	result.tx	= _tx * other.a + _ty * other.c + other.tx;
	result.ty	= _tx * other.b + _ty * other.d + other.ty;

	return result;
	}

/*****************************************************************************\
|* Operation: return the result of inverting this transform
\*****************************************************************************/
- (AZTransform *) invert
	{
   	AZTransform *result = [AZTransform new];;

   	float determinant = _a * _d - _c * _b;
	if (determinant == 0.f)
		return self;

	result.a	= _d / determinant;
	result.b	= -_b / determinant;
	result.c	= -_c / determinant;
	result.d	= _a / determinant;
	result.tx	= (-_d * _tx + _c * _ty) / determinant;
	result.ty	= ( _b * _tx - _a * _ty) / determinant;

	return result;
	}

/*****************************************************************************\
|* Operation: return a rotation of this transform
\*****************************************************************************/
- (AZTransform *) rotate:(float)radians
	{
	AZTransform *T = [AZTransform rotation:radians];
	return [self concat:T];
	}

/*****************************************************************************\
|* Operation: return a scale of this transform
\*****************************************************************************/
- (AZTransform *) scaleX:(float)sx y:(float)sy
	{
	AZTransform *T = [AZTransform scaleX:sx y:sy];
	return [self concat:T];
	}

/*****************************************************************************\
|* Operation: return a translation of this transform
\*****************************************************************************/
- (AZTransform *) translateX:(float)tx y:(float)ty;
	{
	AZTransform *T = [AZTransform translateX:tx y:ty];
	return [self concat:T];
	}

/*****************************************************************************\
|* Operation: transform a point
\*****************************************************************************/
- (NSPoint) applyToPoint:(NSPoint)pt
	{
	NSPoint p;

    p.x = _a * pt.x + _c * pt.y + _tx;
    p.y = _b * pt.x + _d * pt.y + _ty;

    return p;
	}

/*****************************************************************************\
|* Operation: transform a size
\*****************************************************************************/
- (NSSize) applyToSize:(NSSize)size
	{
	NSSize s;

    s.width = _a * size.width + _c * size.height;
    s.height= _b * size.width + _d * size.height;

	return s;
	}

/*****************************************************************************\
|* Debugging
\*****************************************************************************/
- (NSString *)description
	{
	return [NSString stringWithFormat:@"Transform: "
				"{%.2f, %.2f, %.2f, %.2f} "
				"{%.2f, %.2f}",
				_a, _b, _c, _d, _tx, _ty];
	}
@end
