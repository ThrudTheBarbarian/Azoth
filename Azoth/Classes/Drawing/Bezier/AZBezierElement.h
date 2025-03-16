//
//  AZBezierElement.h
//  Azoth
//
//  Created by Simon Gornall on 3/15/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AZPoint;
@class AZLine;

@interface AZBezierElement : NSObject

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
- (AZLine *) startTangentWithTolerance:(double)tolerance;

/*****************************************************************************\
|* Get the line representing the tangent at the end of the element
\*****************************************************************************/
- (AZLine *) endTangentWithTolerance:(double)tolerance;

/*****************************************************************************\
|* Interpolate the point along the curve, 0 < t < 1
\*****************************************************************************/
- (AZPoint *) pointAt:(double)t;

/*****************************************************************************\
|* Return the normal vector at a given point along the curve, 0 < t < 1
\*****************************************************************************/
- (AZPoint *) normalVector:(double)t;

/*****************************************************************************\
|* Return the unit normal vector at a given point along the curve, 0 < t < 1
\*****************************************************************************/
- (AZPoint *) unitNormalVector:(double)t;

/*****************************************************************************\
|* Return the derivative at a given point along the curve, 0 < t < 1
\*****************************************************************************/
- (AZPoint *) derivativeAt:(double)t;

/*****************************************************************************\
|* Return the second derivative at a given point along the curve, 0 < t < 1
\*****************************************************************************/
- (AZPoint *) secondDerivativeAt:(double)t;

/*****************************************************************************\
|* Fetch a subcurve from the source curve between two points, both 0..1
\*****************************************************************************/
- (AZBezierElement *) subcurveFrom:(double)t to:(double)t1;

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
- (void) splitInto:(AZBezierElement *)l1 and:(AZBezierElement *)l2;

/*****************************************************************************\
|* Find the intersections of a ray with this element
\*****************************************************************************/
- (int) rayIntersectionFrom:(AZPoint *)p0 to:(AZPoint *)p1 roots:(double *)t;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// starting point of the bezier curve
@property(assign, nonatomic) AZPoint *							p0;

// 1st control point of the bezier curve
@property(assign, nonatomic) AZPoint *							c0;

// 2nd control point of the bezier curve
@property(assign, nonatomic) AZPoint *							c1;

// ending point of the bezier curve
@property(assign, nonatomic) AZPoint *							p1;

// tolerance for point equality
@property(assign, nonatomic) double								tolerance;

// Is this element a point
@property(assign, readonly, nonatomic) BOOL						isPoint;

// Is this element a straight line (no curves)
@property(assign, readonly, nonatomic) BOOL						isStraight;
@end

NS_ASSUME_NONNULL_END
