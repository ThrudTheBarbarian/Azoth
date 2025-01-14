//
//  AZRenderer.m
//  Azoth
//
//  Created by Simon Gornall on 1/13/25.
//

#import <SDL3/SDL.h>

#import "AZRenderer.h"
#import "AZRenderer2d.h"
#import "AZRenderer3d.h"

static id<AZRenderer> _renderer = nil;

@implementation AZRenderer
/*****************************************************************************\
|* Return a renderer of the requested type
\*****************************************************************************/
+ (BOOL) makeDefaultRendererOfType:(AZRendererType)type
	{
	BOOL ok = YES;

	switch (type)
		{
		case AZRendererType2d:
			_renderer = AZRenderer2d.renderer;
			break;

		case AZRendererType3d:
			//_renderer = AZRenderer3d.renderer;
			break;
			
		default:
			SDL_Log("Unknown renderer-type %d requested", type);
			ok = NO;
			break;
		}

	return ok;
	}

/*****************************************************************************\
|* Return the renderer we created as default
\*****************************************************************************/
+ (id<AZRenderer>)renderer
	{
	return _renderer;
	}


@end
