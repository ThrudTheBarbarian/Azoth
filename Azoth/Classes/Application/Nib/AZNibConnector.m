//
//  AZNibConnector.m
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import "AZNibConnector.h"
#import "AZTypes.h"

@implementation AZNibConnector


/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithCoder:(NSCoder *)coder
	{
	if (coder.allowsKeyedCoding)
		{
		NSKeyedUnarchiver *keyed = (NSKeyedUnarchiver *)coder;

		_source   		= [keyed decodeObjectForKey:@"NSSource"];
		_destination	= [keyed decodeObjectForKey:@"NSDestination"];
		_label			= [keyed decodeObjectForKey:@"NSLabel"];
		}
   else
		[NSException raise:NSInvalidArgumentException
					format:@"-[%@ %@] is not implemented for coder %@",
					self.class.description,
					NSStringFromSelector(_cmd),
					[coder class]];
	return self;
	}

/*****************************************************************************\
|* Just to stop the warning
\*****************************************************************************/
-(void)encodeWithCoder:(NSCoder *)coder
	{
	AZUnimplementedMethod();
	}

-(void)replaceObject:original withObject:replacement {
   if(original==_source)
    [self setSource:replacement];
   if(original==_destination)
    [self setDestination:replacement];
}

-(void)establishConnection
	{
	AZInvalidAbstractInvocation();
	}

@end
