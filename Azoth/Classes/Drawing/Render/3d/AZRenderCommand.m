//
//  AZRenderCommand.m
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import "AZRenderCommand.h"

@implementation AZRenderCommand

/*****************************************************************************\
|* Reset everything
\*****************************************************************************/
- (void) zero
	{
	_command 		= AZRenderCmdNoOp;
	_first			= 0;
	_rect			= (NSRect){0.f, 0.f, 0.f, 0.f};
	_enabled		= NO;
	_count			= 0;
	_colourScale	= 0.f;
	_colour			= (SDL_FColor){0.f, 0.f, 0.f, 0.f};
	_blendMode		= SDL_BLENDMODE_NONE;
	_texture		= nil;
	_addressMode	= AZTextureAddressAuto;
	}

@end
