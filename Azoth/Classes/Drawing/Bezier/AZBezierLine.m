//
//  AZBezierLine.m
//  Azoth
//
//  Created by Simon Gornall on 3/15/25.
//  Based on git@github.com:aurimasg/cubic-bezier-offsetter.git
//

#import "AZBezierLine.h"
#import "AZBezierPoint.h"


/*****************************************************************************\
|* Helper: convert radians to degrees
\*****************************************************************************/
static double _rad2Deg(const double x)
	{
    // 180 / pi.
    return x * 57.295779513082320876798154814105;
	}

@implementation AZBezierLine

/*****************************************************************************\
|* Initialisation : Declare an empty line
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
		_p0 = AZBezierPoint.new;
		_p1 = AZBezierPoint.new;
		}
	return self;
	}

+ (instancetype) empty
	{
	return AZBezierLine.new;
	}

/*****************************************************************************\
|* Initialisation : A line between two points
\*****************************************************************************/
- (instancetype) initFrom:(AZBezierPoint *)p1 to:(AZBezierPoint *)p2
	{
	if (self = [super init])
		{
		_p0 = [AZBezierPoint pointAtX:p1.x y:p1.y];
		_p1 = [AZBezierPoint pointAtX:p2.x y:p2.y];
		}
	return self;
	}

+ (instancetype) lineFrom:(AZBezierPoint *)p1 to:(AZBezierPoint *)p2
	{
	return [[AZBezierLine alloc] initFrom:p1 to:p2];
	}

- (instancetype) initFromX:(double)x0 y:(double)y0 toX:(double)x1 y:(double)y1
	{
	if (self = [super init])
		{
		_p0 = [AZBezierPoint pointAtX:x0 y:y0];
		_p1 = [AZBezierPoint pointAtX:x1 y:y1];
		}
	return self;
	}

+ (instancetype) lineFromX:(double)x0 y:(double)y0 toX:(double)x1 y:(double)y1
	{
	return [[AZBezierLine alloc] initFromX:x0 y:y0 toX:x1 y:y1];
	}

- (instancetype) initFrom:(AZBezierPoint *)p toX:(double)x1 y:(double)y1
	{
	if (self = [super init])
		{
		_p0 = [AZBezierPoint pointAtX:p.x y:p.y];
		_p1 = [AZBezierPoint pointAtX:x1 y:y1];
		}
	return self;
	}

+ (instancetype) lineFrom:(AZBezierPoint *)p toX:(double)x1 y:(double)y1
	{
	return [[AZBezierLine alloc] initFrom:p toX:x1 y:y1];
	}

- (instancetype) initFromX:(double)x0 y:(double)y0 to:(AZBezierPoint *)p
	{
	if (self = [super init])
		{
		_p0 = [AZBezierPoint pointAtX:x0 y:y0];
		_p1 = [AZBezierPoint pointAtX:p.x y:p.y];
		}
	return self;
	}

+ (instancetype) lineFromX:(double)x0 y:(double)y0 to:(AZBezierPoint *)p
	{
	return [[AZBezierLine alloc] initFromX:x0 y:y0 to:p];
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
	return FUZZY_EQUAL(_p0.x, _p1.x) && FUZZY_EQUAL(_p0.y, _p1.y);
	}




// MARK: Public methods

/*****************************************************************************\
|* Return the reversed line
\*****************************************************************************/
- (AZBezierLine *) reversed;
	{
	return [AZBezierLine lineFrom:_p1 to:_p0];
	}

/*****************************************************************************\
|* Return the unit vector for the line
\*****************************************************************************/
- (AZBezierPoint *) unitVector
	{
	AZBezierPoint *p = [AZBezierPoint subtract:_p0 from:_p1];
	return p.unitVector;
	}

/*****************************************************************************\
|* Return the normal vector for the line
\*****************************************************************************/
- (AZBezierPoint *) normalVector
	{
	return [AZBezierPoint pointAtX:[self dy] y:-[self dx]];
	}

/*****************************************************************************\
|* Return the unit normal vector for the line
\*****************************************************************************/
- (AZBezierPoint *) unitNormalVector
	{
	return self.normalVector.unitVector;
	}

/*****************************************************************************\
|* Return this line translated by a {dx,dy} step
\*****************************************************************************/
- (AZBezierLine *) translated:(AZBezierPoint *)p
	{
	AZBezierPoint *P0 = [AZBezierPoint add:_p0 to:p];
	AZBezierPoint *P1 = [AZBezierPoint add:_p1 to:p];
	return [AZBezierLine lineFrom:P0 to:P1];
	}

