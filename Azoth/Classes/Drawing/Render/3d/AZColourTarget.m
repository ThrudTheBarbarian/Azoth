//
//  AZColourTarget.m
//  sdl3_gpu
//
//  Created by Simon Gornall on 1/13/25.
//

#import "AZ3dUtils.h"
#import "AZColourTarget.h"
#import "AZRenderer3d.h"

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


/*****************************************************************************\
|* Use the renderer to convert a blend mode to a target-blendstate
\*****************************************************************************/
- (void) updataBlendStateWith:(AZRenderer3d *)azr andBlendMode:(SDL_BlendMode)bm
	{
	SDL_BlendFactor factor;
	SDL_BlendOperation op;

	_blendState.enable_blend = (bm != 0);
    _blendState.color_write_mask = 0xF;

	op 								  = [azr blendModeAlphaOperation:bm];
    _blendState.alpha_blend_op 		  = AZConvertBlendOperation(op);

	factor							  = [azr blendModeDstAlphaFactor:bm];
    _blendState.dst_alpha_blendfactor = AZConvertBlendFactor(factor);

	factor							  = [azr blendModeSrcAlphaFactor:bm];
    _blendState.src_alpha_blendfactor = AZConvertBlendFactor(factor);

	op 								  = [azr blendModeColourOperation:bm];
    _blendState.alpha_blend_op 		  = AZConvertBlendOperation(op);

	factor							  = [azr blendModeDstColourFactor:bm];
    _blendState.dst_color_blendfactor = AZConvertBlendFactor(factor);

	factor							  = [azr blendModeSrcColourFactor:bm];
    _blendState.src_color_blendfactor = AZConvertBlendFactor(factor);
	}

@end
