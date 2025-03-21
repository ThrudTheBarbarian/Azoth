//
//  AZBezierPath.m
//  Azoth
//
//  Created by Simon Gornall on 3/16/25.
//  Based on git@github.com:aurimasg/cubic-bezier-offsetter.git
//

#import "AZBezierPath.h"
#import "AZBezierPath.h"
#import "AZBezierLine.h"
#import "AZBezierPoint.h"

/*****************************************************************************\
|* A maximum number of iterations for searching for the closest point to cusp
|* that has the first derivative long enough for finding start or end points
|* of a circular arc for cusp.
|*
|* Smaller value means faster search, but worse accuracy when handling
|* cusp-like points of the curve.
\*****************************************************************************/
static const int _nearCuspPointSearchMaxIterationCount = 18;

/*****************************************************************************\
|* After an attempt to find an offset curve is made, squared lengths of all
|* edges of the polygon enclosing curve is calculated and added together. If
|* this length is equal to or less than this number, the resulting curve will
|* be discarded immediately without attempting to add it to the output.
|*
|* Smaller value means smaller curves will be accepted for output.
\*****************************************************************************/
static const double _maximumTinyCurvePolygonPerimeterSquared = 1e-7;


/*****************************************************************************\
|* If a good circular arc approximation of a curve is found, but its radius is
|* very close to the offset amount, the scaled arc can collapse to a point or
|* almost a point. This is an epsilon for testing if the arc is large enough.
|* Arcs with radius smaller than this value will not be added to the output.
|*
|* Smaller value means smaller arcs will be accepted for output.
\*****************************************************************************/
static const double _minimumArcRadius = 1e-8;


/*****************************************************************************\
|* An upper limit of arc radius. Circular arcs with calculated radius greater
|* than this value will not be considered as accepted approximations of curve
|* segments.
\*****************************************************************************/
static const double _maximumArcRadius = 1e+6;


/*****************************************************************************\
|* Offsetter does not attempt to find exact cusp locations and does not
|* consider cusp only to be where the derivative vector length is exactly
|* zero.
|*
|* Smaller values means that sharper curve edges are considered cusps.
\*****************************************************************************/
static const double _cuspDerivativeLengthSquared = 1.5e-4;


/*****************************************************************************\
|* If X and Y components of all points are equal when compared with this
|* epsilon, the curve is considered a point.
\*****************************************************************************/
static const double _curvePointClumpTestEpsilon = 1e-14;


/*****************************************************************************\
|* Epsilon used to compare coordinates of circular arc centers to see if they
|* can be merged into a single circular arc.
\*****************************************************************************/
static const double _arcCenterComparisonEpsilon = 1e-8;


/*****************************************************************************\
|* When testing if curve is almost straight, cross products of unit vectors
|* are calculated as follows
|*
|*     Turn1 = (P0 → P1) ⨯ (P0 → P3)
|*     Turn2 = (P1 → P2) ⨯ (P0 → P3)
|*
|* Where P0, P1, P2 and P3 are curve points and (X → Y) are unit vectors going
|* from X to a direction of Y.
|*
|* Then these values are compared with zero. If they both are close to zero,
|* curve is considered approximately straight. This is the epsilon used for
|* comparing Turn1 and Turn2 values to zero.
|*
|* Bigger value means less straight curves are considered approximately
|* straight.
\*****************************************************************************/
static const double _approximatelyStraightCurveTestApsilon = 1e-5;


/*****************************************************************************\
|* The logic is the same as for ApproximatelyStraightCurveTestApsilon value.
|* This value is used to determine if curve is completely straight, not just
|* approximately straight.
|*
|* Bigger value means less straight curves are considered completely straight.
|* This value should be smaller than ApproximatelyStraightCurveTestApsilon.
\*****************************************************************************/
static const double _completelyStraightCurveTestApsilon = 1e-15;


/*****************************************************************************\
|* A list of positions on curve for testing if circular arc approximation of a
|* curve is good enough. All values must be from 0 to 1. Positions 0 and 1
|* should not be included here because distances at 0 and 1 are either
|* guaranteed to be exactly on the curve being approximated (on the sides of
|* the input curve) or they are tested before using another methods (ray cast
|* from arc center to triangle incenter point).
\*****************************************************************************/
static const double _arcProbePositions[] =
	{
    0.2,
    0.4,
    0.6,
    0.8
	};


/*****************************************************************************\
|* A list of positions on curve for testing if candidate offset curve is good
|* enough. From points on original curve at each of these positions a ray is
|* cast to normal direction and intersection is found with offset candidate.
|* Then distance is checked to see if it is within maximum error. 0 and 1
|* should not be added in this list because candidate points at 0 and 1 is
|* guaranteed to be at the right place already.
|*
|* Note that testing involves cubic root finding which is not very cheap
|* operation. Adding more testing points increases precision, but also
|* increases the time spent for testing if candidate is good.
\*****************************************************************************/
static const double _simpleOffsetProbePositions[] =
	{
    0.25,
    0.5,
    0.75
	};

/*****************************************************************************\
|* State used to build up the final offset curve
\*****************************************************************************/
typedef struct OutputBuilder
	{
    AZBezierPath *		path;				// Where we're building
    AZBezierPoint * 	previousPoint;		// Last point we have
    AZBezierPoint * 	previousPointT;		// Translated/scaled last point
    AZBezierPoint * 	cuspPoint;			// Where the cusp, if any, is
    BOOL 				needsCuspArc;		// Do we need a cusp arc ?
    BOOL 				cuspArcClockwise;	// Direction of cusp arc
    double 				scale;				// Scaling factor
    AZBezierPoint * 	translation;		// dx, dy
	} OutputBuilder;

#define DECLARE_BUILDER(name, _path, _scale, _translation)					\
	OutputBuilder name;														\
	name.scale 		 		= _scale;										\
	name.translation 		= _translation;									\
	name.path        		= _path;										\
	name.previousPoint		= nil;											\
	name.previousPointT		= nil;											\
	name.cuspPoint			= nil;											\
	name.needsCuspArc		= NO;											\
	name.cuspArcClockwise	= NO

/*****************************************************************************\
|* Represents curve tangents as two line segments and some precomputed data
\*****************************************************************************/
typedef struct CurveTangentData
	{
    AZBezierLine *		startTangent;		// Tangent at start of curve
    AZBezierLine * 		endTangent;			// Tangent at end of curve
    double 				turn1;				// turn value at start
    double 				turn2;				// turn value at end
    AZBezierPoint * 	startUnitNormal;	// unit normal at start
    AZBezierPoint *		endUnitNormal;		// unit normal at end
	} CurveTangentData;

