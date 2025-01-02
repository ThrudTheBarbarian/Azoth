//
//  AZIBObjectData.m
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import <SDL3/SDL.h>
#import <Foundation/NSDebug.h>

#import "AZCustomObject.h"
#import "AZIBObjectData.h"
#import "AZMenu.h"
#import "AZNib.h"

@interface AZIBObjectData()

@property(strong, nonatomic) NSArray<NSString *> *		namesKeys;
@property(strong, nonatomic) NSArray<NSString *> *		namesValues;
@property(strong, nonatomic) NSArray<NSObject *> *		accessibilityConnectors;
@property(strong, nonatomic) NSArray<NSString *> *		accessibilityOidsKeys;
@property(strong, nonatomic) NSArray<NSObject *> *		accessibilityOidsValues;
@property(strong, nonatomic) NSArray<NSString *> *		classesKeys;
@property(strong, nonatomic) NSArray<NSObject *> *		classesValues;
@property(strong, nonatomic) NSArray<NSObject *> *		connections;
@property(strong, nonatomic) NSString *					framework;
@property(assign, nonatomic) NSInteger					nextOid;
@property(strong, nonatomic) NSArray<NSString *> *		objectsKeys;
@property(strong, nonatomic) NSArray<NSObject *> *		objectsValues;
@property(strong, nonatomic) NSArray<NSString *> *		oidKeys;
@property(strong, nonatomic) NSArray<NSObject *> *		oidValues;
@property(strong, nonatomic) AZCustomObject *			fileOwner;
@end

@interface NSKeyedUnarchiver(private)
-(void)replaceObject:object withObject:replacement;
@end

@interface AZNib(private)
-(NSDictionary *)externalNameTable;
@end

@interface AZMenu(private)
-(NSString *)_name;
@end



@implementation AZIBObjectData
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithCoder:(NSCoder *)coder
	{
	if (coder.allowsKeyedCoding)
		{
		id owner;
		NSMutableDictionary *nameTable = nil;
		NSKeyedUnarchiver *keyed       = (NSKeyedUnarchiver *)coder;
		nameTable = [NSMutableDictionary dictionaryWithDictionary:
										  [(id)[keyed delegate] externalNameTable]];

		if ((owner = [nameTable objectForKey:AZNibOwner]) != nil)
			[nameTable setObject:owner forKey:@"File's Owner"];
		
		_namesValues 	= [keyed decodeObjectForKey:@"NSNamesValues"];
		NSInteger count	= [_namesValues count];
		NSMutableArray *namedObjects=[[keyed
									   decodeObjectForKey:@"NSNamesKeys"] mutableCopy];
		for (NSInteger i=0; i<count; i++)
			{
			NSString *check = [_namesValues objectAtIndex:i];
			id external		= [nameTable objectForKey:check];
			id nibObject	= [namedObjects objectAtIndex:i];

			if (external != nil)
				{
				[keyed replaceObject:nibObject withObject:external];
				[namedObjects replaceObjectAtIndex:i withObject:external];
				}
			else if ([nibObject isKindOfClass:[AZCustomObject class]])
				{
				id replacement = [nibObject createCustomInstance];

				if(replacement == nil)
					SDL_Log("Custom instance creation failed for %s",
						((NSObject *)nibObject).description.UTF8String);
				else
					{
					[keyed replaceObject:nibObject withObject:replacement];
					[namedObjects replaceObjectAtIndex:i withObject:replacement];
					}
				}
			}
		_namesKeys = namedObjects;

		_fileOwner = [keyed decodeObjectForKey:@"NSRoot"];
		if ([_fileOwner isKindOfClass:[AZCustomObject class]])
			{
			if (_fileOwner != owner)
				{
				id formerFileOwner 	= _fileOwner;
				_fileOwner 			= owner;
				[keyed replaceObject:formerFileOwner withObject:_fileOwner];
				}
			}
		
		_accessibilityConnectors = [keyed decodeObjectForKey:@"NSAccessibilityConnectors"];
		_accessibilityOidsKeys = [keyed decodeObjectForKey:@"NSAccessibilityOidsKeys"];
		_accessibilityOidsValues = [keyed decodeObjectForKey:@"NSAccessibilityOidsValues"];
		_classesKeys = [keyed decodeObjectForKey:@"NSClassesKeys"];
		_classesValues = [keyed decodeObjectForKey:@"NSClassesValues"];
		_connections = [keyed decodeObjectForKey:@"NSConnections"];
		_framework = [keyed decodeObjectForKey:@"NSFramework"];
		_nextOid = [keyed decodeIntForKey:@"NSNextOid"];
		_objectsKeys = [keyed decodeObjectForKey:@"NSObjectsKeys"];
		_objectsValues = [keyed decodeObjectForKey:@"NSObjectsValues"];
		_oidKeys = [keyed decodeObjectForKey:@"NSOidsKeys"];
		_oidValues = [keyed decodeObjectForKey:@"NSOidsValues"];
		_visibleWindows = [keyed decodeObjectForKey:@"NSVisibleWindows"];

		
		// Replace any custom object with the real thing - and update anything
		// tracking them
		for (NSInteger i = _objectsValues.count - 1; i >= 0; i--)
			{
			id  aValue = [_objectsValues objectAtIndex:i];
			if (aValue == owner)
				{
				id aKey = [_objectsKeys objectAtIndex:i];
				if ([aKey isKindOfClass:[AZCustomObject class]])
					{
					id replacement = [aKey createCustomInstance];

					// Tell the decoder we are now using that - that will
					// notify the Nib object
					[keyed replaceObject:aKey withObject:replacement];

					// Update the connections
					[self replaceObject:aKey withObject:replacement];
					
					if (![_objectsKeys isKindOfClass:[NSMutableArray class]])
						_objectsKeys = [_objectsKeys mutableCopy];

					[(NSMutableArray *)_objectsKeys replaceObjectAtIndex:i
													withObject:replacement];
					}
				}
			}
		return self;
		}
	
	return nil;
	}


