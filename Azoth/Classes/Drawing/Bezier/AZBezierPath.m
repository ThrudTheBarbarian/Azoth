//
//  AZBezierPath.m
//  Azoth
//
//  Created by Simon Gornall on 3/15/25.
//  Based on git@github.com:aurimasg/cubic-bezier-offsetter.git
//

#import "AZBezierPath.h"
#import "AZBezierLine.h"
#import "AZBezierPoint.h"

#define CUBE_ROOT(x) (SDL_pow((x), 1.0/3.0))

@interface AZBezierPath()
@end

@implementation AZBezierPath

/*****************************************************************************\
|* Initialisation : Declare an empty bezier path element
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
		_points 	= 0;
		_segments 	= NSMutableArray.new;
		_tolerance  = DBL_EPSILON;
		_p0			= AZBezierPoint.new;
		_p1			= AZBezierPoint.new;
		_c0			= AZBezierPoint.new;
		_c1			= AZBezierPoint.new;
		}
	return self;
	}

+ (instancetype) empty;
	{
	return AZBezierPath.new;
	}


/*****************************************************************************\
|* Initialisation : Declare a bezier path with the start, end and control pts
\*****************************************************************************/
- (instancetype) initFrom:(NSPoint)p0
				 control1:(NSPoint)c0
				 control2:(NSPoint)c1
					   to:(NSPoint)p1
	{
	if (self = [super init])
		{
		_segments 	= NSMutableArray.new;
		_tolerance	= DBL_EPSILON;
		_p0 		= [AZBezierPoint point:p0];
		_p1 		= [AZBezierPoint point:p1];
		_c0 		= [AZBezierPoint point:c0];
		_c1 		= [AZBezierPoint point:c1];
		_points 	= 4;
		}
	return self;
	}

+ (instancetype) pathFrom:(NSPoint)p0
				 control1:(NSPoint)c0
				 control2:(NSPoint)c1
					   to:(NSPoint)p1
	{
	return [[AZBezierPath alloc] initFrom:p0 control1:c0 control2:c1 to:p1];
	}


/*****************************************************************************\
|* Initialisation : Constructs cubic curve from quadratic curve parameters
\*****************************************************************************/
- (instancetype) initFrom:(NSPoint)p0 control:(NSPoint)c to:(NSPoint)p1
	{
	if (self = [super init])
		{
		_segments 	= NSMutableArray.new;
		_tolerance	= DBL_EPSILON;
		_p0 		= [AZBezierPoint point:p0];
		_p1 		= [AZBezierPoint point:p1];
		_c0 		= [AZBezierPoint point:c];
		[self reconfigureAsQuadratic];
//		_c0			= AZBezierPoint.new;
//		_c1			= AZBezierPoint.new;
//		_c0.x 		= p0.x + (2.0 / 3.0) * (c.x - p0.x);
//		_c0.y 		= p0.y + (2.0 / 3.0) * (c.y - p0.y);
//		_c1.x 		= c.x  + (1.0 / 3.0) * (p1.x - c.x);
//		_c1.y 		= c.y  + (1.0 / 3.0) * (p1.y - c.y);
		_points 	= 4;
		}
	return self;
	}

+ (instancetype) pathFrom:(NSPoint)p0 control:(NSPoint)c to:(NSPoint)p1
	{
	return [[AZBezierPath alloc] initFrom:p0 control:c to:p1];
	}


/*****************************************************************************\
|* Initialisation : Constructs cubic curve from a line
\*****************************************************************************/
- (instancetype) initFrom:(NSPoint)p0 to:(NSPoint)p1
	{
	if (self = [super init])
		{
		_segments 	= NSMutableArray.new;
		_tolerance	= DBL_EPSILON;
		_p0 		= [AZBezierPoint point:p0];
		_p1 		= [AZBezierPoint point:p1];
		[self reconfigureAsLine];
//		_c0			= AZBezierPoint.new;
//		_c1			= AZBezierPoint.new;
//		_c0.x 		= p0.x + (1.0 / 3.0) * (p1.x - p0.x);
//		_c0.y 		= p0.y + (1.0 / 3.0) * (p1.y - p0.y);
//		_c1.x 		= p0.x + (1.0 / 3.0) * (p1.x - p0.x);
//		_c1.y 		= p0.y + (1.0 / 3.0) * (p1.y - p0.y);
		_points 	= 4;
		}
	return self;
	}