#define DECLARE_TANGENTDATA(name, _path)									\
	CurveTangentData name;													\
	name.startTangent 		= _path.startTangent;							\
	name.endTangent   		= _path.endTangent;								\
	name.turn1 				= _unitTurn(name.startTangent.p0, 				\
										name.startTangent.p1,				\
										name.endTangent.p0);				\
	name.turn2 				= _unitTurn(name.startTangent.p0, 				\
										name.endTangent.p1,					\
										name.endTangent.p0);				\
	name.startUnitNormal	= name.startTangent.unitNormalVector;			\
	name.endUnitNormal		= name.endTangent.unitNormalVector

#define DEG2RAD(x) 	((x) * 0.01745329251994329576923690768489)

#define ARRAY_SIZE(a) ((sizeof(a) / sizeof(*(a))))

#define MAX4(a,b,c,d) (MAX(MAX(MAX(a,b),c),d))
#define MIN4(a,b,c,d) (MIN(MIN(MIN(a,b),c),d))

@implementation AZBezierPath(Offset)

// MARK: Public methods

/*****************************************************************************\
|* Initialisation : Declare an empty bezier path element
\*****************************************************************************/
- (void) addLineFrom:(AZBezierPoint *)p0 to:(AZBezierPoint *)p1
	{
	AZBezierPath *element = [AZBezierPath pathFrom:p0.asPoint
													  to:p1.asPoint];
	[self.segments addObject:element];
	}

/*****************************************************************************\
|* Add a cubic curve to the path
\*****************************************************************************/
- (void) addCubicFrom:(AZBezierPoint *)p0
			 control0:(AZBezierPoint *)c0
			 control1:(AZBezierPoint *)c1
				   to:(AZBezierPoint *)p1
	{
	AZBezierPath *element = [AZBezierPath pathFrom:p0.asPoint
												control1:c0.asPoint
												control2:c1.asPoint
													  to:p1.asPoint];
	[self.segments addObject:element];
	}


// MARK: Property implementation

/*****************************************************************************\
|* Return the first point, or nil
\*****************************************************************************/
- (AZBezierPoint *) firstPoint
	{
	if (self.segments.count == 0)
		return self.p0;

	return self.segments.firstObject.p0;
	}

/*****************************************************************************\
|* Return the last point, or nil
\*****************************************************************************/
- (AZBezierPoint *) lastPoint
	{
	if (self.segments.count == 0)
		return self.p1;

	return self.segments.lastObject.p1;
	}

/*****************************************************************************\
|* Return the tangent at the start of the path
\*****************************************************************************/
- (AZBezierLine *) startTangent
	{
	if (self.segments.count == 0)
		return [self startTangentWithTolerance:DBL_EPSILON];

	return [self.segments.firstObject startTangentWithTolerance:DBL_EPSILON];
	}

/*****************************************************************************\
|* Return the tangent at the start of the path
\*****************************************************************************/
- (AZBezierLine *) endTangent
	{
	if (self.segments.count == 0)
		return [self endTangentWithTolerance:DBL_EPSILON];

	return [self.segments.firstObject endTangentWithTolerance:DBL_EPSILON];
	}

/*****************************************************************************\
|* Return an element by index
\*****************************************************************************/
- (AZBezierPath *) elementAt:(NSInteger)idx
	{
	if ((idx < 0) || (idx > self.segments.count))
		return nil;
	return self.segments[idx];
	}

/*****************************************************************************\
|* Clear out all the entries in this path, make it re-usable
\*****************************************************************************/
- (void) reset
	{
	[self.segments removeAllObjects];
	}


// MARK: static helper methods

/*****************************************************************************\
|* Called once when the first point of output is calculated
\*****************************************************************************/
static void _moveTo(OutputBuilder *b, AZBezierPoint *to)
	{
	b->previousPoint 	= to;
	b->previousPointT 	= [[to.copy scaleXY:b->scale] add:b->translation];
	}

/*****************************************************************************\
|* Called when a new line needs to be added to the output. Line starts at the
|* last point of previously added segment or point set by a call to MoveTo
\*****************************************************************************/
static void _lineTo(OutputBuilder *b, AZBezierPoint *to)
	{
	AZBezierPoint *previous = b->previousPoint;
	if (![previous isEqual:to])
		{
		AZBezierPoint *t = [[to.copy scaleXY:b->scale] add:b->translation];

		[b->path addLineFrom:b->previousPointT to:t];
		b->previousPoint 	= to;
		b->previousPointT 	= t;
		}
	}

/*****************************************************************************\
|* Called when a new cubic curve needs to be added to the output. Curve starts
|* at the last point of previously added segment or point set by a call to
|* _moveTo
\*****************************************************************************/
static void _cubicTo(OutputBuilder *b,
					 AZBezierPoint *cp1,
					 AZBezierPoint *cp2,
    				 AZBezierPoint *to)
	{
	AZBezierPoint *prev = b->previousPoint;
	if ((![prev isEqual:to]) || (![prev isEqual:cp1]) || (![prev isEqual:cp2]))
		{
		AZBezierPoint *c1 = [[cp1.copy scaleXY:b->scale] add:b->translation];
		AZBezierPoint *c2 = [[cp2.copy scaleXY:b->scale] add:b->translation];
		AZBezierPoint *t  = [[to.copy  scaleXY:b->scale] add:b->translation];

		[b->path addCubicFrom:b->previousPointT control0:c1 control1:c2 to:t];

		b->previousPoint 	= to;
		b->previousPointT 	= t;
		}
	}

/*****************************************************************************\
|* Returns unit cubic curve for given circular arc parameters. Arc center is
|* assumed to be at 0, 0.
|*
|* @param p0 Starting point of circular arc. Both components must be in range
|* from -1 to 1.
|*
|* @param p1 End point of circular arc. Both components must be in range from
|* -1 to 1.
\*****************************************************************************/
static AZBezierPath * _findUnitCubicCurveForArc(AZBezierPoint *p0,
												AZBezierPoint *p1)
	{
    const double ax = p0.x;
    const double ay = p0.y;
    const double bx = p1.x;
    const double by = p1.y;
    const double q1 = ax * ax + ay * ay;
    const double q2 = q1 + ax * bx + ay * by;
    const double k2 = (4.0 / 3.0) * (SDL_sqrt(2.0 * q1 * q2) - q2)
					/ (ax * by - ay * bx);
    const double x1 = p0.x - k2 * p0.y;
    const double y1 = p0.y + k2 * p0.x;
    const double x2 = p1.x + k2 * p1.y;
    const double y2 = p1.y - k2 * p1.x;

	return [AZBezierPath pathFrom:p0.asPoint
						 control1:NSMakePoint(x1,y1)
						 control2:NSMakePoint(x2,y2)
							   to:p1.asPoint];
	}

