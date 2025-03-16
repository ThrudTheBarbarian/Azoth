//
//  AZLine.m
//  Azoth
//
//  Created by Simon Gornall on 3/15/25.
//

#import "AZLine.h"
#import "AZPoint.h"


/*****************************************************************************\
|* Helper: convert radians to degrees
\*****************************************************************************/
static double _rad2Deg(const double x)
	{
    // 180 / pi.
    return x * 57.295779513082320876798154814105;
	}

@implementation AZLine

/*****************************************************************************\
|* Initialisation : Declare an empty line
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
		_p0 = AZPoint.new;
		_p1 = AZPoint.new;
		}
	return self;
	}

+ (instancetype) empty
	{
	return AZLine.new;
	}

/*****************************************************************************\
|* Initialisation : A line between two points
\*****************************************************************************/
- (instancetype) initFrom:(AZPoint *)p1 to:(AZPoint *)p2
	{
	if (self = [super init])
		{
		_p0 = [AZPoint pointAtX:p1.x y:p1.y];
		_p1 = [AZPoint pointAtX:p2.x y:p2.y];
		}
	return self;
	}

+ (instancetype) lineFrom:(AZPoint *)p1 to:(AZPoint *)p2
	{
	return [[AZLine alloc] initFrom:p1 to:p2];
	}

- (instancetype) initFromX:(double)x0 y:(double)y0 toX:(double)x1 y:(double)y1
	{
	if (self = [super init])
		{
		_p0 = [AZPoint pointAtX:x0 y:y0];
		_p1 = [AZPoint pointAtX:x1 y:y1];
		}
	return self;
	}

+ (instancetype) lineFromX:(double)x0 y:(double)y0 toX:(double)x1 y:(double)y1
	{
	return [[AZLine alloc] initFromX:x0 y:y0 toX:x1 y:y1];
	}

- (instancetype) initFrom:(AZPoint *)p toX:(double)x1 y:(double)y1
	{
	if (self = [super init])
		{
		_p0 = [AZPoint pointAtX:p.x y:p.y];
		_p1 = [AZPoint pointAtX:x1 y:y1];
		}
	return self;
	}

+ (instancetype) lineFrom:(AZPoint *)p toX:(double)x1 y:(double)y1
	{
	return [[AZLine alloc] initFrom:p toX:x1 y:y1];
	}

- (instancetype) initFromX:(double)x0 y:(double)y0 to:(AZPoint *)p
	{
	if (self = [super init])
		{
		_p0 = [AZPoint pointAtX:x0 y:y0];
		_p1 = [AZPoint pointAtX:p.x y:p.y];
		}
	return self;
	}

+ (instancetype) lineFromX:(double)x0 y:(double)y0 to:(AZPoint *)p
	{
	return [[AZLine alloc] initFromX:x0 y:y0 to:p];
	}


// MARK: Property methods

/*****************************************************************************\
|* x, y of the first point
\*****************************************************************************/
- (double) x0
	{
	return _p0.x;
	}

- (double) y0
	{
	return _p0.y;
	}

/*****************************************************************************\
|* x, y of the second point
\*****************************************************************************/
- (double) x1
	{
	return _p1.x;
	}

- (double) y1
	{
	return _p1.y;
	}

/*****************************************************************************\
|* change in x over the line
\*****************************************************************************/
- (double) dx
	{
	return _p1.x - _p0.x;
	}

/*****************************************************************************\
|* change in y over the line
\*****************************************************************************/
- (double) dy
	{
	return _p1.y - _p0.y;
	}

/*****************************************************************************\
|* Is the line really a point ?
\*****************************************************************************/
- (BOOL) isPoint
	{
	return  [AZPoint isZero:_p0.x - _p1.x] &&
			[AZPoint isZero:_p0.y - _p1.y];
	}




// MARK: Public methods

