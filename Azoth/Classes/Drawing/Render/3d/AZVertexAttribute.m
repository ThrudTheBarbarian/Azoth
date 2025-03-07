//
//  AZVertexAttribute.m
//  sdl3_gpu
//
//  Created by ThrudTheBarbarian on 1/13/25.
//

#import "AZVertexAttribute.h"

@implementation AZVertexAttribute


/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithLocation:(uint32_t)location
					   bufferSlot:(uint32_t)bufferSlot
						   format:(uint32_t)format
						   offset:(uint32_t)offset
	{
	if (self = [super init])
		{
		_location 	= location;
		_bufferSlot = bufferSlot;
		_format 	= format;
		_offset 	= offset;
		}
	return self;
	}

+ (instancetype) atLocation:(uint32_t)location
				 bufferSlot:(uint32_t)bufferSlot
					 format:(uint32_t)format
					 offset:(uint32_t)offset;
	{
	return [[AZVertexAttribute alloc] initWithLocation:location
											bufferSlot:bufferSlot
												format:format
												offset:offset];
	}


@end
