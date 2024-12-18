//
//  AZControl.m
//  Azoth
//
//  Created by Simon Gornall on 12/15/24.
//

#import "AZControl.h"

@implementation AZControl

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super initWithFrame:frame])
		{
		self.stringValue 	= @"";
		self.state		 	= ControlStateNormal;
		_enabled			= YES;
		_continuous			= NO;
		}
	return self;
	}


/*****************************************************************************\
|* Manage the state
\*****************************************************************************/
- (void) setEnabled:(BOOL)yn
	{
	if (_enabled != yn)
		[self setNeedsDisplay:YES];
	_enabled = yn;
	self.state = (_enabled) ? ControlStateNormal : ControlStateDisabled;
	}

/*****************************************************************************\
|* Send actions to targets
\*****************************************************************************/
- (void) sendAction:(SEL)action to:(NSObject *)target
	{
	if ((target != nil) && (action != nil))
		{
		IMP imp = [target methodForSelector:action];
		void (*func)(id, SEL, id) = (void *)imp;
		func(target, action, self);
		}
	}

/*****************************************************************************\
|* Default actions for set...
\*****************************************************************************/
- (void) setDoubleValue:(double)doubleValue
	{
	_doubleValue = doubleValue;
	[self setNeedsDisplay:YES];
	}

- (void) setStringValue:(NSString *)string
	{
	_stringValue = string;
	[self setNeedsDisplay:YES];
	}

@end
