//
//  AZWindowTemplate.m
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import "AZTypes.h"
#import "AZView.h"
#import "AZWindow.h"
#import "AZWindowTemplate.h"

/*****************************************************************************\
|* Private API on AZWindow
\*****************************************************************************/
@interface AZWindow(private)
+ (BOOL) hasMainMenuForStyleMask:(NSUInteger)styleMask;
@end

@implementation AZWindowTemplate
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithCoder:(NSCoder *)coder
	{
	if (coder.allowsKeyedCoding)
		{
		NSKeyedUnarchiver *keyed = (NSKeyedUnarchiver *)coder;
    
		_maxSize 			= [keyed decodeSizeForKey:@"NSMaxSize"];
		_minSize 			= [keyed decodeSizeForKey:@"NSMinSize"];
		_screenRect 		= [keyed decodeRectForKey:@"NSScreenRect"];
		_viewClass 			= [keyed decodeObjectForKey:@"NSViewClass"];
		_wtFlags 			= [keyed decodeIntForKey:@"NSWTFlags"];
		_windowBacking 		= [keyed decodeIntForKey:@"NSWindowBacking"];
		_windowClass 		= [keyed decodeObjectForKey:@"NSWindowClass"];
		_windowRect 		= [keyed decodeRectForKey:@"NSWindowRect"];
		_windowStyleMask 	= [keyed decodeIntForKey:@"NSWindowStyleMask"];
		_windowTitle 		= [keyed decodeObjectForKey:@"NSWindowTitle"];
		_windowView 		= [keyed decodeObjectForKey:@"NSWindowView"];
		_windowAutosave		= [keyed decodeObjectForKey:@"NSFrameAutosaveName"];

		// compensation for the additional menu bar
		//Class winClass = NSClassFromString(_windowClass);
		//if ([winClass hasMainMenuForStyleMask:_windowStyleMask])
		//	_windowRect.origin.y -= [AZMainMenuView menuHeight];
		}
	else
		{
		[NSException raise:NSInvalidArgumentException
					format:@"%@ can not initWithCoder:%@",
						[self class],
						[coder class]];
		}

	return self;
	}

/*****************************************************************************\
|* Configure, once the coder is done decoding
\*****************************************************************************/
- (id) awakeAfterUsingCoder:(NSCoder *)coder
	{
	AZWindow *result;
	Class     class;

	if ((class = NSClassFromString(_windowClass)) == Nil)
		{
		[NSException raise:NSInvalidArgumentException
					format:@"Unable to find AZWindow class %@, using AZWindow",
					_windowClass];
		class=[AZWindow class];
		}

	BOOL defer = (_wtFlags&0x20000000) ? YES : NO;
	result = [[class alloc] initWithContentRect:_windowRect
								 styleMask:_windowStyleMask
								   backing:_windowBacking
									 defer:defer];
	[result setMinSize:_minSize];
	[result setMaxSize:_maxSize];
	[result setReleasedWhenClosed:(_wtFlags&0x40000000)?NO:YES];
	[result setHidesOnDeactivate:(_wtFlags&0x80000000)?YES:NO];
	[result setTitle:_windowTitle];

	[result setContentView:_windowView];
	[_windowView setAutoresizesSubviews:YES];
	[_windowView setAutoresizingMask:AZViewWidthSizable|AZViewHeightSizable];

	//if([_viewClass isKindOfClass:[AZToolbar class]]) {
	//   [result setToolbar:_viewClass];
	//}

	//if([_windowAutosave length]>0)
	// [result _setFrameAutosaveNameNoIO:_windowAutosave];

	return result;
	}


@end
