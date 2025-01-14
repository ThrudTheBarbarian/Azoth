//
//  AZRenderPipeline.h
//  sdl3_gpu
//
//  Created by Simon Gornall on 1/13/25.
//

#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>

NS_ASSUME_NONNULL_BEGIN

@class AZShader;
@class AZVertexAttribute;
@class AZVertexBuffer;

@interface AZRenderPipeline : NSObject

/*****************************************************************************\
|* Add a vertex buffer
\*****************************************************************************/
- (void) addVertexBuffer:(AZVertexBuffer *)buffer;

/*****************************************************************************\
|* Add a vertex attribute
\*****************************************************************************/
- (void) addVertexAttribute:(AZVertexAttribute *)attribute;



/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The list of vertex buffers
@property(strong, nonatomic)
NSMutableArray<AZVertexBuffer *> *							vertexBuffers;

// The list of vertex attributes
@property(strong, nonatomic)
NSMutableArray<AZVertexAttribute *> *						vertexAttributes;

// The fragment shader, if there is one
@property(strong, nonatomic, nullable) AZShader *			fragment;

// The vertex shader, if there is one
@property(strong, nonatomic, nullable) AZShader *			vertex;

// The primitive type used in the pipeline.
@property(assign, nonatomic) SDL_GPUPrimitiveType			primitiveType;
@end

NS_ASSUME_NONNULL_END
