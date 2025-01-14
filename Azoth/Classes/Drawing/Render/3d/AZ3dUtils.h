//
//  AZ3dUtils.h
//  Azoth
//
//  Created by Simon Gornall on 1/14/25.
//

#ifndef AZ3dUtils_h
#define AZ3dUtils_h

#import <Azoth/AZTypes.h>
#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>

static AZThreadSize AZMakeThreadSize(int x, int y, int z)
	{
	AZThreadSize azts;
	azts.x = x;
	azts.y = y;
	azts.z = z;
	return azts;
	};
	

#endif /* AZ3dUtils_h */
