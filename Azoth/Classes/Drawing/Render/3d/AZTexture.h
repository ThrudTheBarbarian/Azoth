//
//  AZTexture.h
//  Azoth
//
//  Created by Simon Gornall on 1/14/25.
//
// Only support RGBA8888

#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AZRenderer;

@interface AZTexture : NSObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initFor:(id<AZRenderer>)renderer
			   withIndex:(NSNumber *)index
				    size:(NSSize)size
				   usage:(SDL_GPUTextureUsageFlags)flags;

+ (instancetype) textureFor:(id<AZRenderer>)renderer
				  withIndex:(NSNumber *)index
					   size:(NSSize)size
					  usage:(SDL_GPUTextureUsageFlags)flags;


/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Size of the texture
@property(assign, nonatomic, readonly) NSSize						size;

// Flags for the texture
@property(assign, nonatomic, readonly) SDL_GPUTextureUsageFlags		flags;

// Index for this texture in pool
@property(strong, nonatomic, readonly) NSNumber *					index;

// The actual texture pointer for SDL
@property(assign, nonatomic, readonly) SDL_GPUTexture *				texture;
@end

NS_ASSUME_NONNULL_END
