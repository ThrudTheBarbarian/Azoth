//
//  AZLine.h
//  Azoth
//
//  Created by Simon Gornall on 3/15/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AZPoint;

typedef enum
	{
	None		= 0,				// No intersection
	Bounded,						// Intersection within line segments
	Unbounded						// Intersection beyond line segments
	} LineIntersectionKind;

typedef struct
	{
	LineIntersectionKind	kind;	// What type of intersection
	AZPoint *				point;	// Intersection point, only if not None
	} LineIntersection;

typedef struct
	{
	BOOL					found;	// What type of intersection
	AZPoint *				point;	// Intersection point, only if not None
	} LineIntersectionSimple;


@interface AZLine : NSObject

/*****************************************************************************\
|* Initialisation : Declare an empty line
\*****************************************************************************/
- (instancetype) init;
+ (instancetype) empty;

/*****************************************************************************\
|* Initialisation : A line between two points
\*****************************************************************************/
- (instancetype) initFrom:(AZPoint *)p1 to:(AZPoint *)p2;
+ (instancetype) lineFrom:(AZPoint *)p1 to:(AZPoint *)p2;

- (instancetype) initFromX:(double)x0 y:(double)y0 toX:(double)x1 y:(double)y1;
+ (instancetype) lineFromX:(double)x0 y:(double)y0 toX:(double)x1 y:(double)y1;

- (instancetype) initFrom:(AZPoint *)p toX:(double)x1 y:(double)y1;
+ (instancetype) lineFrom:(AZPoint *)p toX:(double)x1 y:(double)y1;

- (instancetype) initFromX:(double)x0 y:(double)y0 to:(AZPoint *)p;
+ (instancetype) lineFromX:(double)x0 y:(double)y0 to:(AZPoint *)p;


/*****************************************************************************\
|* Return the reversed line
\*****************************************************************************/
- (AZLine *) reversed;

/*****************************************************************************\
|* Return the unit vector for the line
\*****************************************************************************/
- (AZPoint *) unitVector;

/*****************************************************************************\
|* Return the normal vector for the line
\*****************************************************************************/
- (AZPoint *) normalVector;

/*****************************************************************************\
|* Return the unit normal vector for the line
\*****************************************************************************/
- (AZPoint *) unitNormalVector;

/*****************************************************************************\
|* Return this line translated by a {dx,dy} step
\*****************************************************************************/
- (AZLine *) translated:(AZPoint *)p;

/*****************************************************************************\
|* Return the midpoint of the line
\*****************************************************************************/
- (AZPoint *) midpoint;

/*****************************************************************************\
|* Is this line a point, within a tolerance
\*****************************************************************************/
- (BOOL) isPointWithTolerance:(double)tolerance;

/*****************************************************************************\
|* Get the angle (in degrees) between this line and another
\*****************************************************************************/
- (double) degreesToLine:(AZLine *)other;

/*****************************************************************************\
|* Get the angle (in radians) between this line and another
\*****************************************************************************/
- (double) radiansToLine:(AZLine *)other;

/*****************************************************************************\
|* Get the intersection of this line with another
\*****************************************************************************/
- (LineIntersection) intersect:(AZLine *)other;

/*****************************************************************************\
|* Get the simple intersection of this line with another
\*****************************************************************************/
- (LineIntersectionSimple) intersectSimple:(AZLine *)other;

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
- (BOOL) isPoint:(AZPoint *)p onLineSegmentWithTolerance:(double)tolerance;

/*****************************************************************************\
|* Is the point on the line
\*****************************************************************************/
- (BOOL) isPoint:(AZPoint *)p onLineWithTolerance:(double)tolerance;



/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Points that define the line
@property(strong, nonatomic, readonly) AZPoint *				p0;
@property(strong, nonatomic, readonly) AZPoint *				p1;

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
