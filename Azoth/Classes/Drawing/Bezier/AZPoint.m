//
//  AZPoint.m
//  Azoth
//
//  Created by Simon Gornall on 3/15/25.
//

#import "AZPoint.h"

@implementation AZPoint

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
	return AZPoint.new;
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
	return [[AZPoint alloc] initAtXY:value];
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
	return  [[AZPoint alloc] initAtX:x y:y];
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
	return [[AZPoint alloc] initWith:p];
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
+ (double) turn:(AZPoint *)p0 and:(AZPoint *)p1 and:(AZPoint *)p2
	{
	AZPoint *c1 = [AZPoint subtract:p0 from:p1];
	AZPoint *c2 = [AZPoint subtract:p0 from:p2];
	return [c1 cross:c2];
	}

/*****************************************************************************\
|* Determines orientation of triangle defined by three given points
\*****************************************************************************/
+ (TrianglePointOrientation) triangleOrientation:(AZPoint *)p0
											 and:(AZPoint *)p1
											 and:(AZPoint *)p2
	{
	double turn = [AZPoint turn:p0 and:p1 and:p2];
	if ([AZPoint isZero:turn])
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
+ (BOOL) triangleClockwise:(AZPoint *)p0 and:(AZPoint *)p1 and:(AZPoint *)p2
	{
	return [self triangleOrientation:p0 and:p1 and:p2] == Clockwise;
	}

/*****************************************************************************\
|* Add two points
\*****************************************************************************/
+ (AZPoint *) add:(AZPoint *)p1 to:(AZPoint *)p2
	{
	AZPoint *p = AZPoint.new;
	p.x = p1.x + p2.x;
	p.y = p1.y + p2.y;
	return p;
	}

/*****************************************************************************\
|* Subtract one point from another
\*****************************************************************************/
+ (AZPoint *) subtract:(AZPoint *)p1 from:(AZPoint *)p2
	{
	AZPoint *p = AZPoint.new;
	p.x = p2.x - p1.x;
	p.y = p2.y - p1.y;
	return p;
	}

/*****************************************************************************\
|* Scale a point
\*****************************************************************************/
+ (AZPoint *) scale:(AZPoint *)p1 by:(double)scale
	{
	AZPoint *p = AZPoint.new;
	p.x = p1.x * scale;
	p.y = p1.y * scale;
	return p;
	}

/*****************************************************************************\
|* Scale a point
\*****************************************************************************/
+ (AZPoint *) multiply:(AZPoint *)p1 by:(AZPoint *)p2;
	{
	AZPoint *p = AZPoint.new;
	p.x = p1.x * p2.x;
	p.y = p1.y * p2.y;
	return p;
	}

/*****************************************************************************\
|* Divide a point by another
\*****************************************************************************/
+ (AZPoint *) divide:(AZPoint *)p1 by:(AZPoint *)p2;
	{
	AZPoint *p = AZPoint.new;
	p.x = p1.x / p2.x;
	p.y = p1.y / p2.y;
	return p;
	}

/*****************************************************************************\
|* Negate a point
\*****************************************************************************/
+ (AZPoint *) negate:(AZPoint *)p1;
	{
	AZPoint *p = AZPoint.new;
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
- (BOOL) isEqual:(AZPoint *)p
	{
	return [AZPoint isZero:p.x - _x] && [AZPoint isZero:p.y - _y];
	}

- (BOOL) isEqual:(AZPoint *)p tolerance:(double)tolerance
	{
	return  [AZPoint isZero:p.x - _x tolerance:tolerance] &&
			[AZPoint isZero:p.y - _y tolerance:tolerance];
	}

/*****************************************************************************\
|* Returns distance from this point to another point
\*****************************************************************************/
- (double) distanceTo:(AZPoint *)other
	{
	AZPoint *p = [AZPoint subtract:self from:other];
	return p.length;
	}

/*****************************************************************************\
|* Returns squared distance from this point to another point
\*****************************************************************************/
- (double) distanceToSquared:(AZPoint *)other
	{
	AZPoint *p = [AZPoint subtract:self from:other];
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
- (AZPoint *) unitVector
	{
	double mag2 = self.lengthSquared;
	if ((mag2 != 0.0) && (mag2 != 1.0))
		{
		double length = SDL_sqrt(mag2);
		return [AZPoint pointAtX:_x/length y:_y/length];
		}
	return self;
	}

/*****************************************************************************\
|* Returns vector which has direction perpendicular to the direction of
|* this vector
\*****************************************************************************/
- (AZPoint *) normalVector
	{
	return [AZPoint pointAtX:_y y:-_x];
	}

/*****************************************************************************\
|* Returns vector which has direction perpendicular to the direction of
|* this vector, vector is normalised
\*****************************************************************************/
- (AZPoint *) unitNormalVector
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
- (double) cross:(AZPoint *)point
	{
	return (_x * point.y) - (_y * point.x);
	}

/*****************************************************************************\
|* Returns dot product of this vector and a given vector
\*****************************************************************************/
- (double) dot:(AZPoint *)point
	{
	return (_x * point.x) - (_y * point.y);
	}


/*****************************************************************************\
|* Returns vector created by rotating this vector 90 degrees counter-clockwise
\*****************************************************************************/
- (AZPoint *) rotated90CCW
	{
	return [AZPoint pointAtX:_y y:-_x];
	}

/*****************************************************************************\
|* Add to this point
\*****************************************************************************/
- (void) add:(AZPoint *)p1
	{
	_x += p1.x;
	_y += p1.y;
	}

/*****************************************************************************\
|* Subtract a point from this one
\*****************************************************************************/
- (void) subtract:(AZPoint *)p1
	{
	_x -= p1.x;
	_y -= p1.y;
	}

/*****************************************************************************\
|* Scale this point
\*****************************************************************************/
- (void) scaleBy:(double)scale
	{
	_x *= scale;
	_y *= scale;
	}

/*****************************************************************************\
|* Scale this point
\*****************************************************************************/
- (void) multiplyBy:(AZPoint *)p1
	{
	_x *= p1.x;
	_y *= p1.y;
	}


/*****************************************************************************\
|* Divide this point by another
\*****************************************************************************/
- (void) divideBy:(AZPoint *)p
	{
	_x /= p.x;
	_y /= p.y;
	}

/*****************************************************************************\
|* Negate this point
\*****************************************************************************/
- (void) negate
	{
	_x = - _x;
	_y = - _y;
	}

/*****************************************************************************\
|* Linearly interpolate from this point to another, parametrically. Does not
|* change this point's values
\*****************************************************************************/
- (AZPoint *) lerpTo:(AZPoint *)other by:(double)t
	{
	t = SDL_clamp(t, 0.0, 1.0);

	double x = _x + ((other.x - _x) * t);
	double y = _y + ((other.y - _y) * t);
	return [AZPoint pointAtX:x y:y];
	}

@end