/*****************************************************************************\
|* Find the menu and return it
\*****************************************************************************/
-(AZMenu *) mainMenu
	{
	for (NSInteger i = _objectsValues.count - 1; i >= 0; i--)
		{
		id  aValue = [_objectsValues objectAtIndex:i];
		if (aValue == _fileOwner)
			{
			id  aKey = [_objectsKeys objectAtIndex:i];
			if ([aKey isKindOfClass:[AZMenu class]] &&
				[[(AZMenu *)aKey _name] isEqual:@"_NSMainMenu"])
				return aKey;

			}
		}
	return nil;
	}

/*****************************************************************************\
|* Replace one object with another
\*****************************************************************************/
-(void)replaceObject:oldObject withObject:newObject
	{
	NSInteger count = _connections.count;
	for (NSInteger i=0; i<count; i++)
		[(id)[_connections objectAtIndex:i] replaceObject:oldObject
										   withObject:newObject];
	}

/*****************************************************************************\
|* establish a connection
\*****************************************************************************/
-(void) establishConnections
	{
	NSInteger count = [_connections count];

	for (NSInteger i=0; i<count; i++)
		{
		@try
			{
			[(id)[_connections objectAtIndex:i] establishConnections];
			}
		@catch (NSException *exception)
			{
			if (NSDebugEnabled)
				NSLog(@"Exception during -establishConnection %@",exception);
			}
		}
	}

/*****************************************************************************\
|* Build the connections using a name-table
\*****************************************************************************/
-(void)buildConnectionsWithNameTable:(NSDictionary *)nameTable
	{
	id owner = [nameTable objectForKey:AZNibOwner];
	if (_fileOwner != owner)
		{
		[self replaceObject:_fileOwner withObject:owner];
		id formerOwner 	= _fileOwner;
		_fileOwner		= owner;

		if (![_objectsValues isKindOfClass:[NSMutableArray class]])
			_objectsValues = [_objectsValues mutableCopy];

		for (NSInteger i = _objectsValues.count - 1; i >= 0; i--)
			{
			id  aValue = [_objectsValues objectAtIndex:i];
			if (aValue == formerOwner)
				[(NSMutableArray *)_objectsValues replaceObjectAtIndex:i
												  withObject:_fileOwner];
			}
		}
	[self establishConnections];
	}

/*****************************************************************************\
|* Return the top-level objects except the File's Owner (and the virtual
|* First Responder)
\*****************************************************************************/
- (NSArray *)topLevelObjects
	{
	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
	NSMutableArray *topLevelObjects;

	for (NSInteger i = _objectsValues.count - 1; i >= 0; i--)
		{
		id  eachObject = [_objectsValues objectAtIndex:i];
		
		if (eachObject == _fileOwner)
			[indexes addIndex:i];
		}
	
	topLevelObjects = [NSMutableArray arrayWithCapacity:indexes.count];
	for (NSInteger i = indexes.firstIndex;
				   i != NSNotFound;
				   i = [indexes indexGreaterThanIndex:i])
		{
		id  anObject = [_objectsKeys objectAtIndex:i];
		
		if(anObject != _fileOwner)
			[topLevelObjects addObject:anObject];
		}
	
	return topLevelObjects;
	}


@end
