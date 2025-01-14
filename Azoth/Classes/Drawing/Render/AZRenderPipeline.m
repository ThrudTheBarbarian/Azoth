//
//  AZRenderPipeline.m
//  sdl3_gpu
//
//  Created by Simon Gornall on 1/13/25.
//

#import "AZRenderPipeline.h"

@implementation AZRenderPipeline
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
		_vertexBuffers 		= NSMutableArray.new;
		_vertexAttributes	= NSMutableArray.new;
		}
	return self;
	}


/*****************************************************************************\
|* Add a vertex buffer
\*****************************************************************************/
- (void) addVertexBuffer:(AZVertexBuffer *)buffer
	{
	[_vertexBuffers addObject:buffer];
	}

/*****************************************************************************\
|* Add a vertex attribute
\*****************************************************************************/
- (void) addVertexAttribute:(AZVertexAttribute *)attribute;
	{
	[_vertexAttributes addObject:attribute];
	}

@end
