//
//  AZCustomObject.m
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import "AZApplication.h"
#import "AZClassSwapper.h"
#import "AZCustomObject.h"

@implementation AZCustomObject

/*****************************************************************************\
|* Create the instance using a coder
\*****************************************************************************/
- (instancetype) initWithCoder:(NSCoder *)coder
	{
	if (coder.allowsKeyedCoding)
		{
		NSKeyedUnarchiver *keyed 	= (NSKeyedUnarchiver *)coder;
		NSString *name 			 	= [keyed decodeObjectForKey:@"NSClassName"];
		_className					= [AZClassSwapper toAZ:name];
		}
	else
		[NSException raise:NSInvalidArgumentException
					format:@"-[%@ %@] does not handle %@",
					self.class.description,
					NSStringFromSelector(_cmd),
					[coder class]];

	return self;
	}

/*****************************************************************************\
|* Create the instance. Note that we don't deal with shared-instances very
|* well here - they are just enumerated as special cases.
\*****************************************************************************/
- (id)createCustomInstance
	{
	Class class = NSClassFromString(_className);
	id ret 		= nil;

	if (class == Nil)
		NSLog(@"AZCustomObject unknown class %@", _className);

	if ([_className isEqualToString:@"NSApplication"])
		ret = AZApplication.sharedApplication;
	else
      ret=[class new];

	return ret;
	}


/*****************************************************************************\
|* Be informative.
\*****************************************************************************/
-(NSString *)description
	{
	return [NSString stringWithFormat:@"<%@:%p:class name=%@>",
			self.class.description,self,_className];
	}

@end
