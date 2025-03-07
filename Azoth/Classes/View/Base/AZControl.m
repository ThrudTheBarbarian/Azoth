//
//  AZControl.m
//  Azoth
//
//  Created by ThrudTheBarbarian on 12/15/24.
//

#import <SDL3/SDL.h>

#import "AZApplication.h"
#import "AZControl.h"
#import "AZZib.h"

@implementation AZControl

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super initWithFrame:frame])
		{
		self.stringValue 	= @"";
		self.state		 	= AZControlStateNormal;
		_enabled			= YES;
		_continuous			= NO;
		_font				= AZApp.controlFont;
		_fpFormat			= @"%.2f";
		}
	return self;
	}

/*****************************************************************************\
|* Configuration via dictionary. This is called by the NIB loader, but is a
|* valid way to create the view
\*****************************************************************************/
- (instancetype) initWithDictionary:(NSDictionary *)info;
	{
	if (self = [super initWithDictionary:info])
		{
		self.stringValue 	= @"";
		self.state		 	= AZControlStateNormal;
		_enabled			= YES;
		_font				= AZApp.controlFont;
		_fpFormat			= @"%.2f";

		_continuous			=  ([info[kZibContinuous] isEqualToString:@"YES"])
							? YES : NO;
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
	self.state = (_enabled) ? AZControlStateNormal : AZControlStateDisabled;
	}

- (void) setState:(AZControlState)state
	{
	_state = state;
	[self setNeedsDisplay:YES];
	}
	
/*****************************************************************************\
|* Send actions to targets
\*****************************************************************************/
- (void) sendAction:(SEL)action to:(NSObject *)target
	{
	if ((target != nil) && (action != nil))
		{
		if ([target respondsToSelector:action])
			{
			IMP imp = [target methodForSelector:action];
			void (*func)(id, SEL, id) = (void *)imp;
			func(target, action, self);
			}
		else
			SDL_Log("Target %s does not respond to selector %s",
					target.description.UTF8String,
					NSStringFromSelector(action).UTF8String);
		}
	}

/*****************************************************************************\
|* Default actions for set...
\*****************************************************************************/
- (void) setDoubleValue:(double)doubleValue
	{
	[self setStringValue:[NSString stringWithFormat:@"%f", doubleValue]];
	}

- (void) setStringValue:(NSString *)string
	{
	_stringValue = string;
	[self setNeedsDisplay:YES];
	}

- (void) setIntValue:(int)intValue
	{
	[self setStringValue:[NSString stringWithFormat:@"%d", intValue]];
	}

/*****************************************************************************\
|* Default actions for get...
\*****************************************************************************/
- (double) doubleValue
	{
	return self.stringValue.doubleValue;
	}

- (int) intValue
	{
	return self.stringValue.intValue;
	}

/*****************************************************************************\
|* Change the floating point format
\*****************************************************************************/
- (void) setFloatingPointFormatLeft:(int)left right:(int)right
	{
	_fpFormat = [NSString stringWithFormat:@"%%%d.%df", left, right];
	}

@end