/*****************************************************************************\
|* Called when a circular arc needs to be added to the output. Arc starts at
|* the last point of previously added segment or point set by a call to MoveTo
|* and goes to a given end point.
\*****************************************************************************/
static void _arcTo(OutputBuilder *b,
				   AZBezierPoint *mid,
				   AZBezierPoint *to,
				   BOOL clockwise)
	{
	AZBezierPoint *arcFrom = b->previousPoint;
    const double arcRadius = [mid distanceTo:arcFrom];
    if (arcRadius < _minimumArcRadius)
        return;

	AZBezierLine *midToCurrentPoint = [AZBezierLine lineFrom:mid to:arcFrom];
	AZBezierLine *midToEndPoint 	= [AZBezierLine lineFrom:mid to:to];
	const double startAngle 		= DEG2RAD(midToCurrentPoint.angle);

    double sweepAngle 		= [midToCurrentPoint radiansToLine:midToEndPoint];
    if (FUZZY_ZERO(sweepAngle))
        return;


    const TrianglePointOrientation determinedOrientation =
				[AZBezierPoint triangleOrientation:mid and:arcFrom and:to];

    if (determinedOrientation != Collinear)
		{
        // If our three points are not collinear, we check if they are
        // clockwise. If we see that their orientation is opposite of what we
        // are told to draw, we draw large arc.
        BOOL determinedClockwise = (determinedOrientation == Clockwise);

        if (determinedClockwise != clockwise)
            sweepAngle = (M_PI * 2.0) - sweepAngle;
		}

    const int nSteps 	= SDL_ceil(sweepAngle / (M_PI / 2.0));
    const double step 	= sweepAngle / nSteps * (clockwise ? -1.0 : 1.0);

    double s = -SDL_sin(startAngle);
    double c =  SDL_cos(startAngle);

    for (int i = 1; i <= nSteps; i++)
		{
        const double a1 = startAngle + step * (double)i;

        const double s1 = -SDL_sin(a1);
        const double c1 =  SDL_cos(a1);

		AZBezierPath *unitCurve = _findUnitCubicCurveForArc(
										[AZBezierPoint pointAtX:c y:s],
										[AZBezierPoint pointAtX:c1 y:s1]);

		AZBezierPoint *p1 = [[unitCurve.c0.copy scaleXY:arcRadius] add:mid];
		AZBezierPoint *p2 = [[unitCurve.c1.copy scaleXY:arcRadius] add:mid];

        if (i < nSteps)
			{
			AZBezierPoint *p3 = [[unitCurve.p1.copy scaleXY:arcRadius] add:mid];
            _cubicTo(b, p1, p2, p3);
			}
		else
			{
            // Last point. Make sure we end with it. This is quite important
            // thing to do.
            _cubicTo(b, p1, p2, to);
			}

        s = s1;
        c = c1;
		}
	}

/*****************************************************************************\
|* Determine if we need to add a cusp arc, and do so if so
\*****************************************************************************/
static void _maybeAddCuspArc(OutputBuilder *b, AZBezierPoint *to)
	{
    if (b->needsCuspArc)
		{
        b->needsCuspArc = NO;
        _arcTo(b, b->cuspPoint, to, b->cuspArcClockwise);
		b->cuspPoint = [AZBezierPoint point];
		b->cuspArcClockwise = NO;
		}
	}

/*****************************************************************************\
|* Returns true if the curve is close enough to be considered parallel to the
|* original curve.
|*
|* @param original The original curve.
|*
|* @param parallel Candidate parallel curve to be tested.
|*
|* @param offset Offset from original curve to candidate parallel curve.
|*
|* @param maximumError Maximum allowed error.
\*****************************************************************************/
static BOOL _acceptOffset(AZBezierPath *original,
						  AZBezierPath *parallel,
						  const double offset,
						  const double maximumError)
	{
    // Using shape control method, sometimes output curve becomes completely
    // off in some situations involving start and end tangents being almost
    // parallel. These two checks are to prevent accepting such curves as good.

	BOOL origCW = [AZBezierPoint triangleClockwise:original.p0
											   and:original.c0
											   and:original.p1];
	BOOL prllCW = [AZBezierPoint triangleClockwise:parallel.p0
											   and:parallel.c0
											   and:parallel.p1];
	if (origCW != prllCW)
		return NO;

	origCW = [AZBezierPoint triangleClockwise:original.p0
										  and:original.c1
										  and:original.p1];
	prllCW = [AZBezierPoint triangleClockwise:parallel.p0
										  and:parallel.c1
										  and:parallel.p1];
	if (origCW != prllCW)
		return NO;


    double intersections[3];
    for (int i = 0; i < ARRAY_SIZE(_simpleOffsetProbePositions); i++)
		{
        const double t 		= _simpleOffsetProbePositions[i];
		AZBezierPoint *op0 	= [original pointAt:t];
		AZBezierPoint *n 	= [original normalVector:t];

        const int nRoots 	= [parallel rayIntersectionFrom:op0
														 to:[op0.copy add:n]
													  roots:intersections];
        if (nRoots != 1)
            return NO;

        AZBezierPoint *p0 	= [parallel pointAt:*intersections];
        const double d 		= [op0 distanceTo:p0];
        const double error 	= SDL_fabs(d - SDL_fabs(offset));

        if (error > maximumError)
            return NO;
		}

    return YES;
	}

