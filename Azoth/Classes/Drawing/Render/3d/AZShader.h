//
//  AZShader.h
//  sdl3_gpu
//
//  Created by ThrudTheBarbarian on 1/13/25.
//
// Shader interface to Azoth.

#import <Foundation/Foundation.h>

#import <Azoth/AZRenderer.h>

NS_ASSUME_NONNULL_BEGIN


@interface AZShader : NSObject
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithRenderer:(id<AZRenderer>)renderer
							 name:(NSString *)name
						 samplers:(int)numSamplers
				   uniformBuffers:(int)numUniformBuffers
				   storageBuffers:(int)numStorageBuffers
				  storageTextures:(int)numStorageTextures;

+ (instancetype) shaderWithRenderer:(id<AZRenderer>)renderer
							   name:(NSString *)name;

+ (instancetype) shaderWithRenderer:(id<AZRenderer>)renderer
							   name:(NSString *)name
						   samplers:(int)numSamplers;

+ (instancetype) shaderWithRenderer:(id<AZRenderer>)renderer
							   name:(NSString *)name
						   samplers:(int)numSamplers
				     uniformBuffers:(int)numUniformBuffers;

+ (instancetype) shaderWithRenderer:(id<AZRenderer>)renderer
							   name:(NSString *)name
						   samplers:(int)numSamplers
				     uniformBuffers:(int)numUniformBuffers
				     storageBuffers:(int)numStorageBuffers;

+ (instancetype) shaderWithRenderer:(id<AZRenderer>)renderer
							   name:(NSString *)name
						   samplers:(int)numSamplers
				     uniformBuffers:(int)numUniformBuffers
				     storageBuffers:(int)numStorageBuffers
				    storageTextures:(int)numStorageTextures;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The actual shader
@property(assign, nonatomic) SDL_GPUShader *						shader;

@end

NS_ASSUME_NONNULL_END