/*****************************************************************************\
|* Return the reversed line
\*****************************************************************************/
- (AZLine *) reversed;
	{
	return [AZLine lineFrom:_p1 to:_p0];
	}

/*****************************************************************************\
|* Return the unit vector for the line
\*****************************************************************************/
- (AZPoint *) unitVector
	{
	AZPoint *p = [AZPoint subtract:_p0 from:_p1];
	return p.unitVector;
	}

/*****************************************************************************\
|* Return the normal vector for the line
\*****************************************************************************/
- (AZPoint *) normalVector
	{
	return [AZPoint pointAtX:[self dy] y:-[self dx]];
	}

/*****************************************************************************\
|* Return the unit normal vector for the line
\*****************************************************************************/
- (AZPoint *) unitNormalVector
	{
	return self.normalVector.unitVector;
	}

/*****************************************************************************\
|* Return this line translated by a {dx,dy} step
\*****************************************************************************/
- (AZLine *) translated:(AZPoint *)p
	{
	AZPoint *P0 = [AZPoint add:_p0 to:p];
	AZPoint *P1 = [AZPoint add:_p1 to:p];
	return [AZLine lineFrom:P0 to:P1];
	}

/*****************************************************************************\
|* Return the midpoint of the line
\*****************************************************************************/
- (AZPoint *) midpoint
	{
	return [AZPoint pointAtX:(_p0.x + _p1.x) * 0.5 y:(_p0.y + _p1.y) * 0.5];
	}

/*****************************************************************************\
|* Is the line really a point within a tolerance ?
\*****************************************************************************/
- (BOOL) isPointWithTolerance:(double)tolerance;
	{
	return  [AZPoint isZero:_p0.x - _p1.x tolerance:tolerance] &&
			[AZPoint isZero:_p0.y - _p1.y tolerance:tolerance];
	}


/*****************************************************************************\
|* Get the angle (in degrees) between this line and another
\*****************************************************************************/
- (double) degreesToLine:(AZLine *)l;
	{
	return _rad2Deg([self radiansToLine:l]);
	}

/*****************************************************************************\
|* Get the angle (in radians) between this line and another
\*****************************************************************************/
- (double) radiansToLine:(AZLine *)l;
	{
    // FLT_EPSILON instead of DBL_EPSILON is used deliberately.
    static double kMinRange = -1.0 - FLT_EPSILON;
    static double kMaxRange =  1.0 + FLT_EPSILON;

	if (self.isPoint || l.isPoint)
		return 0.0;

	double c = (self.dx * l.dx + self.dy * l.dy) / (self.length * l.length);

    // Return 0 instead of PI if c is outside range.
    if ((c >= kMinRange) && (c <= kMaxRange))
		return SDL_acos(SDL_clamp(c, -1.0, 1.0));

    return 0.0;
    }

/*****************************************************************************\
|* Get the length of the line
\*****************************************************************************/
- (double) length
	{
    const double x = _p1.x - _p0.x;
    const double y = _p1.y - _p0.y;

    return SDL_sqrt(x * x  +  y * y);
	}

/*****************************************************************************\
|* Get the squared length of the line
\*****************************************************************************/
- (double) lengthSquared
	{
    const double x = _p1.x - _p0.x;
    const double y = _p1.y - _p0.y;

    return x * x  +  y * y;
	}

/*****************************************************************************\
|* Get the angle of the line
\*****************************************************************************/
- (double) angle
	{
    const double dx 			 = _p1.x - _p0.x;
    const double dy 			 = _p1.y - _p0.y;
	const double theta 			 = _rad2Deg(SDL_atan2(-dy, dx));
    const double thetaNormalized = theta < 0 ? theta + 360 : theta;

	if ([AZPoint isZero:thetaNormalized-360.0])
        return 0;

	// In case we have -0, return positive zero.
	if ([AZPoint isZero:thetaNormalized])
        return 0;

    return thetaNormalized;
	}