static void _arcOffset(OutputBuilder *b,
					   const double offset,
					   AZBezierPoint *center,
					   AZBezierPoint *from,
					   AZBezierPoint *to,
					   BOOL clockwise)
	{
	AZBezierLine *l1 = [AZBezierLine lineFrom:center to:from];
	AZBezierLine *l2 = [AZBezierLine lineFrom:center to:to];

    if (clockwise)
		{
		[l1 extendFrontBy:offset];
		[l2 extendFrontBy:offset];
		}
	else
		{
		[l1 extendFrontBy:-offset];
		[l2 extendFrontBy:-offset];
		}

    _maybeAddCuspArc(b, l1.p1);

    // Determine if it is clockwise again since arc orientation may have
    // changed if arc radius was smaller than offset.
    //
    // Also it is important to use previous point to determine orientation
    // instead of the point we just calculated as the start of circular arc
    // because for small arcs a small numeric error can result in incorrect
    // arc orientation.
	BOOL isCW = [AZBezierPoint triangleClockwise:center
											 and:b->previousPoint
											 and:l2.p1];
	_arcTo(b, center, l2.p1, isCW);
	}

/*****************************************************************************\
|* Work out the cross product of the unit vectors of 3 points
\*****************************************************************************/
static double _unitTurn(AZBezierPoint *p1, AZBezierPoint *p2, AZBezierPoint *p3)
	{
	AZBezierPoint * P1 = [p2.copy subtract:p1].unitVector;
	AZBezierPoint * P2 = [p3.copy subtract:p1].unitVector;
	return [P1 cross:P2];
	}

/*****************************************************************************\
|* Returns true if an attempt to approximate a curve with given tangents
|* should be made.
\*****************************************************************************/
static BOOL _canTryArcOffset(CurveTangentData *d)
	{
    // Arc approximation is only attempted if curve is not considered
    // approximately straight. But it can be attemped for curves which have
    // their control points on the different sides of line connecting points
    // P0 and P3.
    //
    // We need to make sure we don't try to do arc approximation for these S
    // type curves because such curves cannot be approximated by arcs in such
    // cases.

    static double P = _approximatelyStraightCurveTestApsilon;
    static double N = -_approximatelyStraightCurveTestApsilon;

    return
        ((d->turn1 >= P) && (d->turn2 >= P)) ||
        ((d->turn1 <= N) && (d->turn2 <= N));
	}

/*****************************************************************************\
|* Returns true if an attempt to use simple offsetting for a curve with given
|* tangents should be made.
\*****************************************************************************/
static BOOL _canTrySimpleOffset(CurveTangentData *d)
	{
    // Arc approximation is only attempted if curve is not considered
    // approximately straight. But it can be attemped for curves which have
    // their control points on the different sides of line connecting points
    // P0 and P3.
    //
    // We need to make sure we don't try to do arc approximation for these S
    // type curves because the shape control method behaves really badly with
    // S shape curves.

    return
        ((d->turn1 >= 0) && (d->turn2 >= 0)) ||
        ((d->turn1 <= 0) && (d->turn2 <= 0));
	}

/*****************************************************************************\
|* Returns true if curve is considered too small to be added to offset output.
\*****************************************************************************/
static BOOL _curveIsTooTiny(AZBezierPath *path)
	{
    const double lengthsSquared =
        [path.p0 distanceToSquared:path.c0] +
        [path.c0 distanceToSquared:path.c1] +
        [path.c1 distanceToSquared:path.p1];

    return lengthsSquared <= _maximumTinyCurvePolygonPerimeterSquared;
	}

/*****************************************************************************\
|* Attempts to perform simple curve offsetting and returns true if it succeeds
|* to generate good enough parallel curve.
\*****************************************************************************/
static BOOL _trySimpleCurveOffset(AZBezierPath *curve,
								  CurveTangentData *d,
								  OutputBuilder *bld,
								  const double offset,
								  const double maximumError)
	{
    if (!_canTrySimpleOffset(d))
        return NO;

	AZBezierPoint *d1 	= [curve.c0.copy subtract:curve.p0];
	AZBezierPoint *d2 	= [curve.c1.copy subtract:curve.p1];
    const double div 	= [d1 cross:d2];

    if (FUZZY_ZERO(div))
        return NO;

    // Start point.
	AZBezierPoint *p0 	= [[[d->startTangent unitNormalVector]
						   scaleXY:offset]
						   add:d->startTangent.p0];

    // End point.
	AZBezierPoint *p3 	= [[[[d->endTangent unitNormalVector]
						   scaleXY:offset] negate]
						   add:d->endTangent.p0];

    // Middle point.
	AZBezierPoint *mp 	= [curve pointAt:0.5];
	AZBezierPoint *mpN 	= [curve unitNormalVector:0.5];
	AZBezierPoint *p	= [[mpN.copy scaleXY:offset] add:mp];

	AZBezierPoint *bxbm	= [[p0.copy add:p3] scaleXY:0.5];
	AZBezierPoint *bxby = [[p.copy subtract:bxbm] scaleXY:8.0/3.0];

    const double a 		= [bxby cross:d2] / div;
    const double b 		= [d1 cross:bxby] / div;

	AZBezierPoint *p1	= [AZBezierPoint pointAtX:p0.x + a * d1.x
												y:p0.y + a * d1.y];
	AZBezierPoint *p2	= [AZBezierPoint pointAtX:p3.x + b * d2.x
												y:p3.y + b * d2.y];

	AZBezierPath *candidate = [AZBezierPath pathFrom:p0.asPoint
											control1:p1.asPoint
											control2:p2.asPoint
												  to:p3.asPoint];
    if (_curveIsTooTiny(candidate))
        // If curve is too tiny, tell caller there was a great success.
        return YES;

    if (!_acceptOffset(curve, candidate, offset, maximumError))
        return NO;

    _maybeAddCuspArc(bld, candidate.p0);
	_cubicTo(bld, candidate.c0, candidate.c1, candidate.p1);

    return YES;
	}

/*****************************************************************************\
|* Utility function to figure out it we can merge things
\*****************************************************************************/
static BOOL _doubleArrayContainsMergePosition(const double *a,
											  const int count,
											  const double value,
											  const double epsilon)
	{
    for (int i = 0; i < count; i++)
		{
        if (FUZZY_EQUAL_WITH(value, a[i], epsilon))
            return YES;
        }

    return NO;
	}

/*****************************************************************************\
|* Merge similar entries in the double array
\*****************************************************************************/
static int _mergeCurvePositions(double t[5],
							    const int t_count,
							    const double *s,
							    const int count,
							    const double epsilon)
	{
    int rc = t_count;

    for (int i = 0; i < count; i++)
		{
        const double v = s[i];

        if (FUZZY_EQUAL_WITH(v, 0.0, epsilon))
            continue;

        if (FUZZY_EQUAL_WITH(v, 1.0, epsilon))
            continue;

        if (_doubleArrayContainsMergePosition(t, rc, v, epsilon))
            continue;

        t[rc++] = v;
		}

    return rc;
	}

