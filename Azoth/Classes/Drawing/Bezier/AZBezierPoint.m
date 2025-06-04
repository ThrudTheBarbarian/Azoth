//
//  AZBezierPoint.m
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//  Based on git@github.com:aurimasg/cubic-bezier-offsetter.git
//

#import "AZBezierPoint.h"

@implementation AZBezierPoint

/*****************************************************************************\
|* Initialisation : Declare an empty point
\*****************************************************************************/
- (instancetype) init;
	{
	if (self = [super init])
		{
		_x = 0;
		_y = 0;
		}
	return self;
	}

+ (instancetype) point
	{
	return AZBezierPoint.new;
	}


/*****************************************************************************\
|* Initialisation : Declare a point at x=y
\*****************************************************************************/
- (instancetype) initAtXY:(double)value
	{
	if (self = [super init])
		{
		_x = value;
		_y = value;
		}
	return self;
	}

+ (instancetype) pointAtXY:(double)value
	{
	return [[AZBezierPoint alloc] initAtXY:value];
	}


/*****************************************************************************\
|* Initialisation : Declare a point at x,y
\*****************************************************************************/
- (instancetype) initAtX:(double)x y:(double)y
	{
	if (self = [super init])
		{
		_x = x;
		_y = y;
		}
	return self;
	}

+ (instancetype) pointAtX:(double)x y:(double)y
	{
	return  [[AZBezierPoint alloc] initAtX:x y:y];
	}


/*****************************************************************************\
|* Initialisation : Declare a point
\*****************************************************************************/
- (instancetype) initWith:(NSPoint)p
	{
	if (self = [super init])
		{
		_x = p.x;
		_y = p.y;
		}
	return self;
	}

+ (instancetype) point:(NSPoint)p;
	{
	return [[AZBezierPoint alloc] initWith:p];
	}


/*****************************************************************************\
|* Method to see whether a value is pretty much zero. Uses DBL_EPSILON
\*****************************************************************************/
+ (BOOL) isZero:(double)d
	{
	return SDL_fabs(d) < DBL_EPSILON;
	}

+ (BOOL) isZero:(double)d tolerance:(double)tolerance
	{
	return SDL_fabs(d) < tolerance;
	}


/*****************************************************************************\
|* Returns greater than zero if three given points are clockwise. Returns
|* less than zero if points are counter-clockwise. And returns zero if
| * points are collinear
\*****************************************************************************/
+ (double) turn:(AZBezierPoint *)p0
			and:(AZBezierPoint *)p1
			and:(AZBezierPoint *)p2
	{
	AZBezierPoint *c1 = [AZBezierPoint subtract:p0 from:p1];
	AZBezierPoint *c2 = [AZBezierPoint subtract:p0 from:p2];
	return [c1 cross:c2];
	}

/*****************************************************************************\
|* Determines orientation of triangle defined by three given points
\*****************************************************************************/
+ (TrianglePointOrientation) triangleOrientation:(AZBezierPoint *)p0
											 and:(AZBezierPoint *)p1
											 and:(AZBezierPoint *)p2
	{
	double turn = [AZBezierPoint turn:p0 and:p1 and:p2];
	if ([AZBezierPoint isZero:turn])
		return Collinear;
	else if (turn > 0.0)
		return Clockwise;
	return Anticlockwise;
	}

/*****************************************************************************\
|* Returns true if triangle defined by three given points is clockwise.
|* Returns false if triangle is counter-clockwise or if points are
|* collinear
\*****************************************************************************/
+ (BOOL) triangleClockwise:(AZBezierPoint *)p0
					   and:(AZBezierPoint *)p1
					   and:(AZBezierPoint *)p2
	{
	return [self triangleOrientation:p0 and:p1 and:p2] == Clockwise;
	}

/*****************************************************************************\
|* Add two points
\*****************************************************************************/
+ (AZBezierPoint *) add:(AZBezierPoint *)p1 to:(AZBezierPoint *)p2
	{
	AZBezierPoint *p = AZBezierPoint.new;
	p.x = p1.x + p2.x;
	p.y = p1.y + p2.y;
	return p;
	}

