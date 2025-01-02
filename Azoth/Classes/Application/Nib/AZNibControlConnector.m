//
//  AZNibControlConnector.m
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import "AZNibControlConnector.h"
#import "AZTypes.h"

#pragma clang diagnostic ignored "-Wundeclared-selector"

@implementation AZNibControlConnector

/*****************************************************************************\
|* Make the connection
\*****************************************************************************/
-(void)establishConnection
	{
	NSString *selectorName 	= self.label;
   	NSInteger length		= selectorName.length;
	SEL selector;
   
	if ((length > 0) && ([selectorName characterAtIndex:length-1] != ':'))
		selectorName = [selectorName stringByAppendingString:@":"];

	selector = NSSelectorFromString(selectorName);

	if(selector == NULL)
		[NSException raise:NSInvalidArgumentException
					format:@"-[%@ %s] selector %@ does not exist:",
						self.class.description,
						sel_getName(_cmd),
						selectorName];


	SEL setAction = SELECTOR(@"setAction:");
	if ([self.source respondsToSelector:setAction])
		{
		IMP imp = [self.source methodForSelector:setAction];
		void (*func)(id, SEL, SEL) = (void *)imp;
		func(self.source, setAction, selector);
		}
	else
		{
		[NSException raise:NSInvalidArgumentException
					format:@"-[%@ %s] _source does not respond to setAction:",
						self.class.description,
						sel_getName(_cmd)];
		}

	SEL setTarget = SELECTOR(@"setTarget:");
	if ([self.source respondsToSelector:setTarget])
		{
		IMP imp = [self.source methodForSelector:setTarget];
		void (*func)(id, SEL, id) = (void *)imp;
		func(self.source, setTarget, self.destination);
		}
	else
		{
		[NSException raise:NSInvalidArgumentException
					format:@"-[%@ %s] _source does not respond to setTarget:",
						self.class.description,
						sel_getName(_cmd)];
		}
	}

@end