/*****************************************************************************\
|* Returns true if a given line segment intersects with circle. Only
|* intersection within line segment is considered.
|*
|* @param line Line segment.
|*
|* @param circleCenter Position of the circle center.
|*
|* @param circleRadius Circle radius. Must not be negative.
\*****************************************************************************/
static BOOL _lineCircleIntersect(AZBezierLine *line,
								AZBezierPoint *circleCenter,
								const double circleRadius)
	{
	if (circleRadius < 0)
		{
		SDL_Log("Passed negative circle radius to _lineCircleIntersect!");
		return NO;
		}

	AZBezierPoint *d 			= [line.p1.copy subtract:line.p0];
	AZBezierPoint *g 			= [line.p0.copy subtract:circleCenter];

    const double a 				= [d dot:d];
    const double b 				= 2.0 * [g dot:d];
    const double crSquared 		= circleRadius * circleRadius;
    const double c 				= [g dot:g] - crSquared;
    const double discriminant	= b * b - 4.0 * a * c;

    if (discriminant > 0)
		{
        const double dsq 	= SDL_sqrt(discriminant);
        const double a2 	= a * 2.0;
        const double t1 	= (-b - dsq) / a2;
        const double t2 	= (-b + dsq) / a2;

        return ((t1 >= 0.0) && (t1 <= 1.0)) || ((t2 >= 0.0) && (t2 <= 1.0));
		}

    return NO;
	}

/*****************************************************************************\
|* Linear interpolation
\*****************************************************************************/
static double _lerp(double a, double b, double t)
	{
	return a + ((b-a) * t);
	}

/*****************************************************************************\
|* Returns true if circular arc with given parameters approximate curve close
|* enough.
|*
|* @param arcCenter Point where arc center is located.
|*
|* @param arcRadius Radius of arc.
|*
|* @param curve Curve being approximated with arc.
|*
|* @param maximumError Maximum allowed error.
\*****************************************************************************/
static BOOL _goodArc(AZBezierPoint *arcCenter,
					 const double arcRadius,
					 AZBezierPath *curve,
					 const double maximumError,
					 const double tFrom,
					 const double tTo)
	{
    if (arcRadius > _maximumArcRadius)
        return NO;

    const double e = MIN(maximumError, arcRadius / 3.0);

    // Calculate value equal to slightly more than half of maximum error.
    // Slightly more to minimize false negatives due to finite precision in
    // circle-line intersection test.
    const double me = (e * (0.5 + 1e-4));

    for (int i = 0; i < ARRAY_SIZE(_arcProbePositions); i++)
		{
        const double t = _arcProbePositions[i];

        // Find t on a given curve.
        const double curveT = _lerp(t, tFrom, tTo);

        // Find point and normal at this position.
		AZBezierPoint *point 	= [curve pointAt:curveT];
		AZBezierPoint *n 	 	= [curve unitNormalVector:curveT];

        // Create line segment which has its center at curve on point and
        // extends by half of maximum allowed error to both directions from
        // curve point along normal.
		AZBezierPoint *l0		= [[n.copy scaleXY:me] add:point];
		AZBezierPoint *l1		= [[[n.copy scaleXY:me] negate] add:point];
		AZBezierLine *segment 	= [AZBezierLine lineFrom:l0 to:l1];

        // Test if intersection exists.
        if (!_lineCircleIntersect(segment, arcCenter, arcRadius))
            return NO;
		}

    return YES;
	}

/*****************************************************************************\
|* Attempts to use circular arc offsetting method on a given curve
\*****************************************************************************/
static BOOL _tryArcApproximation(AZBezierPath *curve,
								 CurveTangentData *d,
								 OutputBuilder *builder,
								 const double offset,
								 const double maximumError)
	{
    if (!_canTryArcOffset(d))
        return NO;

    // Cast ray from curve end points to start and end tangent directions.
	AZBezierPoint *vectorFrom	= d->startTangent.unitVector;
	AZBezierPoint *vectorTo		= d->endTangent.unitVector;
    const double denom 			= vectorTo.x * vectorFrom.y
								- vectorTo.y * vectorFrom.x;

    // Should not happen as we already elliminated parallel case.
    if (FUZZY_ZERO(denom))
        return NO;

	AZBezierPoint *asv	= d->startTangent.p0;
	AZBezierPoint *bsv	= d->endTangent.p0;

    const double u 		= ((bsv.y - asv.y) * vectorTo.x
						-  (bsv.x - asv.x) * vectorTo.y) / denom;
    const double v 		= ((bsv.y - asv.y) * vectorFrom.x
						-  (bsv.x - asv.x) * vectorFrom.y) / denom;

    if ((u < 0.0) || (v < 0.0))
        // Intersection is on the wrong side.
        return NO;

	AZBezierPoint *V = [[vectorFrom.copy scaleXY:u] add:asv];

    // If start or end tangents extend too far beyond intersection, return
    // early since it will not result in good approximation.
    if (([curve.p0 distanceToSquared:V] < d->startTangent.lengthSquared * 0.25)
    ||  ([curve.p1 distanceToSquared:V] < d->endTangent.lengthSquared * 0.25))
        return NO;

    const double P3VDistance 	= [curve.p1 distanceTo:V];
    const double P0VDistance 	= [curve.p0 distanceTo:V];
    const double P0P3Distance 	= [curve.p0 distanceTo:curve.p1];
	AZBezierLine *P0G, *GP3, *E, *E1;

	AZBezierPoint * numerator 	= [[[curve.p0.copy scaleXY:P3VDistance] add:
									[curve.p1.copy scaleXY:P0VDistance]] add:
									[V.copy scaleXY:P0P3Distance]];
	double denominator			= P3VDistance + P0VDistance + P0P3Distance;
	AZBezierPoint *G 			= [numerator scaleXY:1.0/denominator];
	AZBezierPoint *dN 			= d->startTangent.normalVector;

	P0G	= [AZBezierLine lineFrom:curve.p0 to:G];
	GP3	= [AZBezierLine lineFrom:G to:curve.p1];

	E	= [AZBezierLine lineFrom:P0G.midpoint
							  to:[P0G.midpoint.copy subtract:P0G.normalVector]];
	E1	= [AZBezierLine lineFrom:d->startTangent.p0
							  to:[d->startTangent.p0.copy subtract:dN]];

    const LineIntersectionSimple C1 = [E intersectSimple:E1];
    if (!C1.found)
        return NO;

    double intersections[3];
    const int nRoots = [curve rayIntersectionFrom:C1.point
											   to:G
											roots:intersections];
    if (nRoots != 1)
        return NO;

    const double tG 	= *intersections;
    const double dist0 	= [G distanceTo:[curve pointAt:tG]];

    if (dist0 > maximumError)
        return NO;

	AZBezierLine *F, *F1;


	dN	= d->endTangent.normalVector;
	F 	= [AZBezierLine lineFrom:GP3.midpoint
							  to:[GP3.midpoint.copy subtract:GP3.normalVector]];
    F1  = [AZBezierLine lineFrom:d->endTangent.p0
							  to:[d->endTangent.p0.copy add:dN]];


    const LineIntersectionSimple C2 = [F intersectSimple:F1];
    if (!C2.found)
        return NO;

    if ([C1.point isEqual:C2.point tolerance:_arcCenterComparisonEpsilon])
		{
        const double radius = [C1.point distanceTo:curve.p0];

        if (_goodArc(C1.point, radius, curve, maximumError, 0, 1))
			{
			BOOL isCW = [AZBezierPoint triangleClockwise:curve.p0
													 and:V
													 and:curve.p1];

            _arcOffset(builder, offset, C1.point, curve.p0, curve.p1, isCW);
            return YES;
			}
		}
	else
		{
        const double radius1 = [C1.point distanceTo:curve.p0];
        if (!_goodArc(C1.point, radius1, curve, maximumError, 0, tG))
            return NO;

        const double radius2 = [C2.point distanceTo:curve.p1];
        if (!_goodArc(C2.point, radius2, curve, maximumError, tG, 1))
            return NO;

		BOOL isCW = [AZBezierPoint triangleClockwise:curve.p0
												 and:V
												 and:curve.p1];

        _arcOffset(builder, offset, C1.point, curve.p0, G, isCW);
        _arcOffset(builder, offset, C2.point, G, curve.p1, isCW);
        return YES;
		}

    return NO;
	}

