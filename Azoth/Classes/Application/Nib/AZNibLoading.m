//
//  AZNibLoading.m
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import <SDL3/SDL.h>

#import "AZNib.h"
#import "AZNibLoading.h"
#import "AZTypes.h"

@implementation NSObject(NSNibLoading)

/*****************************************************************************\
|* Create a default awakeFromNib on NSObject so we don't get crashes when the
|* method is called on an unsuspecting object
\*****************************************************************************/
-(void)awakeFromNib
	{
	// do nothing
	}

@end

@implementation NSBundle(NSNibLoading)

/*****************************************************************************\
|* Class method: Load a NIB, linking the external name table
\*****************************************************************************/
+ (BOOL) loadNibFile:(NSString *)path
   externalNameTable:(NSDictionary *)nameTable
			withZone:(NSZone *)zone
	{
    NIBDEBUG(@"+ loadNibFile: '%@' externalNameTable: withZone:", path);

	BOOL result = NO;

	@autoreleasepool
		{
		AZNib *nib  = [[AZNib allocWithZone:zone] initWithContentsOfFile:path];
		result 		= [nib instantiateNibWithExternalNameTable:nameTable];
		}

	return result;
	}

/*****************************************************************************\
|* Class method: Load a NIB, assigning to an owner
\*****************************************************************************/
+ (BOOL)loadNibNamed:(NSString *)name owner:(id)owner
	{
    NIBDEBUG(@"+ loadNibNamed: '%@'", name);
    
	NSBundle     *bundle	= [NSBundle bundleForClass:[owner class]];
	NSDictionary *nameTable	= [NSDictionary dictionaryWithObject:owner
														  forKey:AZNibOwner];

	return [bundle loadNibFile:name
			 externalNameTable:nameTable
					  withZone:NSDefaultMallocZone()];
	}


/*****************************************************************************\
|* Instance method: Load a NIB, linking the external name table
\*****************************************************************************/
- (BOOL) loadNibFile:(NSString *)fileName
   externalNameTable:(NSDictionary *)nameTable
			withZone:(NSZone *)zone
	{
	BOOL result = NO;

	@autoreleasepool
		{
		NIBDEBUG(@"- loadNibNamed:'%@' externalNameTable:withZone:", fileName);

		NSString* path = nil;

		// Build a full path if it's not yet
		if (fileName.stringByDeletingLastPathComponent.length == 0)
			{
			NSString *name 		= fileName.copy;
			name 				= [name stringByDeletingPathExtension];
			NSBundle *bundle	= self;
			NSString *platform	= [name stringByAppendingFormat:@"-%s",
									AZPlatformResourceNameSuffix];

			path=[bundle pathForResource:platform ofType:@"nib"];

			if (path == nil)
				path=[[NSBundle mainBundle] pathForResource:platform
													 ofType:@"nib"];

			if (path == nil)
				path = [bundle pathForResource:name ofType:@"nib"];

			if (path == nil)
				path = [NSBundle.mainBundle pathForResource:name ofType:@"nib"];
			}
		else
			{
			SDL_Log("warning: full path (%s) passed to -loadNibFile when only "
					"nib file name should be used", fileName.UTF8String);
			path = fileName;
			}

		AZNib *nib 	= [[AZNib allocWithZone:zone] initWithContentsOfFile:path];
		result		= [nib instantiateNibWithExternalNameTable:nameTable];
		}
	return result;
	}

@end