+ (instancetype) pathFrom:(NSPoint)p0 to:(NSPoint)p1;
	{
	return [[AZBezierPath alloc] initFrom:p0 to:p1];
	}


// MARK: Mutation methods


/*****************************************************************************\
|* Reconfigure the points as a line between p0 and p1
\*****************************************************************************/
- (void) reconfigureAsLine
	{
	_c0					= AZBezierPoint.new;
	_c1					= AZBezierPoint.new;
	_c0.x 				= _p0.x + (1.0 / 3.0) * (_p1.x - _p0.x);
	_c0.y 				= _p0.y + (1.0 / 3.0) * (_p1.y - _p0.y);
	_c1.x 				= _p0.x + (2.0 / 3.0) * (_p1.x - _p0.x);
	_c1.y 				= _p0.y + (2.0 / 3.0) * (_p1.y - _p0.y);
	}

/*****************************************************************************\
|* Reconfigure the points as a quadratic between p0 and p1, control point c0
\*****************************************************************************/
- (void) reconfigureAsQuadratic;
	{
	AZBezierPoint *c 	= _c0.copy;
	_c0					= AZBezierPoint.new;
	_c1					= AZBezierPoint.new;
	_c0.x 				= _p0.x + (2.0 / 3.0) * (c.x  - _p0.x);
	_c0.y 				= _p0.y + (2.0 / 3.0) * (c.y  - _p0.y);
	_c1.x 				= c.x   + (2.0 / 3.0) * (_p1.x - c.x);
	_c1.y 				= c.y   + (2.0 / 3.0) * (_p1.y - c.y);
	}


// MARK: Property methods

/*****************************************************************************\
|* Implement the isPoint property
\*****************************************************************************/
- (BOOL) isPoint
	{
	return  [_p0 isEqual:_p1 tolerance:_tolerance] &&
			[_p0 isEqual:_c0 tolerance:_tolerance] &&
			[_p0 isEqual:_c1 tolerance:_tolerance];
	}

/*****************************************************************************\
|* Implement the isStraight property
\*****************************************************************************/
- (BOOL) isStraight
	{
    const double minx = MIN(_p0.x, _p1.x);
    const double miny = MIN(_p0.y, _p1.y);
    const double maxx = MAX(_p0.x, _p1.x);
    const double maxy = MAX(_p0.y, _p1.y);

	return
        // Is c0 located between p0 and p1?
        (minx <= _c0.x) &&
        (miny <= _c0.y) &&
        (maxx >= _c0.x) &&
        (maxy >= _c0.y) &&

        // Is c1 located between p0 and p1?
        (minx <= _c1.x) &&
        (miny <= _c1.y) &&
        (maxx >= _c1.x) &&
        (maxy >= _c1.y) &&

        // Are all points collinear?
        [AZBezierPoint isZero:[AZBezierPoint turn:_p0 and:_c0 and:_p1]] &&
		[AZBezierPoint isZero:[AZBezierPoint turn:_p0 and:_c1 and:_p1]];
	}




// MARK: Public methods

/*****************************************************************************\
|* Is this curve a point within a tolerance
\*****************************************************************************/
- (BOOL) isPointWithTolerance:(double)tolerance
	{
	return  [_p0 isEqual:_p1 tolerance:tolerance] &&
			[_p0 isEqual:_c0 tolerance:tolerance] &&
			[_p0 isEqual:_c1 tolerance:tolerance];
	}

/*****************************************************************************\
|* Get the line representing the tangent at the start of the element
\*****************************************************************************/
- (AZBezierLine *) startTangentWithTolerance:(double)tolerance
	{
    if ([_p0 isEqual:_c0 tolerance:tolerance])
		{
		if ([_p0 isEqual:_c1 tolerance:tolerance])
			return [AZBezierLine lineFrom:_p0 to:_p1];
		return [AZBezierLine lineFrom:_p0 to:_c1];
		}
	return [AZBezierLine lineFrom:_p0 to:_c0];
	}

/*****************************************************************************\
|* Get the line representing the tangent at the end of the element
\*****************************************************************************/
- (AZBezierLine *) endTangentWithTolerance:(double)tolerance
	{
    if ([_p1 isEqual:_c1 tolerance:tolerance])
		{
		if ([_p1 isEqual:_c0 tolerance:tolerance])
			return [AZBezierLine lineFrom:_p1 to:_p0];
		return [AZBezierLine lineFrom:_p1 to:_c0];
		}
	return [AZBezierLine lineFrom:_p1 to:_c1];
	}

