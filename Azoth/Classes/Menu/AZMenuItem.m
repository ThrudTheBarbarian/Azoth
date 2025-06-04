//
//  AZMenuItem.m
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import "AZMenuItem.h"

@implementation AZMenuItem

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithTitle:(NSString *)title
						action:(nullable SEL)action
				 keyEquivalent:(NSString *)charcode
	{
	if (self = [super init])
		{
		self.title 			= title;
		self.action			= action;
		self.keyEquivalent	= charcode;
		self.tag			= -1;
 		}
	return self;
	}

+ (AZMenuItem *) itemWithTitle:(NSString *)title
						action:(nullable SEL)action
				 keyEquivalent:(NSString *)charcode;
	{
	return [[AZMenuItem alloc] initWithTitle:title
									  action:action
							   keyEquivalent:charcode];
	}

+ (AZMenuItem *) separatorItem
	{
	AZMenuItem *item = [[AZMenuItem alloc] initWithTitle:@""
												  action:nil
										   keyEquivalent:@""];
	item.separatorItem = YES;
	return item;
	}

+ (AZMenuItem *) sectionHeaderWithTitle:(NSString *)title
	{
	AZMenuItem *item = [[AZMenuItem alloc] initWithTitle:title
												  action:nil
										   keyEquivalent:@""];
	item.headerItem = YES;
	return item;
	}


@end