/*****************************************************************************\
|* Subtract one point from another
\*****************************************************************************/
+ (AZBezierPoint *) subtract:(AZBezierPoint *)p1 from:(AZBezierPoint *)p2
	{
	AZBezierPoint *p = AZBezierPoint.new;
	p.x = p2.x - p1.x;
	p.y = p2.y - p1.y;
	return p;
	}

/*****************************************************************************\
|* Scale a point
\*****************************************************************************/
+ (AZBezierPoint *) scale:(AZBezierPoint *)p1 by:(double)scale
	{
	AZBezierPoint *p = AZBezierPoint.new;
	p.x = p1.x * scale;
	p.y = p1.y * scale;
	return p;
	}

/*****************************************************************************\
|* Scale a point
\*****************************************************************************/
+ (AZBezierPoint *) multiply:(AZBezierPoint *)p1 by:(AZBezierPoint *)p2;
	{
	AZBezierPoint *p = AZBezierPoint.new;
	p.x = p1.x * p2.x;
	p.y = p1.y * p2.y;
	return p;
	}

/*****************************************************************************\
|* Divide a point by another
\*****************************************************************************/
+ (AZBezierPoint *) divide:(AZBezierPoint *)p1 by:(AZBezierPoint *)p2;
	{
	AZBezierPoint *p = AZBezierPoint.new;
	p.x = p1.x / p2.x;
	p.y = p1.y / p2.y;
	return p;
	}

/*****************************************************************************\
|* Negate a point
\*****************************************************************************/
+ (AZBezierPoint *) negate:(AZBezierPoint *)p1;
	{
	AZBezierPoint *p = AZBezierPoint.new;
	p.x = -p1.x;
	p.y = -p1.y;
	return p;
	}


/*****************************************************************************\
|* Returns an NSPoint representation
\*****************************************************************************/
- (NSPoint) asPoint
	{
	return NSMakePoint(_x, _y);
	}

/*****************************************************************************\
|* Returns whether a point is equal to another one, within a tolerance, if the
|* single-argument version is called, a tolerance of DBL_EPSILON is used
\*****************************************************************************/
- (BOOL) isEqual:(AZBezierPoint *)p
	{
	return [AZBezierPoint isZero:p.x - _x] && [AZBezierPoint isZero:p.y - _y];
	}

- (BOOL) isEqual:(AZBezierPoint *)p tolerance:(double)tolerance
	{
	return  [AZBezierPoint isZero:p.x - _x tolerance:tolerance] &&
			[AZBezierPoint isZero:p.y - _y tolerance:tolerance];
	}

/*****************************************************************************\
|* Returns distance from this point to another point
\*****************************************************************************/
- (double) distanceTo:(AZBezierPoint *)other
	{
	AZBezierPoint *p = [AZBezierPoint subtract:self from:other];
	return p.length;
	}

/*****************************************************************************\
|* Returns squared distance from this point to another point
\*****************************************************************************/
- (double) distanceToSquared:(AZBezierPoint *)other
	{
	AZBezierPoint *p = [AZBezierPoint subtract:self from:other];
	return p.lengthSquared;
	}

/*****************************************************************************\
|* Returns length of vector defined by X and Y components of this point
\*****************************************************************************/
- (double) length
	{
	return SDL_sqrt(self.lengthSquared);
	}

/*****************************************************************************\
|* Returns squared length of vector defined by X and Y components of this point
\*****************************************************************************/
- (double) lengthSquared
	{
	return (_x * _x) + (_y * _y);
	}

/*****************************************************************************\
|* Returns normalized version of this vector. If this vector has length of
|* zero, vector with both components set to zero will be returned
\*****************************************************************************/
- (AZBezierPoint *) unitVector
	{
	double mag2 = self.lengthSquared;
	if ((mag2 != 0.0) && (mag2 != 1.0))
		{
		double length = SDL_sqrt(mag2);
		return [AZBezierPoint pointAtX:_x/length y:_y/length];
		}
	return self;
	}