/*****************************************************************************\
|* Interpolate the point along the curve, 0 < t < 1
\*****************************************************************************/
- (AZBezierPoint *) pointAt:(double)t
	{
	t = SDL_clamp(t, 0.0, 1.0);
    const double it = 1.0 - t;

	AZBezierPoint *a0 = [AZBezierPoint add:[AZBezierPoint scale:_p0 by:it]
							to:[AZBezierPoint scale:_c0 by:t]];

	AZBezierPoint *b0 = [AZBezierPoint add:[AZBezierPoint scale:_c0 by:it]
							to:[AZBezierPoint scale:_c1 by:t]];

	AZBezierPoint *c0 = [AZBezierPoint add:[AZBezierPoint scale:_c1 by:it]
							to:[AZBezierPoint scale:_p1 by:t]];

	AZBezierPoint *a1 = [AZBezierPoint add:[AZBezierPoint scale:a0 by:it]
							to:[AZBezierPoint scale:b0 by:t]];

	AZBezierPoint *b1 = [AZBezierPoint add:[AZBezierPoint scale:b0 by:it]
							to:[AZBezierPoint scale:c0 by:t]];

	return [AZBezierPoint add:[AZBezierPoint scale:a1 by:it]
					 to:[AZBezierPoint scale:b1 by:t]];
	}

/*****************************************************************************\
|* Return the normal vector at a given point along the curve, 0 < t < 1
\*****************************************************************************/
- (AZBezierPoint *) normalVector:(double)t
	{
	if ([AZBezierPoint isZero:t])
		{
		if ([_p0 isEqual:_c0])
			{
			if ([_p0 isEqual:_c1])
				return [AZBezierLine lineFrom:_p0 to:_p1].normalVector;
			else
				return [AZBezierLine lineFrom:_p0 to:_c1].normalVector;
			}
		}
	else if ([AZBezierPoint isZero:t-1.0])
		{
		if ([_c1 isEqual:_p1])
			{
			if ([_c0 isEqual:_p1])
				return [AZBezierLine lineFrom:_p0 to:_p1].normalVector;
            else
				return [AZBezierLine lineFrom:_c0 to:_p1].normalVector;
			}
		}

    AZBezierPoint *d = [self derivativeAt:t];
	return [AZBezierPoint pointAtX:d.y y:-d.x];
	}

/*****************************************************************************\
|* Return the unit normal vector at a given point along the curve, 0 < t < 1
\*****************************************************************************/
- (AZBezierPoint *) unitNormalVector:(double)t
	{
	return [self normalVector:t].unitVector;
	}

/*****************************************************************************\
|* Return the derivative at a given point along the curve, 0 < t < 1
\*****************************************************************************/
- (AZBezierPoint *) derivativeAt:(double)t
	{
	AZBezierPoint *p 	= nil;
	t 					= SDL_clamp(t, 0.0, 1.0);
    const double it 	= 1.0 - t;

    const double d 		= t * t;
    const double a 		= -it * it;
    const double b 		= 1.0 - 4.0 * t + 3.0 * d;
    const double c 		= 2.0 * t - 3.0 * d;

	p = [AZBezierPoint pointAtX:a*_p0.x + b * _c0.x + c * _c1.x + d * _p1.x
							  y:a*_p0.y + b * _c0.y + c * _c1.y + d * _p1.y];

	return [p scaleXY:3.0];
	}

/*****************************************************************************\
|* Return the second derivative at a given point along the curve, 0 < t < 1
\*****************************************************************************/
- (AZBezierPoint *) secondDerivativeAt:(double)t
	{
	AZBezierPoint *p 	= nil;
	t 					= SDL_clamp(t, 0.0, 1.0);
    const double a 		= 2.0 - 2.0 * t;
    const double b 		= -4.0 + 6.0 * t;
    const double c 		= 2.0 - 6.0 * t;
    const double d 		= 2.0 * t;

	p = [AZBezierPoint pointAtX:a*_p0.x + b * _c0.x + c * _c1.x + d * _p1.x
							  y:a*_p0.y + b * _c0.y + c * _c1.y + d * _p1.y];
	return [p scaleXY:3.0];
	}

