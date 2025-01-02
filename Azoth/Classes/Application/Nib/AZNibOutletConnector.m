//
//  AZNibOutletConnector.m
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import <SDL3/SDL.h>

#import "AZNibOutletConnector.h"

@implementation AZNibOutletConnector

-(void)establishConnection
	{
	NSString *camelCase  = self.label.capitalizedString;
	NSString *methodName = [NSString stringWithFormat:@"set%@:",camelCase];
	SEL	selector		 = NSSelectorFromString(methodName);

	if (selector != NULL)
		if ([self.source respondsToSelector:selector])
			{
			IMP imp = [self.source methodForSelector:selector];
			void (*func)(id, SEL, id) = (void *)imp;
			func(self.source, selector, self.destination);
			return;
			}

	NSString *err = [NSString stringWithFormat:
						@"Class %@ is not KVO-conpliant for %@",
						self.source,
						methodName];
	SDL_Log("%s", err.UTF8String);
	}

@end
