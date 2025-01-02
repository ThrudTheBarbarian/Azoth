//
//  AZNib.m
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import <SDL3/SDL.h>

#import "AZIBObjectData.h"
#import "AZMenu.h"
#import "AZMenuItem.h"
#import "AZNib.h"
#import "AZNibHelpConnector.h"
#import "AZNibLoading.h"
#import "AZTableCornerView.h"
#import "AZTypes.h"

NSString * const AZNibOwner				= @"NSOwner";
NSString * const AZNibTopLevelObjects	= @"NSNibTopLevelObjects";

@interface AZNib()
@property(strong, nonatomic) NSData *							data;
@property(strong, nonatomic) NSMutableArray*					allObjects;
@property(strong, nonatomic) NSMutableDictionary *				nameTable;
@end

@implementation AZNib 

/*****************************************************************************\
|* Initialisation from file
\*****************************************************************************/
- (instancetype) initWithContentsOfFile:(NSString *)path
	{
    NIBDEBUG(@"initWithContentsOfFile: %@", path);
    
	NSString *keyedObjects	= path;
	BOOL isDirectory		= NO;

	NSFileManager *fm = NSFileManager.defaultManager;

	if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory)
		keyedObjects = [[path stringByAppendingPathComponent:@"keyedobjects"]
							  stringByAppendingPathExtension:@"nib"];

	if (!keyedObjects && !isDirectory)
		keyedObjects = path; // assume "new"-style compiled xib

	if ((_data = [[NSData alloc] initWithContentsOfFile:keyedObjects]) == nil)
		self = nil;
	else
		_allObjects=[NSMutableArray new];
   
	return self;
	}

/*****************************************************************************\
|* Initialisation, more conveniently
\*****************************************************************************/
+ (AZNib *) nibWithContentsOfFile:(NSString *)path
	{
	return [[AZNib alloc] initWithContentsOfFile:path];
	}

/*****************************************************************************\
|* Initialisation from URL
\*****************************************************************************/
- (instancetype) initWithContentsOfURL:(NSURL *)url
	{
    NIBDEBUG(@"initWithContentsOfURL: %@", url);

    if ([url isFileURL])
		return [self initWithContentsOfFile:url.path];

	return nil;
	}

/*****************************************************************************\
|* ... and again
\*****************************************************************************/
+ (AZNib *) nibWithContentsOfURL:(NSURL *)url
	{
	return [[AZNib alloc] initWithContentsOfURL:url];
	}

/*****************************************************************************\
|* Initialisation from a named file in a bundle
\*****************************************************************************/
- (instancetype) initWithNibNamed:(NSString *)name bundle:(NSBundle *)bundle
	{
    NIBDEBUG(@"initWithNibNamed: %s bundle: %s", name.description, bundle);

    if (bundle == nil)
		bundle = NSBundle.mainBundle;

   NSString *path = [bundle pathForResource:name ofType:@"nib"];

   if(path == nil)
		{
		SDL_Log("%s: unable to init nib with name '%s'", __PRETTY_FUNCTION__,
				name.UTF8String);
		self = nil;
		}

	return [self initWithContentsOfFile:path];
	}

/*****************************************************************************\
|* ... and again
\*****************************************************************************/
+ nibWithName:(NSString *)name bundle:(NSBundle *)bundle
	{
	return [[AZNib alloc] initWithNibNamed:name bundle:bundle];
	}


/*****************************************************************************\
|* Handle a decode
\*****************************************************************************/
- (id) unarchiver:(NSKeyedUnarchiver *)unarchiver didDecodeObject:object
	{
	if (object != nil)
		[_allObjects addObject:object];
	return object;
	}

/*****************************************************************************\
|* Handle a replace
\*****************************************************************************/
- (void) unarchiver:(NSKeyedUnarchiver *)unarchiver willReplaceObject:object
													withObject:replacement
	{
	if (object!=nil && replacement!=nil)
		{
		NSUInteger index = [_allObjects indexOfObjectIdenticalTo:object];
		[_allObjects replaceObjectAtIndex:index withObject:replacement];
		}
	}

/*****************************************************************************\
|* Expose the external name table
\*****************************************************************************/
- (NSDictionary *) externalNameTable
	{
	return _nameTable;
	}