/*****************************************************************************\
|* Fetch a subcurve from the source curve between two points, both 0..1
\*****************************************************************************/
- (AZBezierPath *) subcurveFrom:(double)t0 to:(double)t1
	{
	if (t0 >= t1)
		{
		SDL_Log("subcurve incorrectly specified, %.2f must be < %.2f", t0, t1);
		return nil;
		}

	// Corner case, t0 is coincident with t1
	if ([AZBezierPoint isZero:t0-t1])
		{
		NSPoint p = [self pointAt:t0].asPoint;
		return [AZBezierPath pathFrom:p control1:p control2:p to:p];
		}

	// If t0 is actually the start...
	if (t0 <= DBL_EPSILON)
		{
		if (t1 >= (1.0 - DBL_EPSILON))
			// Corner case, t0=0, t1=1
			return self;

		// Cut the curve at t1 only
		AZBezierPoint *ab 		= [_p0 lerpTo:_c0 by:t1];
		AZBezierPoint *bc 		= [_c0 lerpTo:_c1 by:t1];
		AZBezierPoint *cd 		= [_c1 lerpTo:_p1 by:t1];
		AZBezierPoint *abc 		= [ab  lerpTo:bc  by:t1];
		AZBezierPoint *bcd 		= [bc  lerpTo:cd  by:t1];
		AZBezierPoint *abcd 	= [abc lerpTo:bcd by:t1];

		return [AZBezierPath pathFrom:_p0.asPoint
								control1:ab.asPoint
								control2:abc.asPoint
									  to:abcd.asPoint];
		}

	// Or t1 is actually the end...
	if (t1 >= (1.0 - DBL_EPSILON))
		{
		// Cut the curve at t0 only
		AZBezierPoint *ab 		= [_p0 lerpTo:_c0 by:t0];
		AZBezierPoint *bc 		= [_c0 lerpTo:_c1 by:t0];
		AZBezierPoint *cd 		= [_c1 lerpTo:_p1 by:t0];
		AZBezierPoint *abc 		= [ab  lerpTo:bc  by:t0];
		AZBezierPoint *bcd 		= [bc  lerpTo:cd  by:t0];
		AZBezierPoint *abcd 	= [abc lerpTo:bcd by:t0];

		return [AZBezierPath pathFrom:abcd.asPoint
								control1:bcd.asPoint
								control2:cd.asPoint
									  to:_p1.asPoint];
		}

	// Else cut the curve at both t0 and t1
	AZBezierPoint *ab0 		= [_p0  lerpTo:_c0  by:t1];
	AZBezierPoint *bc0 		= [_c0  lerpTo:_c1  by:t1];
	AZBezierPoint *cd0 		= [_c1  lerpTo:_p1  by:t1];
	AZBezierPoint *abc0 	= [ab0  lerpTo:bc0  by:t1];
	AZBezierPoint *bcd0 	= [bc0  lerpTo:cd0  by:t1];
	AZBezierPoint *abcd0 	= [abc0 lerpTo:bcd0 by:t1];

    const double m 	= t0 / t1;
	AZBezierPoint *ab1 		= [_p0  lerpTo:ab0   by:m];
	AZBezierPoint *bc1 		= [ab0  lerpTo:abc0  by:m];
	AZBezierPoint *cd1 		= [abc0 lerpTo:abcd0 by:m];
	AZBezierPoint *abc1 	= [ab1  lerpTo:bc1   by:m];
	AZBezierPoint *bcd1 	= [bc1  lerpTo:cd1   by:m];
	AZBezierPoint *abcd1 	= [abc1 lerpTo:bcd1  by:m];

	return [AZBezierPath pathFrom:abcd1.asPoint
							control1:bcd1.asPoint
							control2:cd1.asPoint
								  to:abcd0.asPoint];
	}


/*****************************************************************************\
|* Find the roots of the max curvature part of the curve
\*****************************************************************************/
- (int) maxCurvature:(double*)tValues;
	{
    const double axx = _c0.x -        _p0.x;
    const double bxx = _c1.x - 2.0 *  _c0.x + _p0.x;
    const double cxx = _p1.x + 3.0 * (_c0.x - _c1.x) - _p0.x;

    const double cox0 = cxx * cxx;
    const double cox1 = 3.0 * bxx * cxx;
    const double cox2 = 2.0 * bxx * bxx + cxx * axx;
    const double cox3 = axx * bxx;

    const double ayy = _c0.y -        _p0.y;
    const double byy = _c1.y - 2.0 *  _c0.y + _p0.y;
    const double cyy = _p1.y + 3.0 * (_c0.y - _c1.y) - _p0.y;

    const double coy0 = cyy * cyy;
    const double coy1 = 3.0 * byy * cyy;
    const double coy2 = 2.0 * byy * byy + cyy * ayy;
    const double coy3 = ayy * byy;

    const double coe0 = cox0 + coy0;
    const double coe1 = cox1 + coy1;
    const double coe2 = cox2 + coy2;
    const double coe3 = cox3 + coy3;

    return _findCubicRoots(coe0, coe1, coe2, coe3, tValues);
	}


