//
//  AZRenderCommand.h
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

@class AZTexture;

typedef enum
	{
    AZRenderCmdNoOp,
    AZRenderCmdSetViewport,
    AZRenderCmdSetCliprect,
    AZRenderCmdSetDrawColour,
    AZRenderCmdClear,
    AZRenderCmdDrawPoints,
    AZRenderCmdDrawLines,
    AZRenderCmdFillRects,
    AZRenderCmdCopy,
    AZRenderCmdCopyExtended,
    AZRenderCmdGeometry
	} AZRenderCommandType;


@interface AZRenderCommand : NSObject

/*****************************************************************************\
|* Reset everything
\*****************************************************************************/
- (void) zero;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The type of command
@property(assign, nonatomic) AZRenderCommandType					command;

// Whether this is the first setViewport (?)
@property(assign, nonatomic) NSInteger								first;

// The rect for this command
@property(assign, nonatomic) NSRect									rect;

// A bool to say whether a command is enabled
@property(assign, nonatomic) BOOL									enabled;

// A count value
@property(assign, nonatomic) NSInteger								count;

// colour scaling
@property(assign, nonatomic) float									colourScale;

// The colour
@property(assign, nonatomic) SDL_FColor								colour;

// The blend mode
@property(assign, nonatomic) SDL_BlendMode							blendMode;

// A texture pointer
@property(strong, nonatomic) AZTexture *							texture;

// How to address the texture
@property(assign, nonatomic) AZTextureAddressMode 					addressMode;
@end

NS_ASSUME_NONNULL_END
