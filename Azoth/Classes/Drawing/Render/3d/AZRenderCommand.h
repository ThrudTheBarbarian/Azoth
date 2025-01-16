//
//  AZRenderCommand.h
//  Azoth
//
//  Created by Simon Gornall on 1/15/25.
//

#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>

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

typedef enum AZTextureAddressMode
	{
    AZTextureAddressAuto,
    AZTextureAddressClamp,
    AZTextureAddressWrap,
	} AZTextureAddressMode;


@interface AZRenderCommand : NSObject


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
@property(assign, nonatomic) SDL_BlendMode							blend;

// A texture pointer
@property(strong, nonatomic) AZTexture *							texture;

// How to address the texture
@property(assign, nonatomic) AZTextureAddressMode 					addressMode;

@end

NS_ASSUME_NONNULL_END