/*****************************************************************************\
|* Find any inflections in the curve
\*****************************************************************************/
- (int) findInflections:(double*)tValues;
	{
    const double ax = _c0.x - _p0.x;
    const double ay = _c0.y - _p0.y;
    const double bx = _c1.x - 2.0 * _c0.x + _p0.x;
    const double by = _c1.y - 2.0 * _c0.y + _p0.y;
    const double cx = _p1.x + 3.0 * (_c0.x - _c1.x) - _p0.x;
    const double cy = _p1.y + 3.0 * (_c0.y - _c1.y) - _p0.y;

    return _findQuadraticRoots(bx * cy - by * cx,
							   ax * cy - ay * cx,
							   ax * by - ay * bx,
							   tValues);
	}


/*****************************************************************************\
|* Split a curve into 2 using its midpoint as the cut point
\*****************************************************************************/
- (void) splitInto:(AZBezierPath *)l1 and:(AZBezierPath *)l2
	{
	AZBezierPoint *c, *aP2, *bP2, *aP3, *bP3, *m;

	c 		= [AZBezierPoint scale:[AZBezierPoint add:_c0 to:_c1] by:0.5];
	aP2		= [AZBezierPoint scale:[AZBezierPoint add:_p0 to:_c0] by:0.5];
	bP3		= [AZBezierPoint scale:[AZBezierPoint add:_c1 to:_p1] by:0.5];
	aP3		= [AZBezierPoint scale:[AZBezierPoint add:aP2 to:c  ] by:0.5];
	bP2		= [AZBezierPoint scale:[AZBezierPoint add:bP3 to:c  ] by:0.5];
	m		= [AZBezierPoint scale:[AZBezierPoint add:aP3 to:bP2] by:0.5];

	l1.p0 	= _p0;
	l1.c0	= aP2;
	l1.c1 	= aP3;
	l1.p1 	= m;

	l2.p0 	= m;
	l2.c0	= bP2;
	l2.c1 	= bP3;
	l2.p1 	= _p1;
	}

/*****************************************************************************\
|* Find the intersections of a ray with this element
\*****************************************************************************/
- (int) rayIntersectionFrom:(AZBezierPoint *)p0
						 to:(AZBezierPoint *)p1
					  roots:(double *)t;
	{
	AZBezierPoint *v = [AZBezierPoint subtract:p0 from:p1];

    const double ax = (_p0.y - p0.y) * v.x - (_p0.x - p0.x) * v.y;
    const double bx = (_c0.y - p0.y) * v.x - (_c0.x - p0.x) * v.y;
    const double cx = (_c1.y - p0.y) * v.x - (_c1.x - p0.x) * v.y;
    const double dx = (_p1.y - p0.y) * v.x - (_p1.x - p0.x) * v.y;

    const double a = dx;
    const double b = cx * 3;
    const double c = bx * 3;

    const double D = ax;
    const double A = a - (D - c + b);
    const double B = b + (3 * D - 2 * c);
    const double C = c - (3 * D);

    return _findCubicRoots(A, B, C, D, t);
	}



// MARK: Helper functions


/*****************************************************************************\
|* Helper function: Accept a root or not
\*****************************************************************************/
static int _acceptRoot(double *t, const double root)
	{
    if (root < -DBL_EPSILON)
        return 0;
    else if (root > (1.0 + DBL_EPSILON))
        return 0;

    t[0] = SDL_clamp(root, 0.0, 1.0);
    return 1;
	}