/*****************************************************************************\
|* Returns vector which has direction perpendicular to the direction of
|* this vector
\*****************************************************************************/
- (AZBezierPoint *) normalVector
	{
	return [AZBezierPoint pointAtX:_y y:-_x];
	}

/*****************************************************************************\
|* Returns vector which has direction perpendicular to the direction of
|* this vector, vector is normalised
\*****************************************************************************/
- (AZBezierPoint *) unitNormalVector
	{
	return self.normalVector.unitVector;
	}

/*****************************************************************************\
|* Returns cross product of two 2D vectors (this × point).
|*
|* Since both 2D vectors lie on the same XY plane, the only meaningful
|* return value is Z component of cross product. This method returns that
|* and does not calculate anything else.
\*****************************************************************************/
- (double) cross:(AZBezierPoint *)point
	{
	return (_x * point.y) - (_y * point.x);
	}

/*****************************************************************************\
|* Returns dot product of this vector and a given vector
\*****************************************************************************/
- (double) dot:(AZBezierPoint *)point
	{
	return (_x * point.x) - (_y * point.y);
	}


/*****************************************************************************\
|* Returns vector created by rotating this vector 90 degrees counter-clockwise
\*****************************************************************************/
- (AZBezierPoint *) rotated90CCW
	{
	return [AZBezierPoint pointAtX:_y y:-_x];
	}

/*****************************************************************************\
|* Add to this point
\*****************************************************************************/
- (AZBezierPoint *) add:(AZBezierPoint *)p1
	{
	_x += p1.x;
	_y += p1.y;
	return self;
	}

/*****************************************************************************\
|* Subtract a point from this one
\*****************************************************************************/
- (AZBezierPoint *) subtract:(AZBezierPoint *)p1
	{
	_x -= p1.x;
	_y -= p1.y;
	return self;
	}

/*****************************************************************************\
|* Scale this point
\*****************************************************************************/
- (AZBezierPoint *) scaleXY:(double)scale
	{
	_x *= scale;
	_y *= scale;
	return self;
	}

/*****************************************************************************\
|* Scale this point
\*****************************************************************************/
- (AZBezierPoint *) multiplyBy:(AZBezierPoint *)p1
	{
	_x *= p1.x;
	_y *= p1.y;
	return self;
	}


/*****************************************************************************\
|* Divide this point by another
\*****************************************************************************/
- (AZBezierPoint *) divideBy:(AZBezierPoint *)p
	{
	_x /= p.x;
	_y /= p.y;
	return self;
	}

/*****************************************************************************\
|* Negate this point
\*****************************************************************************/
- (AZBezierPoint *) negate
	{
	_x = - _x;
	_y = - _y;
	return self;
	}

/*****************************************************************************\
|* Linearly interpolate from this point to another, parametrically. Does not
|* change this point's values
\*****************************************************************************/
- (AZBezierPoint *) lerpTo:(AZBezierPoint *)other by:(double)t
	{
	t = SDL_clamp(t, 0.0, 1.0);

	double x = _x + ((other.x - _x) * t);
	double y = _y + ((other.y - _y) * t);
	return [AZBezierPoint pointAtX:x y:y];
	}

// MARK: NSCopying
/*****************************************************************************\
|* Copy this point by duplication
\*****************************************************************************/
- (nonnull id)copyWithZone:(nullable NSZone *)zone
	{
	AZBezierPoint *p 	= AZBezierPoint.new;
	p.x 				= _x;
	p.y 				= _y;
	return p;
	}

// MARK: Debugging
/*****************************************************************************\
|* Description of this object
\*****************************************************************************/
- (NSString *)description
	{
	return [NSString stringWithFormat:@"{%.2f, %.2f}", _x, _y];
	}


@end
