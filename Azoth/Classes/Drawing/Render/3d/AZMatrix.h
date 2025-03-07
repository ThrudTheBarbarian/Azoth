//
//  AZMatrix.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/16/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct
	{
    float x;
    float y;
	} Float2;

typedef struct
	{
    float x;
    float y;
    float z;
	} Float3;

typedef struct
	{
    float x;
    float y;
    float z;
    float w;
	} Float4;

typedef struct
	{
    union
		{
        struct
			{
            float _11, _12, _13, _14;
            float _21, _22, _23, _24;
            float _31, _32, _33, _34;
            float _41, _42, _43, _44;
			} v;
        float m[4][4];
		};
	} Float4x4;

@interface AZMatrix : NSObject

/*****************************************************************************\
|* Return an identity matrix
\*****************************************************************************/
+ (Float4x4) identity;

/*****************************************************************************\
|* Multiply 2 matrices and return the result
\*****************************************************************************/
+ (Float4x4) multiply:(Float4x4)m1 by:(Float4x4)m2;

/*****************************************************************************\
|* Return a scaling matrix
\*****************************************************************************/
+ (Float4x4) scaleByX:(float)x y:(float)y z:(float)z;

/*****************************************************************************\
|* Return a translation matrix
\*****************************************************************************/
+ (Float4x4) translatebyX:(float)x y:(float)y z:(float)z;

/*****************************************************************************\
|* Return a rotation matrix about X
\*****************************************************************************/
+ (Float4x4) rotateAboutX:(float)r;

/*****************************************************************************\
|* Return a rotation matrix about Y
\*****************************************************************************/
+ (Float4x4) rotateAboutY:(float)r;

/*****************************************************************************\
|* Return a rotation matrix about Z
\*****************************************************************************/
+ (Float4x4) rotateAboutZ:(float)r;

@end

NS_ASSUME_NONNULL_END
