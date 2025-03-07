//
//  AZPasteboard.m
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/9/25.
//

#import <SDL3/SDL.h>

#import "AZPasteboard.h"

// These should all be lowercase
AZPasteboardType const AZPasteboardTypeColour	= @"text/colour";
AZPasteboardType const AZPasteboardTypeImage	= @"image/texture";
AZPasteboardType const AZPasteboardTypeString	= @"text/plain;charset=utf-8";
AZPasteboardType const AZPasteboardTypeURL		= @"text/url";

AZPasteboardType const AZPasteboardNameDrag		= @"AZ:PBName:Drag";
AZPasteboardType const AZPasteboardNameGeneral	= @"AZ:PBName:System";


/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZPasteboard()

// Whether this pasteboard is the system-provided copy/paste buffer
@property(assign, nonatomic) BOOL 									isSystem;

// Dictionary of objects by mime-type in the pasteboard
@property(strong, nonatomic)
NSMutableDictionary<NSString *,NSObject *> *							data;

@end

/*****************************************************************************\
|* Shared list of pasteboards by name
\*****************************************************************************/
static NSMutableDictionary<NSString*, AZPasteboard*> * _boards 	= nil;
static NSMutableSet<NSString *> * _valid						= nil;
@implementation AZPasteboard

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) init
	{
	if (self = [super init])
		{
		_isSystem	= NO;
		_changes 	= 0;
		_data		= NSMutableDictionary.new;
		_itemCount = 0;

		static dispatch_once_t onceToken;
		dispatch_once(&onceToken,
			^{
			_valid = NSMutableSet.new;
			[_valid addObject:AZPasteboardTypeColour];
			[_valid addObject:AZPasteboardTypeImage];
			[_valid addObject:AZPasteboardTypeString];
			[_valid addObject:AZPasteboardTypeURL];
			[_valid addObject:@"text/plain"];	// in case charset not set
			});

		}
	return self;
	}

+ (nullable AZPasteboard *) pasteboardWithName:(AZPasteboardName) name
	{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,
		^{
		_boards = NSMutableDictionary.new;
		[_boards setValue:AZPasteboard.new forKey:AZPasteboardNameDrag];
		[_boards setValue:AZPasteboard.new forKey:AZPasteboardNameGeneral];
		_boards[AZPasteboardNameGeneral].isSystem = YES;
		});

	return _boards[name];
	}

/*****************************************************************************\
|* Return the general pasteboard by asking for the system one
\*****************************************************************************/
+ (AZPasteboard *)generalPasteboard
	{
	return [AZPasteboard pasteboardWithName:AZPasteboardNameGeneral];
	}

/*****************************************************************************\
|* Return the dragging pasteboard by asking for the system one
\*****************************************************************************/
+ (AZPasteboard *)draggingPasteboard
	{
	return [AZPasteboard pasteboardWithName:AZPasteboardNameDrag];
	}

/*****************************************************************************\
|* Sets the property list as the value for the given type in this pasteboard.
|* If you want to set multiple items, encode them as elements within an
|* NSArray or NSDictionary top-level item
\*****************************************************************************/
- (BOOL) setPropertyList:(id)plist forType:(AZPasteboardType)type
	{
	_itemCount = 1;
	_changes ++;
	NSError *error = nil;
	NSData *data   = [NSPropertyListSerialization
						dataWithPropertyList:plist
									  format:NSPropertyListBinaryFormat_v1_0
									 options:0
									   error:&error];
	if (error)
		{
		SDL_Log("Pasteboard: cannot serialise %s",
				((NSObject *)plist).description.UTF8String);
		return NO;
		}

	[_data setValue:data forKey:type];
	return YES;
	}

/*****************************************************************************\
|* Sets a string as the value for the given type in this pasteboard. We don't
|* encode strings as data, for interop between the system and the app
\*****************************************************************************/
- (BOOL) setString:(NSString *)payload
	{
	return [self setString:payload forType:AZPasteboardTypeString];
	}

- (BOOL) setString:(NSString *)payload forType:(AZPasteboardType)type
	{
	_itemCount = 1;
	_changes ++;
	[_data setValue:payload forKey:type];
	return YES;
	}

/*****************************************************************************\
|* Returns a list of the pasteboard types set within this pasteboard
\*****************************************************************************/
- (NSArray<AZPasteboardType> *) datatypes
	{
	if (_isSystem)
		{
		NSMutableArray<AZPasteboardType> *list = NSMutableArray.new;
		size_t num   = 0;
		char **types = SDL_GetClipboardMimeTypes(&num);
		if (types == NULL)
			SDL_Log("Cannot find system pasteboard. %s", SDL_GetError());
		else
			{
			for (int i=0; i<num; i++)
				{
				NSString *entry = [NSString stringWithUTF8String:types[i]];
				if ([_valid containsObject:entry.lowercaseString])
					[list addObject:entry];
				}
			}
		if (types)
			SDL_free(types);
		return list;
		}

	return _data.allKeys;
	}