/*****************************************************************************\
|* Determine if this curve is more or less a straight line
\*****************************************************************************/
static BOOL _isCurveApproximatelyStraight(CurveTangentData *d)
	{
    const double minx = MIN(d->startTangent.x0, d->endTangent.x0);
    const double miny = MIN(d->startTangent.y0, d->endTangent.y0);
    const double maxx = MAX(d->startTangent.x0, d->endTangent.x0);
    const double maxy = MAX(d->startTangent.y0, d->endTangent.y0);

    const double x1 = d->startTangent.x1;
    const double y1 = d->startTangent.y1;
    const double x2 = d->endTangent.x1;
    const double y2 = d->endTangent.y1;

    return
        // Is P1 located between P0 and P3?
        (minx <= x1) &&
        (miny <= y1) &&
        (maxx >= x1) &&
        (maxy >= y1) &&
        // Is P2 located between P0 and P3?
        (minx <= x2) &&
        (miny <= y2) &&
        (maxx >= x2) &&
        (maxy >= y2) &&
        // Are all points collinear?
        FUZZY_EQUAL_WITH(d->turn1, 0, _approximatelyStraightCurveTestApsilon) &&
        FUZZY_EQUAL_WITH(d->turn2, 0, _approximatelyStraightCurveTestApsilon);
	}

/*****************************************************************************\
|* Determine if this curve is a straight line
\*****************************************************************************/
static BOOL _curveIsCompletelyStraight(CurveTangentData *d)
	{
    return
        FUZZY_EQUAL_WITH(d->turn1, 0, _completelyStraightCurveTestApsilon) &&
        FUZZY_EQUAL_WITH(d->turn2, 0, _completelyStraightCurveTestApsilon);
	}

/*****************************************************************************\
|* Main function for approximating offset of a curve without cusps.
\*****************************************************************************/
static void _approximateBezier(AZBezierPath *curve,
							   CurveTangentData *d,
							   OutputBuilder *B,
							   const double offset,
							   const double maximumError)
	{
    if (![curve isPointWithTolerance:_curvePointClumpTestEpsilon])
		{
        if (_isCurveApproximatelyStraight(d))
			{
            if (_curveIsCompletelyStraight(d))
				{
                // Curve is extremely close to being straight.
                AZBezierLine *line 		= [AZBezierLine lineFrom:curve.p0
															  to:curve.c0];
                AZBezierPoint *normal 	= line.unitNormalVector;

                _maybeAddCuspArc(B, [[normal.copy scaleXY:offset] add:line.p0]);
                _lineTo(B, [[normal.copy scaleXY:offset] add:line.p1]);
				}
			else
				{
				AZBezierPoint *p1o, *p2o, *p3o, *p4o;
				p1o = [[d->startUnitNormal.copy scaleXY:offset]
							add:d->startTangent.p0];
				p2o = [[d->startUnitNormal.copy scaleXY:offset]
							add:d->startTangent.p1];
				p3o = [[[d->endUnitNormal.copy scaleXY:offset] negate]
							add:d->endTangent.p1];
				p4o = [[[d->endUnitNormal.copy scaleXY:offset] negate]
							add:d->endTangent.p0];

                _maybeAddCuspArc(B, p1o);
                _cubicTo(B, p2o, p3o, p4o);
				}
			}
		else
			{
            if (!_trySimpleCurveOffset(curve, d, B, offset, maximumError))
				{
                if (!_tryArcApproximation(curve, d, B, offset, maximumError))
					{
                    // Split in half and continue.
					AZBezierPath *a = AZBezierPath.new;
					AZBezierPath *b = AZBezierPath.new;
					[curve splitInto:a and:b];

					DECLARE_TANGENTDATA(da, a);
                    _approximateBezier(a, &da, B, offset, maximumError);

 					DECLARE_TANGENTDATA(db, b);
					_approximateBezier(b, &db, B, offset, maximumError);
					}
				}
			}
		}
	}

