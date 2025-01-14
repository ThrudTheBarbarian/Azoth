//
//  AZColourTarget.m
//  sdl3_gpu
//
//  Created by Simon Gornall on 1/13/25.
//

#import "AZColourTarget.h"

@implementation AZColourTarget

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
+ (AZColourTarget*) targetWithFormat:(SDL_GPUTextureFormat)format
	{
	AZColourTarget *target = AZColourTarget.new;
	target.format = format;
	return target;
	}

@end
