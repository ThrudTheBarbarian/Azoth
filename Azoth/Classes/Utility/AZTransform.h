//
//  AZTransform.h
//  Azoth
//
//  Created by Simon Gornall on 12/23/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZTransform : NSObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithA:(float)a
						 b:(float)b
						 c:(float)c
						 d:(float)d
					    tx:(float)tx
					    ty:(float)ty;

+ (AZTransform *) transformWithA:(float)a
							   b:(float)b
							   c:(float)c
							   d:(float)d
							   tx:(float)tx
							   ty:(float)ty;

+ (AZTransform *) identity;

+ (AZTransform *) rotation:(float)radians;

+ (AZTransform *) scaleX:(float)sx y:(float)sy;

+ (AZTransform *) translateX:(float)tx y:(float)ty;

/*****************************************************************************\
|* Operation: append a transform onto this one and return the result
\*****************************************************************************/
- (AZTransform *) concat:(AZTransform *)other;

/*****************************************************************************\
|* Operation: return the result of inverting this transform
\*****************************************************************************/
- (AZTransform *) invert;

/*****************************************************************************\
|* Operation: return a rotation of this transform
\*****************************************************************************/
- (AZTransform *) rotate:(float)radians;

/*****************************************************************************\
|* Operation: return a scale of this transform
\*****************************************************************************/
- (AZTransform *) scaleX:(float)sx y:(float)sy;

/*****************************************************************************\
|* Operation: return a translation of this transform
\*****************************************************************************/
- (AZTransform *) translateX:(float)tx y:(float)ty;

/*****************************************************************************\
|* Operation: transform a point
\*****************************************************************************/
- (NSPoint) applyToPoint:(NSPoint)pt;

/*****************************************************************************\
|* Operation: transform a size
\*****************************************************************************/
- (NSSize) applyToSize:(NSSize)size;

// The 6 parameters of the affine transform matrix
@property(assign, nonatomic) float										a;
@property(assign, nonatomic) float										b;
@property(assign, nonatomic) float										c;
@property(assign, nonatomic) float										d;
@property(assign, nonatomic) float										tx;
@property(assign, nonatomic) float										ty;

// Returns true if this is the identity transform
@property(assign, nonatomic) BOOL								isIdentity;
@end

NS_ASSUME_NONNULL_END
