//
//  AZBezierPath.h
//  Azoth
//
//  Created by Simon Gornall on 3/16/25.
//  Based on git@github.com:aurimasg/cubic-bezier-offsetter.git
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AZBezierPoint;
@class AZBezierLine;

@interface AZBezierPath (Offset)

/*****************************************************************************\
|* Add a line to the path
\*****************************************************************************/
- (void) addLineFrom:(AZBezierPoint *)p0 to:(AZBezierPoint *)p1;

/*****************************************************************************\
|* Add a cubic curve to the path
\*****************************************************************************/
- (void) addCubicFrom:(AZBezierPoint *)p0
			 control0:(AZBezierPoint *)c0
			 control1:(AZBezierPoint *)c1
				   to:(AZBezierPoint *)p1;


/*****************************************************************************\
|* Return an element by index
\*****************************************************************************/
- (AZBezierPath *) elementAt:(NSInteger)idx;

/*****************************************************************************\
|* Clear out all the entries in this path, make it re-usable
\*****************************************************************************/
- (void) reset;

/*****************************************************************************\
|* Create an offset curve from this one
|*
|* - if offset == 0, then the same curve will be returned, otherwise larger
|*   values mean larger offsets, offset can be -ve
|* - lower maxError means better precision and more output segments, the
|*   reverse is also true
\*****************************************************************************/
- (nullable AZBezierPath *) curveWithOffset:(double)offset
								   maxError:(double)maxError;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Return the first point, or nil if none
@property(strong, nonatomic, readonly, nullable) AZBezierPoint *	firstPoint;

// Return the first point, or nil if none
@property(strong, nonatomic, readonly, nullable) AZBezierPoint *	lastPoint;

// Return the tangent at the start of the path
@property(strong, nonatomic, readonly, nullable) AZBezierLine *		startTangent;

// Return the tangent at the end of the path
@property(strong, nonatomic, readonly, nullable) AZBezierLine *		endTangent;

// Return the number of segments
@property(assign, nonatomic, readonly) NSInteger					segmentCount;


@end

NS_ASSUME_NONNULL_END