/*****************************************************************************\
|* Get the intersection of this line with another
\*****************************************************************************/
- (LineIntersection) intersect:(AZLine *)l
	{
	AZPoint *a 					= [AZPoint subtract:_p0 from:_p1];
	AZPoint *b 					= [AZPoint subtract:l.p0 from:l.p1];
    const double denominator 	= a.y * b.x - a.x * b.y;

    if (denominator == 0)
        return (LineIntersection){None, nil};

	AZPoint *c 					= [AZPoint subtract:l.p0 from:_p0];
    const double reciprocal 	= 1.0 / denominator;
    const double na 			= (b.y * c.x - b.x * c.y) * reciprocal;

	AZPoint *point 				= [AZPoint scale:[AZPoint add:_p0 to:a] by:na];
    if ((na < 0) || (na > 1))
        return (LineIntersection){Unbounded, point};


    const double nb = (a.x * c.y - a.y * c.x) * reciprocal;

    if ((nb < 0) || (nb > 1))
        return (LineIntersection){Unbounded, point};

	return (LineIntersection){Bounded, point};
	}

/*****************************************************************************\
|* Get the simple intersection of this line with another
\*****************************************************************************/
- (LineIntersectionSimple) intersectSimple:(AZLine *)l
	{
	AZPoint *a 					= [AZPoint subtract:_p0 from:_p1];
	AZPoint *b 					= [AZPoint subtract:l.p0 from:l.p1];
    const double denominator 	= a.y * b.x - a.x * b.y;

    if (denominator == 0)
		return (LineIntersectionSimple){NO, nil};

	AZPoint *c 					= [AZPoint subtract:l.p0 from:_p0];
    const double reciprocal 	= 1.0 / denominator;
    const double na 			= (b.y * c.x - b.x * c.y) * reciprocal;

	AZPoint *point 				= [AZPoint scale:[AZPoint add:_p0 to:a] by:na];
	return (LineIntersectionSimple){YES, point};
	}

/*****************************************************************************\
|* Extend a line by an amount, on the front side
\*****************************************************************************/
- (void) extendFrontBy:(double)length
	{
	if ((self.isPoint) || ([AZPoint isZero:self.length]))
		return;

	AZPoint *v = self.unitVector;
	_p1 = [AZPoint pointAtX:_p1.x + v.x * length
						  y:_p1.y + v.y * length];
	}

/*****************************************************************************\
|* Extend a line by an amount, at the back
\*****************************************************************************/
- (void) extendBackBy:(double)length
	{
	if ((self.isPoint) || ([AZPoint isZero:self.length]))
		return;

	AZPoint *v = self.unitVector;
	_p0 = [AZPoint pointAtX:_p1.x - v.x * length
						  y:_p1.y - v.y * length];
	}

/*****************************************************************************\
|* Is the point on the line segment
\*****************************************************************************/
- (BOOL) isPoint:(AZPoint *)p onLineSegmentWithTolerance:(double)epsilon
	{
    const double cross = (p.y - _p0.y) * (_p1.x - _p0.x)
					   - (p.x - _p0.x) * (_p1.y - _p0.y);
	if (SDL_fabs(cross) > epsilon)
        return NO;


    const double dot = (p.x - _p0.x) * (_p1.x - _p0.x)
					 + (p.x - _p0.y) * (_p1.y - _p0.y);
    if (dot < 0)
        return NO;

    const double sql = (_p1.x - _p0.x) * (_p1.x - _p0.x)
					 + (_p1.y - _p0.y) * (_p1.y - _p0.y);
    return dot <= sql;
	}

/*****************************************************************************\
|* Is the point on the line
\*****************************************************************************/
- (BOOL) isPoint:(AZPoint *)p onLineWithTolerance:(double)epsilon
	{
    const double cross = (p.y - _p0.y) * (_p1.x - _p0.x)
					   - (p.x - _p0.x) * (_p1.y - _p0.y);

	return SDL_fabs(cross) < epsilon;
	}


@end
