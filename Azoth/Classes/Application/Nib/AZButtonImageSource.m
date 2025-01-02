//
//  AZButtonImageSource.m
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import "AZButtonImageSource.h"
#import "AZClassSwapper.h"
#import "AZImage.h"

@interface AZButtonImageSource()
@property(strong, nonatomic) NSString *						imageName;
@end

@implementation AZButtonImageSource

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
-initWithCoder:(NSCoder *)coder
	{
	if (coder.allowsKeyedCoding)
		{
		NSKeyedUnarchiver *keyed = (NSKeyedUnarchiver *)coder;

		NSString *name = [keyed decodeObjectForKey:@"NSImageName"];
		_imageName = [AZClassSwapper toAZ:name];
		}
	return self;
	}

/*****************************************************************************\
|* Return the normal image
\*****************************************************************************/
- (AZImage *) normalImage
	{
	return [AZImage imageNamed:_imageName];
	}

/*****************************************************************************\
|* Return the alternate image
\*****************************************************************************/
- (AZImage *) alternateImage
	{
	NSString *stem = [_imageName substringFromIndex:2];
	NSString *name = [@"AZHighlighted" stringByAppendingString:stem];
	return [AZImage imageNamed:name];
	}

@end
