//
//  AZCustomView.m
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import "AZClassSwapper.h"
#import "AZCustomView.h"
#import "AZView.h"

@implementation AZCustomView

/*****************************************************************************\
|* Create the instance using a coder
\*****************************************************************************/
- (instancetype) initWithCoder:(NSCoder *)coder
	{
	if (coder.allowsKeyedCoding)
		{
		NSKeyedUnarchiver *keyed 	= (NSKeyedUnarchiver *)coder;
		NSString *name 				= [keyed decodeObjectForKey:@"NSClassName"];
		NSString *className			= [AZClassSwapper toAZ:name];
		Class class 				= NSClassFromString(className);

		if (class == nil)
			{
			NSLog(@"AZCustomView unknown class %@", className);
			return self;
			}
		else
			{
			NSRect frame=NSZeroRect;
			if ([coder containsValueForKey:@"NSFrame"])
				frame=[coder decodeRectForKey:@"NSFrame"];
			else if([coder containsValueForKey:@"NSFrameSize"])
				frame.size=[coder decodeSizeForKey:@"NSFrameSize"];

			AZView *newView = [[class alloc] initWithFrame:frame];
			if ([coder containsValueForKey:@"NSvFlags"])
				{
				unsigned vFlags=[coder decodeIntForKey:@"NSvFlags"];
          
				newView.autoresizingMask 	= vFlags & 0x3F;
				newView.autoresizesSubviews	= (vFlags & 0x100) 		? YES : NO;
				newView.hidden 				= (vFlags & 0x80000000)	? YES : NO;
				}

			// Despite the fact it appears _autoresizesSubviews is encoded in
			// the flags, it should always be on
			newView.autoresizesSubviews		= YES;

			if ([coder containsValueForKey:@"NSTag"])
				newView.tag	= [coder decodeIntForKey:@"NSTag"];

			NSArray* subviews = [coder decodeObjectForKey:@"NSSubviews"];
		  
			// For some unknown reason custom view subviews are presented in
			// reverse order in the nib - so we need to add them in reverse
			// - this matches Cocoa behaviour
			NSEnumerator* reverseEnum = [subviews reverseObjectEnumerator];
			AZView* subview = nil;
			while ((subview = [reverseEnum nextObject]))
				[newView.subviews addObject: subview];
		  
			[newView.subviews makeObjectsPerformSelector:
				@selector(setSuperview:) withObject:newView];
			[self.subviews removeAllObjects];

			return (id)newView;
			}
		}
	else
		{
		[NSException raise:NSInvalidArgumentException
					format:@"-[%@ %@] does not handle %@",
						self.class.description,
						NSStringFromSelector(_cmd),
						[coder class]];
		return self;
		}
	}

@end