/*****************************************************************************\
|* Return the midpoint of the line
\*****************************************************************************/
- (AZBezierPoint *) midpoint
	{
	return [AZBezierPoint pointAtX:(_p0.x + _p1.x) * 0.5
								 y:(_p0.y + _p1.y) * 0.5];
	}

/*****************************************************************************\
|* Is the line really a point within a tolerance ?
\*****************************************************************************/
- (BOOL) isPointWithTolerance:(double)tolerance;
	{
	return  FUZZY_EQUAL_WITH(_p0.x, _p1.x, tolerance) &&
			FUZZY_EQUAL_WITH(_p0.y, _p1.y, tolerance);
	}


/*****************************************************************************\
|* Get the angle (in degrees) between this line and another
\*****************************************************************************/
- (double) degreesToLine:(AZBezierLine *)l;
	{
	return _rad2Deg([self radiansToLine:l]);
	}

/*****************************************************************************\
|* Get the angle (in radians) between this line and another
\*****************************************************************************/
- (double) radiansToLine:(AZBezierLine *)l;
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

	if (FUZZY_EQUAL(thetaNormalized,360.0))
        return 0;

	// In case we have -0, return positive zero.
	if (FUZZY_ZERO(thetaNormalized))
        return 0;

    return thetaNormalized;
	}

/*****************************************************************************\
|* Get the intersection of this line with another
\*****************************************************************************/
- (LineIntersection) intersect:(AZBezierLine *)l
	{
	AZBezierPoint *a 			= [AZBezierPoint subtract:_p0 from:_p1];
	AZBezierPoint *b 			= [AZBezierPoint subtract:l.p0 from:l.p1];
    const double denominator 	= a.y * b.x - a.x * b.y;

    if (denominator == 0)
        return (LineIntersection){None, nil};

	AZBezierPoint *c 			= [AZBezierPoint subtract:l.p0 from:_p0];
    const double reciprocal 	= 1.0 / denominator;
    const double na 			= (b.y * c.x - b.x * c.y) * reciprocal;

	AZBezierPoint *point		= [[_p0.copy add:a] scaleXY:na];
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
- (LineIntersectionSimple) intersectSimple:(AZBezierLine *)l
	{
	AZBezierPoint *a 			= [AZBezierPoint subtract:_p0 from:_p1];
	AZBezierPoint *b 			= [AZBezierPoint subtract:l.p0 from:l.p1];
    const double denominator 	= a.y * b.x - a.x * b.y;

    if (denominator == 0)
		return (LineIntersectionSimple){NO, nil};

	AZBezierPoint *c 			= [AZBezierPoint subtract:l.p0 from:_p0];
    const double reciprocal 	= 1.0 / denominator;
    const double na 			= (b.y * c.x - b.x * c.y) * reciprocal;

	AZBezierPoint *point		= [[_p0.copy add:a] scaleXY:na];
	return (LineIntersectionSimple){YES, point};
	}

/*****************************************************************************\
|* Extend a line by an amount, on the front side
\*****************************************************************************/
- (void) extendFrontBy:(double)length
	{
	if ((self.isPoint) || (FUZZY_ZERO(self.length)))
		return;

	AZBezierPoint *v = self.unitVector;
	_p1 = [AZBezierPoint pointAtX:_p1.x + v.x * length
						  y:_p1.y + v.y * length];
	}

/*****************************************************************************\
|* Extend a line by an amount, at the back
\*****************************************************************************/
- (void) extendBackBy:(double)length
	{
	if ((self.isPoint) || (FUZZY_ZERO(self.length)))
		return;

	AZBezierPoint *v = self.unitVector;
	_p0 = [AZBezierPoint pointAtX:_p1.x - v.x * length
						  y:_p1.y - v.y * length];
	}

/*****************************************************************************\
|* Is the point on the line segment
\*****************************************************************************/
- (BOOL) isPoint:(AZBezierPoint *)p onLineSegmentWithTolerance:(double)epsilon
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
- (BOOL) isPoint:(AZBezierPoint *)p onLineWithTolerance:(double)epsilon
	{
    const double cross = (p.y - _p0.y) * (_p1.x - _p0.x)
					   - (p.x - _p0.x) * (_p1.y - _p0.y);

	return SDL_fabs(cross) < epsilon;
	}


@end