/*****************************************************************************\
|* Find position on curve with large enough derivative
\*****************************************************************************/
static double _findPositionOnCurveWithLargeEnoughDerivative(
				AZBezierPath *curve,
				const double previousT,
				const double currentT)
	{
    static double kPrecision = _cuspDerivativeLengthSquared * 2.0;
	if (previousT >= currentT)
		{
		SDL_Log("Previous interpolation is ahead of current interpolation!");
		return 0.0;
		}

    double t = MAX(_lerp(previousT, currentT, 0.8), currentT - 0.05);
    for (int i = 0; i < _nearCuspPointSearchMaxIterationCount; i++)
		{
		AZBezierPoint *derivative  = [curve derivativeAt:t];
        const double lengthSquared = derivative.lengthSquared;

        if (lengthSquared < kPrecision)
            return t;

        const double a = t + currentT;
        t = a / 2.0;
		}
    return t;
	}

/*****************************************************************************\
|* Find position on curve with large enough derivative to start with
\*****************************************************************************/
static double _findPositionOnCurveWithLargeEnoughDerivativeStart (
				AZBezierPath *curve,
				const double currentT,
				const double nextT)
	{
    static double kPrecision = _cuspDerivativeLengthSquared * 2.0;
	if (nextT <= currentT)
		{
		SDL_Log("Previous interpolation is ahead of current interpolation!");
		return 0.0;
		}

    double t = MIN(_lerp(currentT, nextT, 0.2), currentT + 0.05);
    for (int i = 0; i < _nearCuspPointSearchMaxIterationCount; i++)
		{
		AZBezierPoint *derivative  = [curve derivativeAt:t];
        const double lengthSquared = derivative.lengthSquared;

        if (lengthSquared < kPrecision)
            return t;

        const double a = t + currentT;
        t = a / 2.0;
		}
    return t;
	}

/*****************************************************************************\
|* If all points of the curve are collinear, a shortcut must be made because
|* general offsetting algorithm does not handle such curves very well. In case
|* where are points are collinear, lines between cusps are offset to direction
|* of their normals and at the points where curve has a cusps, semi-circles
|* are added to the output.
\*****************************************************************************/
static void _offsetLinearCuspyCurve(AZBezierPath *curve,
									OutputBuilder *builder,
									const double offset,
									const double *maximumCurvaturePoints,
									const int maximumCurvaturePointCount)
	{
    AZBezierLine *startTangent = curve.startTangent;
    AZBezierPoint *normal 	   = startTangent.unitNormalVector;

    AZBezierPoint * previousPoint 		= startTangent.p0;
	AZBezierPoint * previousOffsetPoint = [normal.copy scaleXY:offset];
	[previousOffsetPoint add:previousPoint];

    _moveTo(builder, previousOffsetPoint);

    for (int i = 0; i < maximumCurvaturePointCount; i++)
		{
        // Skip 0 and 1!
        const double t 				= maximumCurvaturePoints[i];
		AZBezierPoint *derived		= [curve derivativeAt:t];
        const double lengthSquared 	= derived.lengthSquared;

        if (lengthSquared <= 1e-9)
			{
			AZBezierLine *l;
			AZBezierPoint *arcTo;

            // Cusp. Since we know all curve points are on the same line, some
            // of maximum curvature points will have nearly zero length
            // derivative vectors.
            AZBezierPoint *pointAtCusp = [curve pointAt:t];

            // Draw line from previous point to point at cusp.
			l = [AZBezierLine lineFrom:previousPoint to:pointAtCusp];
            AZBezierPoint *n = l.unitNormalVector;
			AZBezierPoint *to = [[n.copy scaleXY:offset] add:pointAtCusp];

            _lineTo(builder, to);

            // Draw semi circle at cusp.
			arcTo = [[[n.copy scaleXY:offset] negate] add:pointAtCusp];

            _arcTo(builder,
				   pointAtCusp,
				   arcTo,
				   [AZBezierPoint triangleClockwise:previousPoint
												and:previousOffsetPoint
												and:pointAtCusp]);
            previousPoint 		= pointAtCusp;
            previousOffsetPoint = arcTo;
			}
		}

    AZBezierLine *endTangent = curve.endTangent;
    AZBezierPoint *normal2 	 = endTangent.unitNormalVector;
	_lineTo(builder, [[[normal2.copy scaleXY:offset] negate] add:endTangent.p0]);
	}

static int qcomp(const void *a, const void *b)
	{
	double d1 = *((double *)a);
	double d2 = *((double *)b);
	return (d1 < d2) ? -1
		 : (d1 > d2) ? 1
		 : 0;
	}

/*****************************************************************************\
|* Create an approximate bezier curve
\*****************************************************************************/
static void _doApproximateBezier(AZBezierPath *curve,
								 CurveTangentData *d,
								 OutputBuilder *builder,
								 const double offset,
								 const double maximumError)
	{
    // First find maximum curvature positions.
    double maxCurvePosns[3];
    const int numMaxCurvePosns = [curve maxCurvature:maxCurvePosns];

    // Handle special case where the input curve is a straight line, but
    // control points do not necessary lie on line segment between curve
    // points P0 and P3.
    if (_curveIsCompletelyStraight(d))
		{
        _offsetLinearCuspyCurve(curve,
							    builder,
							    offset,
								maxCurvePosns,
								numMaxCurvePosns);
        return;
		}

    // Now find inflection point positions.
    double inflects[2];
    const int numInflects = [curve findInflections:inflects];

    // Merge maximum curvature and inflection point positions.
    double t[5];
    const int count0 = _mergeCurvePositions(t, 0, inflects, numInflects, 1e-7);

    const int count = _mergeCurvePositions(t,
										   count0,
										   maxCurvePosns,
										   numMaxCurvePosns,
										   1e-5);

	qsort(t, count, sizeof(double), qcomp);
    if (count == 0)
		{
        // No initial subdivision suggestions.
        _approximateBezier(curve, d, builder, offset, maximumError);
		}
	else
		{
        double previousT = 0;

        for (int i = 0; i < count; i++)
			{
            const double T = t[i];
            AZBezierPoint *derivative  = [curve derivativeAt:T];
            const double lengthSquared = derivative.lengthSquared;

            if (lengthSquared < _cuspDerivativeLengthSquared)
				{
                // Squared length of derivative becomes tiny. This is where
                // the cusp is. The goal here is to find a spot on curve,
                // located before T which has large enough derivative and draw
                // circular arc to the next point on curve with large enough
                // derivative.

                double t1 = _findPositionOnCurveWithLargeEnoughDerivative(
								curve, previousT, T);

				if (t1 >= T)
					{
					SDL_Log("Failure trying to work around cusp in curve");
					return;
					}

                AZBezierPath *k = [curve subcurveFrom:previousT to:t1];
                DECLARE_TANGENTDATA(nd, k);
                _approximateBezier(k, &nd, builder, offset, maximumError);

                double t2 = _findPositionOnCurveWithLargeEnoughDerivativeStart(
								curve, T, i == (count - 1) ? 1.0 : t[i + 1]);

				if (t2 <= T)
					{
					SDL_Log("Failure trying to work around cusp (#2) in curve");
					return;
					}

				BOOL isCW = [AZBezierPoint triangleClockwise:k.p1
														 and:builder->cuspPoint
														 and:[curve pointAt:t2]];

                builder->cuspPoint 		 	= [curve pointAt:T];
                builder->needsCuspArc 	 	= YES;
				builder->cuspArcClockwise 	= isCW;
                previousT = t2;
				}
			else
				{
                // Easy, feed subcurve between previous and current t values
                // to offset approximation function.

                AZBezierPath *k = [curve subcurveFrom:previousT to:T];
				DECLARE_TANGENTDATA(nd, k);
				_approximateBezier(k, &nd, builder, offset, maximumError);
                previousT = T;
				}
			}

		if (previousT >= 1.0)
			{
			SDL_Log("Failure trying to work around cusp (#3) in curve");
			return;
			}

        AZBezierPath *k = [curve subcurveFrom:previousT to:1.0];
		DECLARE_TANGENTDATA(nd, k);

        _approximateBezier(k, &nd, builder, offset, maximumError);
		}
	}


