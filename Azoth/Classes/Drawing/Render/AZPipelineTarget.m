//
//  AZPipelineTarget.m
//  sdl3_gpu
//
//  Created by Simon Gornall on 1/13/25.
//

#import "AZPipelineTarget.h"

@implementation AZPipelineTarget
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
		_colourTargets 		= NSMutableArray.new;
		}
	return self;
	}



/*****************************************************************************\
|* Add a colour target
\*****************************************************************************/
- (void) addColourTarget:(AZColourTarget *)colourTarget
	{
	[_colourTargets addObject:colourTarget];
	}


@end
