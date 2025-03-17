//
//  AZBezierPath.h
//  Azoth
//
//  Created by Simon Gornall on 3/15/25.
//  Based on git@github.com:aurimasg/cubic-bezier-offsetter.git
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AZBezierPoint;
@class AZBezierLine;

@interface AZBezierPath : NSObject

/*****************************************************************************\
|* Initialisation : Declare an empty bezier path
\*****************************************************************************/
- (instancetype) init;

+ (instancetype) empty;

/*****************************************************************************\
|* Initialisation : Declare a bezier path with the start, end and control pts
\*****************************************************************************/
- (instancetype) initFrom:(NSPoint)p0
				 control1:(NSPoint)c0
				 control2:(NSPoint)c1
					   to:(NSPoint)p1;

+ (instancetype) pathFrom:(NSPoint)p0
				 control1:(NSPoint)c0
				 control2:(NSPoint)c1
					   to:(NSPoint)p1;

/*****************************************************************************\
|* Initialisation : Constructs cubic curve from quadratic curve parameters
\*****************************************************************************/
- (instancetype) initFrom:(NSPoint)p0 control:(NSPoint)c to:(NSPoint)p1;
+ (instancetype) pathFrom:(NSPoint)p0 control:(NSPoint)c to:(NSPoint)p1;

/*****************************************************************************\
|* Initialisation : Constructs cubic curve from a line
\*****************************************************************************/
- (instancetype) initFrom:(NSPoint)p0 to:(NSPoint)p1;
+ (instancetype) pathFrom:(NSPoint)p0 to:(NSPoint)p1;


/*****************************************************************************\
|* Get the line representing the tangent at the start of the element
\*****************************************************************************/
- (AZBezierLine *) startTangentWithTolerance:(double)tolerance;

/*****************************************************************************\
|* Get the line representing the tangent at the end of the element
\*****************************************************************************/
- (AZBezierLine *) endTangentWithTolerance:(double)tolerance;

/*****************************************************************************\
|* Interpolate the point along the curve, 0 < t < 1
\*****************************************************************************/
- (AZBezierPoint *) pointAt:(double)t;

/*****************************************************************************\
|* Return the normal vector at a given point along the curve, 0 < t < 1
\*****************************************************************************/
- (AZBezierPoint *) normalVector:(double)t;

/*****************************************************************************\
|* Return the unit normal vector at a given point along the curve, 0 < t < 1
\*****************************************************************************/
- (AZBezierPoint *) unitNormalVector:(double)t;

/*****************************************************************************\
|* Return the derivative at a given point along the curve, 0 < t < 1
\*****************************************************************************/
- (AZBezierPoint *) derivativeAt:(double)t;

/*****************************************************************************\
|* Return the second derivative at a given point along the curve, 0 < t < 1
\*****************************************************************************/
- (AZBezierPoint *) secondDerivativeAt:(double)t;

/*****************************************************************************\
|* Fetch a subcurve from the source curve between two points, both 0..1
\*****************************************************************************/
- (AZBezierPath *) subcurveFrom:(double)t to:(double)t1;

/*****************************************************************************\
|* Find the roots of the max curvature part of the curve
\*****************************************************************************/
- (int) maxCurvature:(double*)roots;

/*****************************************************************************\
|* Find any inflections in the curve
\*****************************************************************************/
- (int) findInflections:(double*)roots;

/*****************************************************************************\
|* Split a curve into 2 using its midpoint as the cut point
\*****************************************************************************/
- (void) splitInto:(AZBezierPath *)l1 and:(AZBezierPath *)l2;

/*****************************************************************************\
|* Is this curve a point within a tolerance
\*****************************************************************************/
- (BOOL) isPointWithTolerance:(double)tolerance;

/*****************************************************************************\
|* Find the intersections of a ray with this element
\*****************************************************************************/
- (int) rayIntersectionFrom:(AZBezierPoint *)p0
						 to:(AZBezierPoint *)p1
					  roots:(double *)t;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// starting point of the bezier curve
@property(assign, nonatomic) AZBezierPoint *					p0;

// 1st control point of the bezier curve
@property(assign, nonatomic) AZBezierPoint *					c0;

// 2nd control point of the bezier curve
@property(assign, nonatomic) AZBezierPoint *					c1;

// ending point of the bezier curve
@property(assign, nonatomic) AZBezierPoint *					p1;

// tolerance for point equality
@property(assign, nonatomic) double								tolerance;

// Is this element a point
@property(assign, readonly, nonatomic) BOOL						isPoint;

// Is this element a straight line (no curves)
@property(assign, readonly, nonatomic) BOOL						isStraight;

// The list of segments in the path
@property(strong, nonatomic) NSMutableArray<AZBezierPath *> *	segments;
@end

NS_ASSUME_NONNULL_END
