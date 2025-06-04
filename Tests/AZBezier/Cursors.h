//
//  Cursors.h
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>

typedef enum
	{
	Cursor_None = 0,
	Cursor_P0,
	Cursor_C0,
	Cursor_C1,
	Cursor_P1
	} CursorType;

NS_ASSUME_NONNULL_BEGIN

@interface Cursors : NSObject

/*****************************************************************************\
|* Return a cursor for a given type
\*****************************************************************************/
+ (nullable SDL_Cursor *) type:(CursorType)type;

@end

NS_ASSUME_NONNULL_END
