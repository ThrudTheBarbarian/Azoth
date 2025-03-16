//
//  AZPoint.h
//  Azoth
//
//  Created by Simon Gornall on 3/15/25.
//

#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>

#define FUZZY_EQUAL(x,y)	(SDL_fabs((x)-(y)) < DBL_EPSILON)
#define FUZZY_ZERO(x)		(SDL_fabs(x) < DBL_EPSILON)

NS_ASSUME_NONNULL_BEGIN

typedef enum
	{
	Clockwise		= 0,
	Anticlockwise,
	Collinear
	} TrianglePointOrientation;


@interface AZPoint : NSObject

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
+ (double) turn:(AZPoint *)p0 and:(AZPoint *)p1 and:(AZPoint *)p2;

/*****************************************************************************\
|* Determines orientation of triangle defined by three given points
\*****************************************************************************/
+ (TrianglePointOrientation) triangleOrientation:(AZPoint *)p0
											 and:(AZPoint *)p1
											 and:(AZPoint *)p2;

/*****************************************************************************\
|* Returns true if triangle defined by three given points is clockwise.
|* Returns false if triangle is counter-clockwise or if points are
|* collinear
\*****************************************************************************/
+ (BOOL) triangleClockwise:(AZPoint *)p0 and:(AZPoint *)p1 and:(AZPoint *)p2;


/*****************************************************************************\
|* Add two points
\*****************************************************************************/
+ (AZPoint *) add:(AZPoint *)p1 to:(AZPoint *)p2;

/*****************************************************************************\
|* Subtract one point from another
\*****************************************************************************/
+ (AZPoint *) subtract:(AZPoint *)p1 from:(AZPoint *)p2;

/*****************************************************************************\
|* Scale a point
\*****************************************************************************/
+ (AZPoint *) scale:(AZPoint *)p1 by:(double)scale;

/*****************************************************************************\
|* Scale a point
\*****************************************************************************/
+ (AZPoint *) multiply:(AZPoint *)p1 by:(AZPoint *)p2;

/*****************************************************************************\
|* Divide a point by another
\*****************************************************************************/
+ (AZPoint *) divide:(AZPoint *)p1 by:(AZPoint *)p2;

/*****************************************************************************\
|* Negate a point
\*****************************************************************************/
+ (AZPoint *) negate:(AZPoint *)p1;


// MARK: Public methods

/*****************************************************************************\
|* Returns an NSPoint representation
\*****************************************************************************/
- (NSPoint) asPoint;

/*****************************************************************************\
|* Return a linear interpolation from this point to another, using parameter
|* t which must range from 0..1 inclusive
\*****************************************************************************/
- (AZPoint *)lerpTo:(AZPoint *)other by:(double)t;

/*****************************************************************************\
|* Returns whether a point is equal to another one, within a tolerance, if the
|* single-argument version is called, a tolerance of DBL_EPSILON is used
\*****************************************************************************/
- (BOOL) isEqual:(AZPoint *)p;
- (BOOL) isEqual:(AZPoint *)p tolerance:(double)tolerance;

/*****************************************************************************\
|* Returns distance from this point to another point
\*****************************************************************************/
- (double) distanceTo:(AZPoint *)other;

/*****************************************************************************\
|* Returns squared distance from this point to another point
\*****************************************************************************/
- (double) distanceToSquared:(AZPoint *)other;

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
- (AZPoint *) unitVector;

/*****************************************************************************\
|* Returns vector which has direction perpendicular to the direction of
|* this vector
\*****************************************************************************/
- (AZPoint *) normalVector;

/*****************************************************************************\
|* Returns vector which has direction perpendicular to the direction of
|* this vector, vector is normalised
\*****************************************************************************/
- (AZPoint *) unitNormalVector;

/*****************************************************************************\
|* Returns cross product of two 2D vectors (this × point).
|*
|* Since both 2D vectors lie on the same XY plane, the only meaningful
|* return value is Z component of cross product. This method returns that
|* and does not calculate anything else.
\*****************************************************************************/
- (double) cross:(AZPoint *)other;

/*****************************************************************************\
|* Returns dot product of this vector and a given vector
\*****************************************************************************/
- (double) dot:(AZPoint *)other;

/*****************************************************************************\
|* Returns vector created by rotating this vector 90 degrees counter-clockwise
\*****************************************************************************/
- (AZPoint *) rotated90CCW;

/*****************************************************************************\
|* Add to this point
\*****************************************************************************/
- (void) add:(AZPoint *)p1;

/*****************************************************************************\
|* Subtract a point from this one
\*****************************************************************************/
- (void) subtract:(AZPoint *)p1;

/*****************************************************************************\
|* Scale this point
\*****************************************************************************/
- (void) scaleBy:(double)scale;

/*****************************************************************************\
|* Scale this point
\*****************************************************************************/
- (void) multiplyBy:(AZPoint *)p1;

/*****************************************************************************\
|* Divide this point by another
\*****************************************************************************/
- (void) divideBy:(AZPoint *)p1;

/*****************************************************************************\
|* Negate this point
\*****************************************************************************/
- (void) negate;



/*****************************************************************************\
|* Properties
\*****************************************************************************/
@property (assign, nonatomic) double								x;
@property (assign, nonatomic) double								y;
@end

NS_ASSUME_NONNULL_END
