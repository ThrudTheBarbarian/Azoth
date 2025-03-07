//
//  AZ3dUtils.c
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/14/25.
//

#import <SDL3/SDL.h>

#include "AZ3dUtils.h"
#include "AZShader.h"

// Fetch a vertex shader with sanity tests
AZShader * AZVertexShader(AZShaders *shaders, AZVertexShaderID which)
	{
    SDL_assert((unsigned int)which < SDL_arraysize(shaders->vertShaders));
    AZShader *shader = shaders->vertShaders[which];
    SDL_assert(shader != NULL);
    return shader;
	}


// Fetch a fragment shader with sanity tests
AZShader * AZFragmentShader(AZShaders *shaders, AZFragmentShaderID which)
	{
    SDL_assert((unsigned int)which < SDL_arraysize(shaders->fragShaders));
    AZShader *shader = shaders->fragShaders[which];
    SDL_assert(shader != NULL);
    return shader;
	}

// Get the default colourspace for a format
SDL_Colorspace AZGetDefaultColorspaceForFormat(SDL_PixelFormat format)
	{
    if (SDL_ISPIXELFORMAT_FOURCC(format))
		{
        if (format == SDL_PIXELFORMAT_P010)
            return SDL_COLORSPACE_HDR10;
		return SDL_COLORSPACE_YUV_DEFAULT;
		}

	else if (SDL_ISPIXELFORMAT_FLOAT(format))
        return SDL_COLORSPACE_SRGB_LINEAR;

    else if (SDL_ISPIXELFORMAT_10BIT(format))
        return SDL_COLORSPACE_HDR10;

	return SDL_COLORSPACE_RGB_DEFAULT;
    }

// Bit of a fudge for the value for the white-point. Don't want to pull in
// too much from the SDL code, so it's either HDR or not.
float AZGetSurfaceSDRWhitePoint(SDL_Colorspace cs)
	{
    SDL_TransferCharacteristics transfer = SDL_COLORSPACETRANSFER(cs);

    if (transfer == SDL_TRANSFER_CHARACTERISTICS_LINEAR ||
        transfer == SDL_TRANSFER_CHARACTERISTICS_PQ)
        {
        if (transfer == SDL_TRANSFER_CHARACTERISTICS_PQ)
			{
            /* The older standards use an SDR white point of 100 nits.
             * ITU-R BT.2408-6 recommends using an SDR white point of 203 nits.
             * This is the default Chrome uses, and what a lot of game content
             * assumes, so we'll go with that.
             */
            const float DEFAULT_PQ_SDR_WHITE_POINT = 203.f;
            return DEFAULT_PQ_SDR_WHITE_POINT;
			}
		}
    return 1.f;
	}

// Same... Ignoring any props.
float AZGetSurfaceHDRHeadroom(SDL_Colorspace cs)
	{
    SDL_TransferCharacteristics transfer = SDL_COLORSPACETRANSFER(cs);

    if (transfer == SDL_TRANSFER_CHARACTERISTICS_LINEAR ||
        transfer == SDL_TRANSFER_CHARACTERISTICS_PQ)
		{
        return 1.f;
        }

    return 0.f;
	}

void AZDetectPalette(const SDL_Palette *pal, BOOL *isOpaque, BOOL *hasAlpha)
	{
	BOOL allOpaque = YES;
	for (int i = 0; i < pal->ncolors; i++)
		{
		Uint8 alphaValue = pal->colors[i].a;
		if (alphaValue != SDL_ALPHA_OPAQUE)
			{
			allOpaque = NO;
			break;
			}
		}

	if (allOpaque)
		{
		// Palette is opaque, with an alpha channel
		*isOpaque 	= YES;
		*hasAlpha 	= YES;
		return;
		}

	BOOL allTransparent = YES;
	for (int i = 0; i < pal->ncolors; i++)
		{
		Uint8 alphaValue = pal->colors[i].a;
		if (alphaValue != SDL_ALPHA_TRANSPARENT)
			{
			allTransparent = NO;
			break;
			}
		}

	if (allTransparent)
		{
		// Palette is opaque, without an alpha channel
		*isOpaque = YES;
		*hasAlpha = NO;
		return;
		}

    // Palette has alpha values
    *isOpaque = NO;
    *hasAlpha = YES;
	}
