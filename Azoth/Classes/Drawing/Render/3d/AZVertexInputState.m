//
//  AZVertexInputState.m
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import "AZTypes.h"
#import "AZVertexAttribute.h"
#import "AZVertexBuffer.h"
#import "AZVertexInputState.h"

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZVertexInputState()

// Number of attribute-slots in the description storage
@property(assign, nonatomic) int								aslots;

// Number of buffer-slots in the description storage
@property(assign, nonatomic) int								bslots;

// The attribute description storage
@property(assign, nonatomic) SDL_GPUVertexAttribute *			vads;

// The buffer description storage
@property(assign, nonatomic) SDL_GPUVertexBufferDescription *	vbds;

@end

@implementation AZVertexInputState

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
		_vertexBuffers 		= NSMutableArray.new;
		_vertexAttributes	= NSMutableArray.new;
		_vads				= NULL;
		_vbds				= NULL;
		_aslots				= 0;
		_bslots				= 0;
		}
	return self;
	}

/*****************************************************************************\
|* Tidy up on release
\*****************************************************************************/
- (void) dealloc
	{
	SAFELY_FREE(_vads);
	SAFELY_FREE(_vbds);
	}

/*****************************************************************************\
|* Add a vertex buffer
\*****************************************************************************/
- (void) addBuffer:(AZVertexBuffer *)buffer
	{
	[_vertexBuffers addObject:buffer];
	}

/*****************************************************************************\
|* Add a vertex attribute
\*****************************************************************************/
- (void) addAttribute:(AZVertexAttribute *)attribute;
	{
	[_vertexAttributes addObject:attribute];
	}

/*****************************************************************************\
|* Compute the input state
\*****************************************************************************/
- (SDL_GPUVertexInputState) state
	{
	SDL_GPUVertexInputState state;

	/*************************************************************************\
	|* Do the attributes
	\*************************************************************************/
	state.num_vertex_attributes = (int)_vertexAttributes.count;

	if (_aslots < _vertexAttributes.count)
		{
		SAFELY_FREE(_vads);
		_aslots 	= (int)_vertexAttributes.count;
		int size 	= sizeof(SDL_GPUVertexAttribute);
		_vads  		= (SDL_GPUVertexAttribute *) malloc(_aslots * size);
		}

	for (int i=0; i<state.num_vertex_attributes; i++)
		{
		_vads[i].location 		= _vertexAttributes[i].location;
		_vads[i].offset			= _vertexAttributes[i].offset;
		_vads[i].format 		= _vertexAttributes[i].format;
		_vads[i].buffer_slot	= _vertexAttributes[i].bufferSlot;
		}
	state.vertex_attributes = _vads;

	/*************************************************************************\
	|* Do the buffers
	\*************************************************************************/
	state.num_vertex_buffers = (int)_vertexBuffers.count;

	if (_bslots < _vertexBuffers.count)
		{
		SAFELY_FREE(_vbds);
		_bslots 	= (int)_vertexBuffers.count;
		int size 	= sizeof(SDL_GPUVertexBufferDescription);
		_vbds  		= (SDL_GPUVertexBufferDescription *) malloc(_bslots * size);
		}

	for (int i=0; i<state.num_vertex_buffers; i++)
		_vbds[i] = _vertexBuffers[i].bufferDescription;
	state.vertex_buffer_descriptions = _vbds;

	return state;
	}


@end
