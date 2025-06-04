//
//  NSDictionary+ZIB.m
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <Azoth/AZTypes.h>

#import "NSDictionary+ZIB.h"

static NSString * const kFlexibleMaxX	= @"flexibleMaxX";
static NSString * const kFlexibleMaxY	= @"flexibleMaxY";
static NSString * const kFlexibleMinX	= @"flexibleMinX";
static NSString * const kFlexibleMinY	= @"flexibleMinY";
static NSString * const kHeightSizable  = @"heightSizable";
static NSString * const kWidthSizable  	= @"widthSizable";

static NSString * const kRect			= @"rect";
static NSString * const kKey			= @"key";
static NSString * const kX				= @"x";
static NSString * const kY				= @"y";
static NSString * const kW				= @"width";
static NSString * const kH				= @"height";

@implementation NSDictionary (ZIB)

/*****************************************************************************\
|* Decode an integer resize-mask from the constants in the dictionary
\*****************************************************************************/
- (int) AZResizeMask
	{
	int resizeMask = AZViewNotSizable;

	if ([self[kFlexibleMinX] isEqualToString:@"YES"])
		resizeMask |= AZViewMinXMargin;
	if ([self[kWidthSizable] isEqualToString:@"YES"])
		resizeMask |= AZViewWidthSizable;
	if ([self[kFlexibleMaxX] isEqualToString:@"YES"])
		resizeMask |= AZViewMaxXMargin;
	if ([self[kFlexibleMinY] isEqualToString:@"YES"])
		resizeMask |= AZViewMaxYMargin;
	if ([self[kHeightSizable] isEqualToString:@"YES"])
		resizeMask |= AZViewHeightSizable;
	if ([self[kFlexibleMaxY] isEqualToString:@"YES"])
		resizeMask |= AZViewMinYMargin;

	return resizeMask;
	}

/*****************************************************************************\
|* Return a rectangle that matches a key, eg a 'frame' rect might be defined as
|* <rect key="frame" x="158" y="132" width="163" height="96"/>
\*****************************************************************************/
- (NSRect) AZRectWithKey:(NSString *)key
	{
	NSArray *rectList = nil;

	if (![self[kRect] isKindOfClass:NSArray.class])
		rectList = @[self[kRect]];
	else
		rectList = self[kRect];

	for (NSDictionary *rect in rectList)
		{
		if ([rect[kKey] isEqualToString:key])
			{
			float x = ((NSNumber *)rect[kX]).floatValue;
			float y = ((NSNumber *)rect[kY]).floatValue;
			float w = ((NSNumber *)rect[kW]).floatValue;
			float h = ((NSNumber *)rect[kH]).floatValue;

			return NSMakeRect(x,y,w,h);
			}
		}

	return NSZeroRect;
	}


/*****************************************************************************\
|* Return a string or a fallback
\*****************************************************************************/
- (NSString *) AZStringWithKey:(NSString *)key orDefault:(NSString *)fallback;
	{
	NSString *value = self[key];
	return (value == nil) ? fallback : value;
	}
@end
