//
//  AZVertexInputState.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/14/25.
//

#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>

NS_ASSUME_NONNULL_BEGIN

@class AZVertexAttribute;
@class AZVertexBuffer;

@interface AZVertexInputState : NSObject


/*****************************************************************************\
|* Add a vertex buffer
\*****************************************************************************/
- (void) addBuffer:(AZVertexBuffer *)buffer;

/*****************************************************************************\
|* Add a vertex attribute
\*****************************************************************************/
- (void) addAttribute:(AZVertexAttribute *)attribute;


/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The list of vertex buffers
@property(strong, nonatomic)
NSMutableArray<AZVertexBuffer *> *							vertexBuffers;

// The list of vertex attributes
@property(strong, nonatomic)
NSMutableArray<AZVertexAttribute *> *						vertexAttributes;

// The input state as needed to create the pipeline
@property(assign, nonatomic, readonly)
SDL_GPUVertexInputState										state;

@end

NS_ASSUME_NONNULL_END
