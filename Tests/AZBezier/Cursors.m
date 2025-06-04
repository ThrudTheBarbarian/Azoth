//
//  Cursors.m
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import "Cursors.h"

static const char *p0[] = {
  /* width height num_colors chars_per_pixel */
  "    32    32        3            1",
  /* colors */
  "X c #000000",
  ". c #ffffff",
  "  c None",
  /* pixels */
  "X                 XXXXXXXX      ",
  "XX                XXXXXXXX      ",
  "X.X               XXXXXXXX      ",
  "X..X              XXXXXXXX      ",
  "X...X             XXXXXXXX      ",
  "X....X            XXXXXXXX      ",
  "X.....X                         ",
  "X......X                        ",
  "X.......X         XXXXXXXX      ",
  "X........X        X      X      ",
  "X.....XXXXX       X      X      ",
  "X..X..X           X      X      ",
  "X.X X..X          X      X      ",
  "XX  X..X          XXXXXXXX      ",
  "X    X..X                       ",
  "     X..X                       ",
  "      X..X        XXXXXXXX      ",
  "      X..X        X      X      ",
  "       XX         X      X      ",
  "                  X      X      ",
  "                  X      X      ",
  "                  XXXXXXXX      ",
  "                                ",
  "                                ",
  "                  XXXXXXXX      ",
  "                  X      X      ",
  "                  X      X      ",
  "                  X      X      ",
  "                  X      X      ",
  "                  XXXXXXXX      ",
  "                                ",
  "                                ",
  "0,0"
};

static const char *c0[] = {
  /* width height num_colors chars_per_pixel */
  "    32    32        3            1",
  /* colors */
  "X c #000000",
  ". c #ffffff",
  "  c None",
  /* pixels */
  "X                 XXXXXXXX      ",
  "XX                X      X      ",
  "X.X               X      X      ",
  "X..X              X      X      ",
  "X...X             X      X      ",
  "X....X            XXXXXXXX      ",
  "X.....X                         ",
  "X......X                        ",
  "X.......X         XXXXXXXX      ",
  "X........X        XXXXXXXX      ",
  "X.....XXXXX       XXXXXXXX      ",
  "X..X..X           XXXXXXXX      ",
  "X.X X..X          XXXXXXXX      ",
  "XX  X..X          XXXXXXXX      ",
  "X    X..X                       ",
  "     X..X                       ",
  "      X..X        XXXXXXXX      ",
  "      X..X        X      X      ",
  "       XX         X      X      ",
  "                  X      X      ",
  "                  X      X      ",
  "                  XXXXXXXX      ",
  "                                ",
  "                                ",
  "                  XXXXXXXX      ",
  "                  X      X      ",
  "                  X      X      ",
  "                  X      X      ",
  "                  X      X      ",
  "                  XXXXXXXX      ",
  "                                ",
  "                                ",
  "0,0"
};

static const char *c1[] = {
  /* width height num_colors chars_per_pixel */
  "    32    32        3            1",
  /* colors */
  "X c #000000",
  ". c #ffffff",
  "  c None",
  /* pixels */
  "X                 XXXXXXXX      ",
  "XX                X      X      ",
  "X.X               X      X      ",
  "X..X              X      X      ",
  "X...X             X      X      ",
  "X....X            XXXXXXXX      ",
  "X.....X                         ",
  "X......X                        ",
  "X.......X         XXXXXXXX      ",
  "X........X        X      X      ",
  "X.....XXXXX       X      X      ",
  "X..X..X           X      X      ",
  "X.X X..X          X      X      ",
  "XX  X..X          XXXXXXXX      ",
  "X    X..X                       ",
  "     X..X                       ",
  "      X..X        XXXXXXXX      ",
  "      X..X        XXXXXXXX      ",
  "       XX         XXXXXXXX      ",
  "                  XXXXXXXX      ",
  "                  XXXXXXXX      ",
  "                  XXXXXXXX      ",
  "                                ",
  "                                ",
  "                  XXXXXXXX      ",
  "                  X      X      ",
  "                  X      X      ",
  "                  X      X      ",
  "                  X      X      ",
  "                  XXXXXXXX      ",
  "                                ",
  "                                ",
  "0,0"
};

static const char *p1[] = {
  /* width height num_colors chars_per_pixel */
  "    32    32        3            1",
  /* colors */
  "X c #000000",
  ". c #ffffff",
  "  c None",
  /* pixels */
  "X                 XXXXXXXX      ",
  "XX                X      X      ",
  "X.X               X      X      ",
  "X..X              X      X      ",
  "X...X             X      X      ",
  "X....X            XXXXXXXX      ",
  "X.....X                         ",
  "X......X                        ",
  "X.......X         XXXXXXXX      ",
  "X........X        X      X      ",
  "X.....XXXXX       X      X      ",
  "X..X..X           X      X      ",
  "X.X X..X          X      X      ",
  "XX  X..X          XXXXXXXX      ",
  "X    X..X                       ",
  "     X..X                       ",
  "      X..X        XXXXXXXX      ",
  "      X..X        X      X      ",
  "       XX         X      X      ",
  "                  X      X      ",
  "                  X      X      ",
  "                  XXXXXXXX      ",
  "                                ",
  "                                ",
  "                  XXXXXXXX      ",
  "                  XXXXXXXX      ",
  "                  XXXXXXXX      ",
  "                  XXXXXXXX      ",
  "                  XXXXXXXX      ",
  "                  XXXXXXXX      ",
  "                                ",
  "                                ",
  "0,0"
};

typedef struct
	{
	CursorType		type;
	const char **	info;
	} Cursor;

static Cursor _cursors[] = {
	{Cursor_P0, p0},
	{Cursor_C0, c0},
	{Cursor_C1, c1},
	{Cursor_P1, p1},
	{Cursor_None, NULL}
	};

@implementation Cursors


/*****************************************************************************\
|* Return a cursor for a given type
\*****************************************************************************/
+ (nullable SDL_Cursor *) type:(CursorType)type
	{
	SDL_Cursor *result = NULL;

	int idx 			= 0;
	Cursor cursor		= {type, NULL};
	while (cursor.type != Cursor_None)
		{
		if (_cursors[idx].type == Cursor_None)
			break;

		if (_cursors[idx].type == type)
			{
			cursor.info = _cursors[idx].info;
			break;
			}
		idx ++;
		}

	if (cursor.info != NULL)
		{
		int row;
		Uint8 data[4*32];
		Uint8 mask[4*32];
		int hot_x, hot_y;

		int i = -1;
		for (row=0; row<32; ++row)
			{
			for (int col=0; col<32; ++col)
				{
				if (col % 8)
					{
					data[i] <<= 1;
					mask[i] <<= 1;
					}
				else
					{
					++i;
					data[i] = mask[i] = 0;
					}

				switch (cursor.info[4+row][col])
					{
					case 'X':
						data[i] |= 0x01;
						mask[i] |= 0x01;
						break;
					case '.':
						mask[i] |= 0x01;
						break;
					case ' ':
						break;
					}
				}
			}
		sscanf(cursor.info[4+row], "%d,%d", &hot_x, &hot_y);
		result = SDL_CreateCursor(data, mask, 32, 32, hot_x, hot_y);
		}

	return result;
	}


@end
