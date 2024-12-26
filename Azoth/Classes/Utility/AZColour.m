//
//  AZColour.m
//  Azoth
//
//  Created by Simon Gornall on 12/12/24.
//

#import "AZColour.h"

@implementation AZColour

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithByteR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	if (self = [super init])
		{
		_r = r / 255.f;
		_g = g / 255.f;
		_b = b / 255.f;
		_a = a / 255.f;
		}
	return self;
	}

- (instancetype) initWithR:(float)r g:(float)g b:(float)b a:(float)a
	{
	if (self = [super init])
		{
		_r = r;
		_g = g;
		_b = b;
		_a = a;
		}
	return self;
	}

+ (AZColour *) colourWithByteR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a
	{
	return [[AZColour alloc] initWithByteR:r g:g b:b a:a];
	}

+ (AZColour *) colourWithR:(float)r g:(float)g b:(float)b a:(float)a
	{
	return [[AZColour alloc] initWithR:r g:g b:b a:a];
	}

/*****************************************************************************\
|* Predefined colours : red
\*****************************************************************************/
+ (AZColour *) redColour
	{
	static AZColour *colour = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		colour = [[AZColour alloc] initWithR:1.f g:0.f b:0.f a:1.f];
		});
	return colour;
	}

/*****************************************************************************\
|* Predefined colours : green
\*****************************************************************************/
+ (AZColour *) greenColour
	{
	static AZColour *colour = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		colour = [[AZColour alloc] initWithR:0.f g:1.f b:0.f a:1.f];
		});
	return colour;
	}

/*****************************************************************************\
|* Predefined colours : blue
\*****************************************************************************/
+ (AZColour *) blueColour
	{
	static AZColour *colour = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		colour = [[AZColour alloc] initWithR:0.f g:0.f b:1.f a:1.f];
		});
	return colour;
	}

/*****************************************************************************\
|* Predefined colours : black
\*****************************************************************************/
+ (AZColour *) blackColour
	{
	static AZColour *colour = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		colour = [[AZColour alloc] initWithR:0.f g:0.f b:0.f a:1.f];
		});
	return colour;
	}

/*****************************************************************************\
|* Predefined colours : white
\*****************************************************************************/
+ (AZColour *) whiteColour
	{
	static AZColour *colour = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		colour = [[AZColour alloc] initWithR:1.f g:1.f b:1.f a:1.f];
		});
	return colour;
	}

/*****************************************************************************\
|* Predefined colours : light grey
\*****************************************************************************/
+ (AZColour *) grey25Colour
	{
	static AZColour *colour = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		colour = [[AZColour alloc] initWithR:0.25f g:0.25f b:0.25f a:1.f];
		});
	return colour;
	}

/*****************************************************************************\
|* Predefined colours : grey
\*****************************************************************************/
+ (AZColour *) grey50Colour
	{
	static AZColour *colour = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		colour = [[AZColour alloc] initWithR:0.5f g:0.5f b:0.5f a:1.f];
		});
	return colour;
	}

/*****************************************************************************\
|* Predefined colours : dark grey
\*****************************************************************************/
+ (AZColour *) grey75Colour
	{
	static AZColour *colour = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		colour = [[AZColour alloc] initWithR:0.75f g:0.75f b:0.75f a:1.f];
		});
	return colour;
	}

/*****************************************************************************\
|* Predefined colours : magenta
\*****************************************************************************/
+ (AZColour *) magentaColour
	{
	static AZColour *colour = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		colour = [[AZColour alloc] initWithR:1.f g:0.f b:1.f a:1.f];
		});
	return colour;
	}

/*****************************************************************************\
|* Predefined colours : yellow
\*****************************************************************************/
+ (AZColour *) yellowColour
	{
	static AZColour *colour = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		colour = [[AZColour alloc] initWithR:1.f g:1.f b:0.f a:1.f];
		});
	return colour;
	}

/*****************************************************************************\
|* Predefined colours : brown
\*****************************************************************************/
+ (AZColour *) brownColour
	{
	static AZColour *colour = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		colour = [[AZColour alloc] initWithR:0.6f g:0.4f b:0.2f a:1.f];
		});
	return colour;
	}

/*****************************************************************************\
|* Predefined colours : cyan
\*****************************************************************************/
+ (AZColour *) cyanColour
	{
	static AZColour *colour = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		colour = [[AZColour alloc] initWithR:0.f g:1.f b:1.f a:1.f];
		});
	return colour;
	}

/*****************************************************************************\
|* Predefined colours : orange
\*****************************************************************************/
+ (AZColour *) orangeColour
	{
	static AZColour *colour = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		colour = [[AZColour alloc] initWithR:1.f g:0.5f b:0.f a:1.f];
		});
	return colour;
	}

/*****************************************************************************\
|* Predefined colours : purple
\*****************************************************************************/
+ (AZColour *) purpleColour
	{
	static AZColour *colour = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		colour = [[AZColour alloc] initWithR:0.5f g:0.f b:0.5f a:1.f];
		});
	return colour;
	}

/*****************************************************************************\
|* Predefined colours : clear
\*****************************************************************************/
+ (AZColour *) clearColour
	{
	static AZColour *colour = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		colour = [[AZColour alloc] initWithR:0.f g:0.f b:0.f a:0.f];
		});
	return colour;
	}


/*****************************************************************************\
|* Predefined colours : 'control' colour
\*****************************************************************************/
+ (AZColour *) controlColour
	{
	static AZColour *colour = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		colour = [[AZColour alloc] initWithR:.67f g:.67f b:.67f a:1.f];
		});
	return colour;
	}

/*****************************************************************************\
|* Predefined colours : 'control' background colour
\*****************************************************************************/
+ (AZColour *) controlBackgroundColour
	{
	static AZColour *colour = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		colour = [[AZColour alloc] initWithR:.95f g:.95f b:.95f a:1.f];
		});
	return colour;
	}

/*****************************************************************************\
|* Predefined colours : 'grid' colour
\*****************************************************************************/
+ (AZColour *) gridColour
	{
	static AZColour *colour = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken,
		^{
		colour = [[AZColour alloc] initWithR:.8f g:.8f b:.8f a:1.f];
		});
	return colour;
	}


// MARK: uint8_t accessors

/*****************************************************************************\
|* get the red component as a value between 0 and 255
\*****************************************************************************/
- (uint8_t) red
	{
	return (uint8_t)(255.f * _r);
	}

/*****************************************************************************\
|* get the green component as a value between 0 and 255
\*****************************************************************************/
- (uint8_t) green
	{
	return (uint8_t)(255.f * _g);
	}

/*****************************************************************************\
|* get the blue component as a value between 0 and 255
\*****************************************************************************/
- (uint8_t) blue
	{
	return (uint8_t)(255.f * _b);
	}

/*****************************************************************************\
|* get the alpha component as a value between 0 and 255
\*****************************************************************************/
- (uint8_t) alpha
	{
	return (uint8_t)(255.f * _a);
	}

// MARK: NSCopying

- (nonnull id)copyWithZone:(nullable NSZone *)zone
	{
	return [AZColour colourWithR:_r g:_g b:_b a:_a];
	}

@end
