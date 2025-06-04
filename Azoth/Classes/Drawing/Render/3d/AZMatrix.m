//
//  AZMatrix.m
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <SDL3/SDL.h>

#import "AZMatrix.h"

static Float4x4 _zero = {0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0};

@implementation AZMatrix

/*****************************************************************************\
|* Return an identity matrix
\*****************************************************************************/
+ (Float4x4) identity
	{
    Float4x4 m 	= _zero;
    m.v._11 	= 1.0f;
    m.v._22 	= 1.0f;
    m.v._33 	= 1.0f;
    m.v._44 	= 1.0f;
    return m;
	}

/*****************************************************************************\
|* Multiply 2 matrices and return the result
\*****************************************************************************/
+ (Float4x4) multiply:(Float4x4)m1 by:(Float4x4)m2
	{
    Float4x4 m;
    m.v._11 = m1.v._11 * m2.v._11 + m1.v._12 * m2.v._21
			+ m1.v._13 * m2.v._31 + m1.v._14 * m2.v._41;
    m.v._12 = m1.v._11 * m2.v._12 + m1.v._12 * m2.v._22
			+ m1.v._13 * m2.v._32 + m1.v._14 * m2.v._42;
    m.v._13 = m1.v._11 * m2.v._13 + m1.v._12 * m2.v._23
			+ m1.v._13 * m2.v._33 + m1.v._14 * m2.v._43;
    m.v._14 = m1.v._11 * m2.v._14 + m1.v._12 * m2.v._24
			+ m1.v._13 * m2.v._34 + m1.v._14 * m2.v._44;
    m.v._21 = m1.v._21 * m2.v._11 + m1.v._22 * m2.v._21
			+ m1.v._23 * m2.v._31 + m1.v._24 * m2.v._41;
    m.v._22 = m1.v._21 * m2.v._12 + m1.v._22 * m2.v._22
			+ m1.v._23 * m2.v._32 + m1.v._24 * m2.v._42;
    m.v._23 = m1.v._21 * m2.v._13 + m1.v._22 * m2.v._23
			+ m1.v._23 * m2.v._33 + m1.v._24 * m2.v._43;
    m.v._24 = m1.v._21 * m2.v._14 + m1.v._22 * m2.v._24
			+ m1.v._23 * m2.v._34 + m1.v._24 * m2.v._44;
    m.v._31 = m1.v._31 * m2.v._11 + m1.v._32 * m2.v._21
			+ m1.v._33 * m2.v._31 + m1.v._34 * m2.v._41;
    m.v._32 = m1.v._31 * m2.v._12 + m1.v._32 * m2.v._22
			+ m1.v._33 * m2.v._32 + m1.v._34 * m2.v._42;
    m.v._33 = m1.v._31 * m2.v._13 + m1.v._32 * m2.v._23
			+ m1.v._33 * m2.v._33 + m1.v._34 * m2.v._43;
    m.v._34 = m1.v._31 * m2.v._14 + m1.v._32 * m2.v._24
			+ m1.v._33 * m2.v._34 + m1.v._34 * m2.v._44;
    m.v._41 = m1.v._41 * m2.v._11 + m1.v._42 * m2.v._21
			+ m1.v._43 * m2.v._31 + m1.v._44 * m2.v._41;
    m.v._42 = m1.v._41 * m2.v._12 + m1.v._42 * m2.v._22
			+ m1.v._43 * m2.v._32 + m1.v._44 * m2.v._42;
    m.v._43 = m1.v._41 * m2.v._13 + m1.v._42 * m2.v._23
			+ m1.v._43 * m2.v._33 + m1.v._44 * m2.v._43;
    m.v._44 = m1.v._41 * m2.v._14 + m1.v._42 * m2.v._24
			+ m1.v._43 * m2.v._34 + m1.v._44 * m2.v._44;
    return m;
	}

/*****************************************************************************\
|* Return a scaling matrix
\*****************************************************************************/
+ (Float4x4) scaleByX:(float)x y:(float)y z:(float)z
	{
    Float4x4 m 	= _zero;
    m.v._11 	= x;
    m.v._22 	= y;
    m.v._33 	= z;
    m.v._44 	= 1.0f;
    return m;
	}

/*****************************************************************************\
|* Return a translation matrix
\*****************************************************************************/
+ (Float4x4) translatebyX:(float)x y:(float)y z:(float)z
	{
    Float4x4 m 	= _zero;
    m.v._11 	= 1.0f;
    m.v._22 	= 1.0f;
    m.v._33 	= 1.0f;
    m.v._44 	= 1.0f;
    m.v._41 	= x;
    m.v._42 	= y;
    m.v._43 	= z;
    return m;
	}

/*****************************************************************************\
|* Return a rotation matrix about X
\*****************************************************************************/
+ (Float4x4) rotateAboutX:(float)r
	{
    Float4x4 m 	= _zero;
    float sinR 	= SDL_sinf(r);
    float cosR 	= SDL_cosf(r);
    m.v._11 	= 1.0f;
    m.v._22 	= cosR;
    m.v._23 	= sinR;
    m.v._32 	= -sinR;
    m.v._33 	= cosR;
    m.v._44 	= 1.0f;
    return m;
	}

/*****************************************************************************\
|* Return a rotation matrix about Y
\*****************************************************************************/
+ (Float4x4) rotateAboutY:(float)r
	{
    Float4x4 m 	= _zero;
    float sinR 	= SDL_sinf(r);
    float cosR 	= SDL_cosf(r);
    m.v._11 	= cosR;
    m.v._13 	= -sinR;
    m.v._22 	= 1.0f;
    m.v._31 	= sinR;
    m.v._33 	= cosR;
    m.v._44 	= 1.0f;
    return m;
	}

/*****************************************************************************\
|* Return a rotation matrix about Z
\*****************************************************************************/
+ (Float4x4) rotateAboutZ:(float)r
	{
    Float4x4 m 	= _zero;
    float sinR 	= SDL_sinf(r);
    float cosR 	= SDL_cosf(r);
    m.v._11 	= cosR;
    m.v._12 	= sinR;
    m.v._21 	= -sinR;
    m.v._22 	= cosR;
    m.v._33 	= 1.0f;
    m.v._44 	= 1.0f;
    return m;
	}


@end