/*****************************************************************************\
|* Called by the entry method to populate everything
|*
|*    TO DO:
|*   - utf8 in the multinational panel
|*   - misaligned objects in boxes everywhere
|*
\*****************************************************************************/
- (BOOL) instantiateNibWithExternalNameTable:(NSDictionary *)nameTable
	{
    NIBDEBUG(@"instantiateNibWithExternalNameTable: %@", nameTable);
	NSKeyedUnarchiver *unarchiver 	= nil;
	AZIBObjectData *objectData 		= nil;

	@autoreleasepool
		{
		AZMenu *menu				= nil;
		_nameTable 					= nameTable.mutableCopy;
		NSError *error				= nil;

		unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:_data
																 error:&error];
		if (error != nil)
			{
			SDL_Log("%s: failed to read NIB data",
					NSStringFromSelector(_cmd).UTF8String);
			return NO;
			}

		[unarchiver setDelegate:self];
    
		[unarchiver setClass:[AZTableCornerView class]
				forClassName:@"_NSCornerView"];
		[unarchiver setClass:[AZNibHelpConnector class]
				forClassName:@"NSIBHelpConnector"];

		objectData=[unarchiver decodeObjectForKey:@"IB.objectdata"];

		[objectData buildConnectionsWithNameTable:_nameTable];
		if ((menu = [objectData mainMenu]) != nil)
			{
			// Rename the first item to have the application name.
			if ([menu numberOfItems] > 0)
				{
				AZMenuItem *firstItem	= [menu itemAtIndex: 0];
				NSBundle *bundle		= NSBundle.mainBundle;
				NSDictionary *info		= bundle.localizedInfoDictionary;
				NSString *appName 		= info[(NSString *)kCFBundleNameKey];
				[firstItem setTitle: appName];
				}
			[AZApp setMainMenu:menu];
			}

		NSArray *tlo = [objectData topLevelObjects];

		// if external table contains a mutable array for key NSNibTopLevelObjects,
		// then this array also retains all top-level objects,
		if ([_nameTable objectForKey:AZNibTopLevelObjects])
			[[_nameTable objectForKey:AZNibTopLevelObjects] setArray:tlo];


		// We do not need to add the objects from nameTable to allObjects as
		// they get put into the uid->object table already
		// Do we send awakeFromNib to objects in the nameTable *not* present
		// in the nib ?

		NSInteger count = _allObjects.count;

		for (NSInteger i=0; i<count; i++)
			{
			id object=[_allObjects objectAtIndex:i];

			if ([object respondsToSelector:@selector(awakeFromNib)])
				[object awakeFromNib];
			}

		// This little song-and-dance is because Xcode doesn't like sending
		// selectors that it doesn't know about. Go via the IMP instead.
		SEL postAwakeFromNib = SELECTOR(@"postAwakeFromNib");
		for (NSInteger i=0; i<count; i++)
			{
			id object=[_allObjects objectAtIndex:i];

			if ([object respondsToSelector:postAwakeFromNib])
				{
				IMP imp = [object methodForSelector:postAwakeFromNib];
				void (*func)(id, SEL) = (void *)imp;
				func(object, postAwakeFromNib);
				}
			}

		// One day, perhaps...
		// [[objectData visibleWindows] makeObjectsPerformSelector:
		//  @selector(makeKeyAndOrderFront:) withObject:nil];

		_nameTable=nil;
		}

    return (objectData!=nil);
	}

/*****************************************************************************\
|* Another entry method, go do it all
\*****************************************************************************/
- (BOOL)instantiateNibWithOwner:owner
				topLevelObjects:(NSArray *_Nullable*_Nullable)objects;
	{
    NIBDEBUG(@"instantiateNibWithOwner: %@ topLevelObjects: ", owner);

	NSMutableArray * topLevelObjects = (objects != NULL)
									 ? [NSMutableArray new]
									 : nil;
	NSDictionary *nameTable	=
		@{
		AZNibOwner 				: owner,
		AZNibTopLevelObjects	: topLevelObjects
		};

	BOOL result = [self instantiateNibWithExternalNameTable:nameTable];

	if ((objects != NULL) && result)
		*objects = [NSArray arrayWithArray:topLevelObjects];

	return result;
	}

@end
