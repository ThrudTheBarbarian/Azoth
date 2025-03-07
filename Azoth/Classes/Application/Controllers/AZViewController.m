//
//  AZViewController.m
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/1/25.
//

#import <SDL3/SDL.h>

#import "AZViewController.h"
#import "NSBundle+ZIB.h"

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

- (instancetype) initWithView:(AZView *)view
	{
	if (self = [super init])
		{
		_view = view;
		}
	return self;
	}

/*****************************************************************************\
|* Initialisation with a dictionary (our version of Coder)
\*****************************************************************************/
- (instancetype) initWithDictionary:(NSDictionary *)info
	{
	_nibName 			= info[@"NSNibName"];
	_title   			= info[@"NSTitle"];
	NSString *bundleId = info[@"NSNibBundleIdentifier"];
	if (bundleId)
		_bundle = [NSBundle bundleWithIdentifier:bundleId];
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
	if (_view == nil)
		{
		NSString *name		= self.nibName;
		NSBundle *bundle	= self.bundle;

		if (name == nil)
			{
			[NSException raise:NSInvalidArgumentException
						format:@"-[%@ %@] nibName is nil",
						self.class.description,
						NSStringFromSelector(_cmd)];
			return;
			}

		if (bundle == nil)
			bundle = NSBundle.mainBundle;
		[bundle loadZibNamed:name owner:self topLevelObjects:nil];
		}
	}

@end