/*****************************************************************************\
|* Returns the data for the specified type from the first item in the
|* receiver that contains the type
\*****************************************************************************/
- (NSData *) dataForType:(AZPasteboardType)type
	{
	if (_isSystem)
		{
		size_t size;
		uint8_t *bytes = SDL_GetClipboardData(type.UTF8String, &size);
		if (bytes == NULL)
			return nil;

		NSData *data = [NSData dataWithBytes:bytes length:size];
		SDL_free(bytes);
		return data;
		}

	id element = [_data objectForKey:type];
	if ([element isKindOfClass:NSData.class])
		return (NSData *)element;

	// Only other option is a string
	NSString *str = (NSString *)element;
	return [str dataUsingEncoding:NSUTF8StringEncoding];
	}

/*****************************************************************************\
|* Returns the property list for the specified type from the first item in the
|* receiver that contains the type
\*****************************************************************************/
- (id) propertyListForType:(AZPasteboardType)type
	{
	if (_isSystem)
		{
		// We don't really expect property-list serialised data from the
		// system clipboard. Get it as data and return it in an array
		NSData *data = [self dataForType:type];
		if (data)
			return @[data];
		return nil;
		}

	id element = [_data objectForKey:type];
	if ([element isKindOfClass:NSData.class])
		{
		NSError *error = nil;
		element = [NSPropertyListSerialization
			propertyListWithData:element
						 options:NSPropertyListMutableContainersAndLeaves
						  format:nil
						   error:&error];

		if (error)
			{
			SDL_Log("Pasteboard: cannot deserialise for type %s",
					type.UTF8String);
			return nil;
			}
		return element;
		}

	return nil;
	}


/*****************************************************************************\
|* Returns a string value (if it can be decoded) for a given type.
\*****************************************************************************/
- (NSString *) string
	{
	return [self stringForType:AZPasteboardTypeString];
	}

- (NSString *) stringForType:(AZPasteboardType)type
	{
	if (_isSystem)
		{
		NSData *data = [self dataForType:type];
		return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		}

	return ((NSObject *)_data[type]).description;
	}

/*****************************************************************************\
|* Clears the existing contents of the pasteboard. Returns the change-count
\*****************************************************************************/
- (NSInteger) clearContents
	{
	_itemCount = 0;
	_changes ++;
	[_data removeAllObjects];
	return _changes;
	}

/*****************************************************************************\
|* Writes an array of objects to the receiver, assuming they all implement
|* the AZPasteboardWriting protocol
\*****************************************************************************/
- (BOOL) writeObjects:(NSArray<id<AZPasteboardWriting>> *) objects;
	{
	// Don't support this on the system clipboard
	if (_isSystem)
		return NO;
	_itemCount = objects.count;

	if (objects.count < 1)
		return YES;

	/*************************************************************************\
	|* Find a list of types common to the objects sent through, so we write all
	|* the same types for each object. Otherwise multiple array-based lists
	|* would get out-of-sync
	\*************************************************************************/
	NSMutableSet *commonTypes 		= [NSMutableSet new];
	id<AZPasteboardWriting> first 	= objects.firstObject;
	[commonTypes addObjectsFromArray:[first writableTypesForPasteboard:self]];

	for (id<AZPasteboardWriting> o in objects)
		{
		NSSet *types = [NSSet setWithArray:[o writableTypesForPasteboard:self]];
		[commonTypes intersectSet:types];
		}
	if (commonTypes.count == 0)
		{
		SDL_Log("No common pasteboard-types in objects requested to write");
		return NO;
		}

	/*************************************************************************\
	|* Create arrays to store the representations for each type for each object
	\*************************************************************************/
	NSMutableDictionary *content = [NSMutableDictionary new];
	for (AZPasteboardType type in commonTypes)
		content[type] = [NSMutableArray new];

 	/*************************************************************************\
	|* Write the data to the arrays
	\*************************************************************************/
	for (id<AZPasteboardWriting> o in objects)
		for (AZPasteboardType type in commonTypes)
			{
			id value = [o pasteboardPropertyListForType:type];
			[(NSMutableArray *)content[type] addObject:value];
			}

 	/*************************************************************************\
	|* Store the arrays to the pasteboard
	\*************************************************************************/
	for (AZPasteboardType type in content)
		[self setPropertyList:content[type] forType:type];

	return YES;
	}

/*****************************************************************************\
|* Encode a plist as data
\*****************************************************************************/
- (nullable NSData *) _dataFor:(id)plist
	{
	NSError *error = nil;
	NSData *data   = [NSPropertyListSerialization
						dataWithPropertyList:plist
									  format:NSPropertyListBinaryFormat_v1_0
									 options:0
									   error:&error];
	if (error)
		{
		SDL_Log("Pasteboard: cannot serialise %s",
				((NSObject *)plist).description.UTF8String);
		return nil;
		}
	return data;
	}

@end