/*****************************************************************************\
|* Flattens ends of curves if control points are too close to end points
\*****************************************************************************/
static AZBezierPath * _fixRedundantTangents(AZBezierPath *curve)
	{
    AZBezierPoint *p1 = curve.c0;
    AZBezierPoint *p2 = curve.c1;

    if ([curve.p0 distanceToSquared:p1] < 1e-12)
        p1 = curve.p0;

    if ([curve.p1 distanceToSquared:p2] < 1e-12)
        p2 = curve.p1;

	return [AZBezierPath pathFrom:curve.p0.asPoint
						 control1:p1.asPoint
						 control2:p2.asPoint
							   to:curve.p1.asPoint];
	}


// MARK: offset curve


/*****************************************************************************\
|* Create an offset curve from this one
|*
|* - if offset == 0, then the same curve will be returned, otherwise larger
|*   values mean larger offsets, offset can be -ve
|* - lower maxError means better precision and more output segments, the
|*   reverse is also true
\*****************************************************************************/
- (nullable AZBezierPath *) curveWithOffset:(double)offset
								   maxError:(double)maxError
	{
	AZBezierPath *builder = AZBezierPath.new;

    const double minx 	= MIN4(self.p0.x, self.c0.x, self.c1.x, self.p1.x);
    const double maxx 	= MAX4(self.p0.x, self.c0.x, self.c1.x, self.p1.x);
    const double miny 	= MIN4(self.p0.y, self.c0.y, self.c1.y, self.p1.y);
    const double maxy 	= MAX4(self.p0.y, self.c0.y, self.c1.y, self.p1.y);

    const double dx 	= maxx - minx;
    const double dy 	= maxy - miny;

    if ((dx < _curvePointClumpTestEpsilon) && (dy < _curvePointClumpTestEpsilon))
		{
		return nil;
		}

    // Select bigger of width and height.
    const double m 	= MAX(dx, dy) / 2.0;
	const double rm	= 1.0/m;

    // Calculate scaled offset.
    const double so = offset / m;

    if (FUZZY_ZERO(so))
		{
        [builder addCubicFrom:self.p0
					 control0:self.c0
					 control1:self.c1
						   to:self.p1];
        return builder;
		}

    // Calculate "normalized" curve which kind of fits into range from -1 to 1.
    const double tx 	= (minx + maxx) / 2.0;
    const double ty 	= (miny + maxy) / 2.0;
	AZBezierPoint *t 	= [AZBezierPoint pointAtX:tx y:ty];

	AZBezierPoint *p0 	= [self.p0.copy subtract:t];
	AZBezierPoint *p1 	= [self.c0.copy subtract:t];
	AZBezierPoint *p2 	= [self.c1.copy subtract:t];
	AZBezierPoint *p3 	= [self.p1.copy subtract:t];

	AZBezierPath *sc	= [AZBezierPath pathFrom:[p0 scaleXY:rm].asPoint
										control1:[p1 scaleXY:rm].asPoint
										control2:[p2 scaleXY:rm].asPoint
											  to:[p3 scaleXY:rm].asPoint];

	AZBezierPath *c		= _fixRedundantTangents(sc);
	DECLARE_BUILDER(b, builder, m, t);
	DECLARE_TANGENTDATA(d, c);

    if (_isCurveApproximatelyStraight(&d))
		{
        if (_curveIsCompletelyStraight(&d))
			{
            // Curve is extremely close to being straight, use simple line
            // translation.
			AZBezierLine *line 		= [AZBezierLine lineFrom:c.p0 to:c.p1];
			AZBezierPoint *normal	= line.unitNormalVector;
			AZBezierLine *moved		= [line translated:[normal scaleXY:so]];

            _moveTo(&b, moved.p0);
            _lineTo(&b, moved.p1);
			}
		else
			{
			AZBezierPoint *p1o, *p2o, *p3o, *p4o;

            // Curve is almost straight. Translate start and end tangents
            // separately and generate a cubic curve.
			p1o = [[d.startUnitNormal.copy scaleXY:so] add:d.startTangent.p0];
			p2o = [[d.startUnitNormal.copy scaleXY:so] add:d.startTangent.p1];
			p3o = [[[d.endUnitNormal.copy scaleXY:so] negate] add:d.endTangent.p1];
			p4o = [[[d.endUnitNormal.copy scaleXY:so] negate] add:d.endTangent.p0];

            _moveTo(&b, p1o);
			_cubicTo(&b, p2o, p3o, p4o);
			}
		}
	else
		{
        // Arbitrary curve.
		_moveTo(&b, [[d.startUnitNormal.copy scaleXY:so] add:d.startTangent.p0]);

        // Try arc approximation first in case this curve was intended to
        // approximate circle. If that is indeed true, we avoid a lot of
        // expensive calculations like finding inflection and maximum
        // curvature points.
        if (!_tryArcApproximation(c, &d, &b, so, maxError))
            _doApproximateBezier(c, &d, &b, so, maxError);
		}

	return builder;
	}

@end
