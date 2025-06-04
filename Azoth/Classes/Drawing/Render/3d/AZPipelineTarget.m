//
//  AZPipelineTarget.m
//  sdl3_gpu
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import "AZColourTarget.h"
#import "AZPipelineTarget.h"
#import "AZTypes.h"

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZPipelineTarget()

// Number of slots in the description storage
@property(assign, nonatomic) int								slots;

// The actual description storage
@property(assign, nonatomic) SDL_GPUColorTargetDescription *	ctds;

@end



@implementation AZPipelineTarget
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
		_colourTargets 			= NSMutableArray.new;
		_slots					= 0;
		_ctds					= NULL;
		_hasDepthStencilTarget	= NO;
		_depthStencilTarget		= SDL_GPU_TEXTUREFORMAT_INVALID;
		}
	return self;
	}

/*****************************************************************************\
|* Tidy up on release
\*****************************************************************************/
- (void) dealloc
	{
	SAFELY_FREE(_ctds);
	}


/*****************************************************************************\
|* Add a colour target
\*****************************************************************************/
- (void) addColourTarget:(AZColourTarget *)colourTarget
	{
	[_colourTargets addObject:colourTarget];
	}

/*****************************************************************************\
|* Return the target info description
\*****************************************************************************/
- (SDL_GPUGraphicsPipelineTargetInfo) info
	{
	SDL_GPUGraphicsPipelineTargetInfo info;

	if (_slots < _colourTargets.count)
		{
		SAFELY_FREE(_ctds);
		_slots 		= (int)_colourTargets.count;
		int size 	= sizeof(SDL_GPUColorTargetDescription);
		_ctds  		= (SDL_GPUColorTargetDescription *) malloc(_slots * size);
		}

	for (int i=0; i<_colourTargets.count; i++)
		{
		_ctds[i].format = _colourTargets[i].format;
		_ctds[i].blend_state = _colourTargets[i].blendState;
		}

	info.num_color_targets 			= (int)_colourTargets.count;
	info.color_target_descriptions	= _ctds;
	info.depth_stencil_format		= _depthStencilTarget;
	info.has_depth_stencil_target	= _hasDepthStencilTarget;

	return info;
	}


@end
