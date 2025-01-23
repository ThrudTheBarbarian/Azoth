//
//  AZModalShieldView.m
//  Azoth
//
//  Created by Simon Gornall on 1/22/25.
//

#import "AZModalShieldView.h"

@implementation AZModalShieldView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super initWithFrame:frame])
		{
		}
	return self;
	}

/*****************************************************************************\
|* Draw
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	AZColour *c = [AZColour colourWithByteR:0 g:0 b:0 a:0x80];
	[painter rectangleWithRect:self.bounds filled:YES colour:c];
	}


/*****************************************************************************\
|* Mouse
\*****************************************************************************/
- (BOOL) mouseDown:(AZEvent *)e
	{
	return YES;
	}

- (BOOL) mouseUp:(AZEvent *)e
	{
	return YES;
	}
	
@end
