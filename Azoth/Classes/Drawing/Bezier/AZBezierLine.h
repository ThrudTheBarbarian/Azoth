//
//  AZBezierLine.h
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//  Based on git@github.com:aurimasg/cubic-bezier-offsetter.git
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AZBezierPoint;

typedef enum
	{
	None		= 0,				// No intersection
	Bounded,						// Intersection within line segments
	Unbounded						// Intersection beyond line segments
	} LineIntersectionKind;

typedef struct
	{
	LineIntersectionKind	kind;	// What type of intersection
	AZBezierPoint *			point;	// Intersection point, only if not None
	} LineIntersection;

typedef struct
	{
	BOOL					found;	// What type of intersection
	AZBezierPoint *			point;	// Intersection point, only if not None
	} LineIntersectionSimple;


@interface AZBezierLine : NSObject

/*****************************************************************************\
|* Initialisation : Declare an empty line
\*****************************************************************************/
- (instancetype) init;
+ (instancetype) empty;

/*****************************************************************************\
|* Initialisation : A line between two points
\*****************************************************************************/
- (instancetype) initFrom:(AZBezierPoint *)p1 to:(AZBezierPoint *)p2;
+ (instancetype) lineFrom:(AZBezierPoint *)p1 to:(AZBezierPoint *)p2;

- (instancetype) initFromX:(double)x0 y:(double)y0 toX:(double)x1 y:(double)y1;
+ (instancetype) lineFromX:(double)x0 y:(double)y0 toX:(double)x1 y:(double)y1;

- (instancetype) initFrom:(AZBezierPoint *)p toX:(double)x1 y:(double)y1;
+ (instancetype) lineFrom:(AZBezierPoint *)p toX:(double)x1 y:(double)y1;

- (instancetype) initFromX:(double)x0 y:(double)y0 to:(AZBezierPoint *)p;
+ (instancetype) lineFromX:(double)x0 y:(double)y0 to:(AZBezierPoint *)p;


/*****************************************************************************\
|* Return the reversed line
\*****************************************************************************/
- (AZBezierLine *) reversed;

/*****************************************************************************\
|* Return the unit vector for the line
\*****************************************************************************/
- (AZBezierPoint *) unitVector;

/*****************************************************************************\
|* Return the normal vector for the line
\*****************************************************************************/
- (AZBezierPoint *) normalVector;

/*****************************************************************************\
|* Return the unit normal vector for the line
\*****************************************************************************/
- (AZBezierPoint *) unitNormalVector;

/*****************************************************************************\
|* Return this line translated by a {dx,dy} step
\*****************************************************************************/
- (AZBezierLine *) translated:(AZBezierPoint *)p;

/*****************************************************************************\
|* Return the midpoint of the line
\*****************************************************************************/
- (AZBezierPoint *) midpoint;

/*****************************************************************************\
|* Is this line a point, within a tolerance
\*****************************************************************************/
- (BOOL) isPointWithTolerance:(double)tolerance;

/*****************************************************************************\
|* Get the angle (in degrees) between this line and another
\*****************************************************************************/
- (double) degreesToLine:(AZBezierLine *)other;

/*****************************************************************************\
|* Get the angle (in radians) between this line and another
\*****************************************************************************/
- (double) radiansToLine:(AZBezierLine *)other;

/*****************************************************************************\
|* Get the intersection of this line with another
\*****************************************************************************/
- (LineIntersection) intersect:(AZBezierLine *)other;

/*****************************************************************************\
|* Get the simple intersection of this line with another
\*****************************************************************************/
- (LineIntersectionSimple) intersectSimple:(AZBezierLine *)other;

/*****************************************************************************\
|* Extend a line by an amount, at the front
\*****************************************************************************/
- (void) extendFrontBy:(double)length;

/*****************************************************************************\
|* Extend a line by an amount, at the back
\*****************************************************************************/
- (void) extendBackBy:(double)length;

/*****************************************************************************\
|* Is the point on the line segment
\*****************************************************************************/
- (BOOL) isPoint:(AZBezierPoint *)p onLineSegmentWithTolerance:(double)tolerance;

/*****************************************************************************\
|* Is the point on the line
\*****************************************************************************/
- (BOOL) isPoint:(AZBezierPoint *)p onLineWithTolerance:(double)tolerance;



/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Points that define the line
@property(strong, nonatomic, readonly) AZBezierPoint *			p0;
@property(strong, nonatomic, readonly) AZBezierPoint *			p1;

// Starting point of the line
@property(assign, nonatomic, readonly) double					x0;
@property(assign, nonatomic, readonly) double					y0;

// Ending point of the line
@property(assign, nonatomic, readonly) double					x1;
@property(assign, nonatomic, readonly) double					y1;

// Change in x,y over line
@property(assign, nonatomic, readonly) double					dx;
@property(assign, nonatomic, readonly) double					dy;

// Is this line actually a point
@property(assign, nonatomic, readonly) BOOL 					isPoint;

// length of the line
@property(assign, nonatomic, readonly) double 					length;

// squared length of the line
@property(assign, nonatomic, readonly) double 					lengthSquared;

// angle of the line
@property(assign, nonatomic, readonly) double 					angle;

@end

NS_ASSUME_NONNULL_END
