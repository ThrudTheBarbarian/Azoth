//
//  AZ3dUtils.c
//  Azoth
//
//  Created by Simon Gornall on 1/14/25.
//

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
