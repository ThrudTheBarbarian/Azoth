//
//  AZBezierPoint.h
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//  Based on git@github.com:aurimasg/cubic-bezier-offsetter.git
//

#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>

#define FUZZY_EQUAL_WITH(x,y,t)	(SDL_fabs((x)-(y)) < (t))
#define FUZZY_EQUAL(x,y)		(SDL_fabs((x)-(y)) < DBL_EPSILON)
#define FUZZY_ZERO(x)			(SDL_fabs(x) < DBL_EPSILON)

NS_ASSUME_NONNULL_BEGIN

typedef enum
	{
	Clockwise		= 0,
	Anticlockwise,
	Collinear
	} TrianglePointOrientation;


@interface AZBezierPoint : NSObject <NSCopying>

/*****************************************************************************\
|* Initialisation : Declare an empty point
\*****************************************************************************/
- (instancetype) init;
+ (instancetype) point;

/*****************************************************************************\
|* Initialisation : Declare a point at x=y
\*****************************************************************************/
- (instancetype) initAtXY:(double)value;
+ (instancetype) pointAtXY:(double)value;

/*****************************************************************************\
|* Initialisation : Declare a point at x,y
\*****************************************************************************/
- (instancetype) initAtX:(double)x y:(double)y;
+ (instancetype) pointAtX:(double)x y:(double)y;

/*****************************************************************************\
|* Initialisation : Declare a point
\*****************************************************************************/
- (instancetype) initWith:(NSPoint)p;
+ (instancetype) point:(NSPoint)p;



// MARK: Public class methods


/*****************************************************************************\
|* Method to see whether a value is pretty much zero. Uses DBL_EPSILON
\*****************************************************************************/
+ (BOOL) isZero:(double)d;
+ (BOOL) isZero:(double)d tolerance:(double)tolerance;

/*****************************************************************************\
|* Returns greater than zero if three given points are clockwise. Returns
|* less than zero if points are counter-clockwise. And returns zero if
| * points are collinear
\*****************************************************************************/
+ (double) turn:(AZBezierPoint *)p0
			and:(AZBezierPoint *)p1
			and:(AZBezierPoint *)p2;

/*****************************************************************************\
|* Determines orientation of triangle defined by three given points
\*****************************************************************************/
+ (TrianglePointOrientation) triangleOrientation:(AZBezierPoint *)p0
											 and:(AZBezierPoint *)p1
											 and:(AZBezierPoint *)p2;

/*****************************************************************************\
|* Returns true if triangle defined by three given points is clockwise.
|* Returns false if triangle is counter-clockwise or if points are
|* collinear
\*****************************************************************************/
+ (BOOL) triangleClockwise:(AZBezierPoint *)p0
					   and:(AZBezierPoint *)p1
					   and:(AZBezierPoint *)p2;


/*****************************************************************************\
|* Add two points
\*****************************************************************************/
+ (AZBezierPoint *) add:(AZBezierPoint *)p1 to:(AZBezierPoint *)p2;

/*****************************************************************************\
|* Subtract one point from another
\*****************************************************************************/
+ (AZBezierPoint *) subtract:(AZBezierPoint *)p1 from:(AZBezierPoint *)p2;

/*****************************************************************************\
|* Scale a point
\*****************************************************************************/
+ (AZBezierPoint *) scale:(AZBezierPoint *)p1 by:(double)scale;

/*****************************************************************************\
|* Scale a point
\*****************************************************************************/
+ (AZBezierPoint *) multiply:(AZBezierPoint *)p1 by:(AZBezierPoint *)p2;

/*****************************************************************************\
|* Divide a point by another
\*****************************************************************************/
+ (AZBezierPoint *) divide:(AZBezierPoint *)p1 by:(AZBezierPoint *)p2;

/*****************************************************************************\
|* Negate a point
\*****************************************************************************/
+ (AZBezierPoint *) negate:(AZBezierPoint *)p1;


// MARK: Public methods

/*****************************************************************************\
|* Returns an NSPoint representation
\*****************************************************************************/
- (NSPoint) asPoint;

/*****************************************************************************\
|* Return a linear interpolation from this point to another, using parameter
|* t which must range from 0..1 inclusive
\*****************************************************************************/
- (AZBezierPoint *)lerpTo:(AZBezierPoint *)other by:(double)t;

/*****************************************************************************\
|* Returns whether a point is equal to another one, within a tolerance, if the
|* single-argument version is called, a tolerance of DBL_EPSILON is used
\*****************************************************************************/
- (BOOL) isEqual:(AZBezierPoint *)p;
- (BOOL) isEqual:(AZBezierPoint *)p tolerance:(double)tolerance;

/*****************************************************************************\
|* Returns distance from this point to another point
\*****************************************************************************/
- (double) distanceTo:(AZBezierPoint *)other;

/*****************************************************************************\
|* Returns squared distance from this point to another point
\*****************************************************************************/
- (double) distanceToSquared:(AZBezierPoint *)other;

/*****************************************************************************\
|* Returns length of vector defined by X and Y components of this point
\*****************************************************************************/
- (double) length;

/*****************************************************************************\
|* Returns squared length of vector defined by X and Y components of this point
\*****************************************************************************/
- (double) lengthSquared;

/*****************************************************************************\
|* Returns normalized version of this vector. If this vector has length of
|* zero, vector with both components set to zero will be returned
\*****************************************************************************/
- (AZBezierPoint *) unitVector;

/*****************************************************************************\
|* Returns vector which has direction perpendicular to the direction of
|* this vector
\*****************************************************************************/
- (AZBezierPoint *) normalVector;

/*****************************************************************************\
|* Returns vector which has direction perpendicular to the direction of
|* this vector, vector is normalised
\*****************************************************************************/
- (AZBezierPoint *) unitNormalVector;

/*****************************************************************************\
|* Returns cross product of two 2D vectors (this × point).
|*
|* Since both 2D vectors lie on the same XY plane, the only meaningful
|* return value is Z component of cross product. This method returns that
|* and does not calculate anything else.
\*****************************************************************************/
- (double) cross:(AZBezierPoint *)other;

/*****************************************************************************\
|* Returns dot product of this vector and a given vector
\*****************************************************************************/
- (double) dot:(AZBezierPoint *)other;

/*****************************************************************************\
|* Returns vector created by rotating this vector 90 degrees counter-clockwise
\*****************************************************************************/
- (AZBezierPoint *) rotated90CCW;

/*****************************************************************************\
|* Add to this point
\*****************************************************************************/
- (AZBezierPoint *) add:(AZBezierPoint *)p1;

/*****************************************************************************\
|* Subtract a point from this one
\*****************************************************************************/
- (AZBezierPoint *) subtract:(AZBezierPoint *)p1;

/*****************************************************************************\
|* Scale this point
\*****************************************************************************/
- (AZBezierPoint *) scaleXY:(double)scale;

/*****************************************************************************\
|* Scale this point
\*****************************************************************************/
- (AZBezierPoint *) multiplyBy:(AZBezierPoint *)p1;

/*****************************************************************************\
|* Divide this point by another
\*****************************************************************************/
- (AZBezierPoint *) divideBy:(AZBezierPoint *)p1;

/*****************************************************************************\
|* Negate this point
\*****************************************************************************/
- (AZBezierPoint *) negate;



/*****************************************************************************\
|* Properties
\*****************************************************************************/
@property (assign, nonatomic) double								x;
@property (assign, nonatomic) double								y;
@end

NS_ASSUME_NONNULL_END
