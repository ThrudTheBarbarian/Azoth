//
//  AZViewController.m
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import <SDL3/SDL.h>

#import "AZViewController.h"

@implementation AZViewController

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithNibName:(NSString *)name
						  bundle:(nullable NSBundle*)bundle
	{
	if (self = [super init])
		{
		_nibName 	= name;
		_bundle		= bundle;
		}
	return self;
	}

/*****************************************************************************\
|* Initialisation with a coder
\*****************************************************************************/
- (instancetype) initWithCoder:(NSCoder *)coder
	{
	if (coder.allowsKeyedCoding)
		{
		_nibName = [coder decodeObjectForKey:@"NSNibName"];
		_title   = [coder decodeObjectForKey:@"NSTitle"];

		NSString *bundleId = [coder decodeObjectForKey:@"NSNibBundleIdentifier"];
		if (bundleId)
			_bundle = [NSBundle bundleWithIdentifier:bundleId];
		}

	return self;
	}

/*****************************************************************************\
|* If our view is requested, make sure it's loaded
\*****************************************************************************/
- (AZView *)view
	{
	if (_view == nil)
		[self loadView];
	return _view;
	}

/*****************************************************************************\
|* Load the view
\*****************************************************************************/
- (void) loadView
	{
	NSString *name		= self.nibName;
	NSBundle *bundle	= self.bundle;

	if(name == nil)
		{
		[NSException raise:NSInvalidArgumentException
					format:@"-[%@ %@] nibName is nil",
					self.class.description,
					NSStringFromSelector(_cmd)];
		return;
		}
   
	if (bundle == nil)
		bundle = [NSBundle mainBundle];

	NSString *path 			= [bundle pathForResource:name ofType:@"nib"];
//	NSDictionary *nameTable = [NSDictionary dictionaryWithObject:self
//														  forKey:NSNibOwner];

   if (path == nil)
		SDL_Log("AZViewController unable to find nib named %s, bundle=%s",
				name.UTF8String, bundle.description.UTF8String);

  // [bundle loadNibFile:path externalNameTable:nameTable withZone:NULL];
}

@end