/*****************************************************************************\
|* Helper function: roots must not be nil, returns 0..2
\*****************************************************************************/
static int _findQuadraticRoots(const double a,
							   const double b,
							   const double c,
							   double roots[2])
	{
	// Bail if we don't have a valid pointer
	if (roots == NULL)
		{
		SDL_Log("Passed nil roots to _findQuadraticRoots!");
		return 0;
		}

	// Work out b^2 - 4ac, if it's <0, bail
    const double delta = b * b - 4.0 * a * c;
    if (delta < 0.0)
        return 0;

	// If it's +ve..
    if (delta > 0.0)
		{
		const double d 		= SDL_sqrt(delta);
        const double q 		= -0.5 * (b + (b < 0.0 ? -d : d));
        const double rv0 	= q / a;
        const double rv1 	= c / q;

        if (FUZZY_EQUAL(rv0, rv1))
            return _acceptRoot(roots, rv0);

        if (rv0 < rv1)
			{
            int n = _acceptRoot(roots,     rv0);
			n    += _acceptRoot(roots + n, rv1);

            return n;
			}
		else
			{
            int n = _acceptRoot(roots,     rv1);
			n    += _acceptRoot(roots + n, rv0);

            return n;
			}
		}

	// So delta == 0
    if (a != 0)
        return _acceptRoot(roots, -0.5 * b / a);

    return 0;
	}

/*****************************************************************************\
|* Helper function: is a value in the array
\*****************************************************************************/
static BOOL _doubleArrayContainsValue(const double *array,
									  const int count,
									  const double value)
	{
    for (int i = 0; i < count; i++)
		if (FUZZY_EQUAL(array[i], value))
            return YES;

    return NO;
	}

/*****************************************************************************\
|* Helper function: deduplicate an array of doubles
\*****************************************************************************/
static int _deduplicateDoubleArray(double *array, const int currentCount)
	{
    int newCount = 0;

    for (int i = 0; i < currentCount; i++)
		{
        const double value = array[i];

        if (_doubleArrayContainsValue(array, newCount, value))
            continue;

        array[newCount++] = value;
		}
    return newCount;
	}

static int qcompare(const void *a, const void *b)
	{
	double d1 = *((double *)a);
	double d2 = *((double *)b);
	return (d1 < d2) ? -1
		 : (d1 > d2) ? 1
		 : 0;
	}

/*****************************************************************************\
|* Helper function: Find the cubic roots given the coefficients. This function
|* is based on Numerical Recipes 5.6 Quadratic and Cubic Equations
\*****************************************************************************/

static int _findCubicRoots(const double coe0,
						   const double coe1,
						   const double coe2,
						   const double coe3,
						   double roots[3])
	{
	// Bail if we don't have a valid pointer
	if (roots == NULL)
		{
		SDL_Log("Passed nil roots to _findCubicRoots!");
		return 0;
		}

	// Corner case, no cubic term
    if (FUZZY_ZERO(coe0))
		return _findQuadraticRoots(coe1, coe2, coe3, roots);

    const double inva 		= 1.0 / coe0;

    const double a 			= coe1 * inva;
    const double b 			= coe2 * inva;
    const double c 			= coe3 * inva;

    const double Q 			= (a * a - b * 3.0) / 9.0;
    const double R 			= (2.0 * a * a * a - 9.0 * a * b + 27.0 * c) / 54.0;

    const double R2 		= R * R;
    const double Q3 		= Q * Q * Q;
    const double R2subQ3 	= R2 - Q3;
    const double adiv3 		= a / 3.0;

    if (R2subQ3 < 0.0)
		{
        // If Q and R are real (always true when a, b, c are real) and R2 < Q3,
        // then the cubic equation has three real roots.
        const double theta   = SDL_acos(SDL_clamp(R / SDL_sqrt(Q3), -1.0, 1.0));
        const double n2RootQ = -2.0 * SDL_sqrt(Q);

        const double x0 = n2RootQ * SDL_cos(theta / 3.0) - adiv3;
        const double x1 = n2RootQ * SDL_cos((theta + 2.0 * M_PI) / 3.0) - adiv3;
        const double x2 = n2RootQ * SDL_cos((theta - 2.0 * M_PI) / 3.0) - adiv3;

        int n 	= _acceptRoot(roots, x0);
        n 	   += _acceptRoot(roots + n, x1);
        n 	   += _acceptRoot(roots + n, x2);

		qsort(roots, n, sizeof(double), qcompare);

        return _deduplicateDoubleArray(roots, n);
		}

    double A = SDL_fabs(R) + SDL_sqrt(R2subQ3);

    A = CUBE_ROOT(A);

    if (R > 0.0)
        A = -A;

    if (A != 0.0)
        A += Q / A;


    return _acceptRoot(roots, A - adiv3);
	}

@end
