//
//  AZView.m
//  Azoth
//
//  Created by Simon Gornall on 12/11/24.
//

#import "AZRect.h"
#import "AZView.h"

/*****************************************************************************\
|* Store the top-level content-views for each window we know about
\*****************************************************************************/
static NSMutableDictionary<NSNumber *, AZView *> * _contentViews = nil;

@implementation AZView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(AZRect*)frame
	{
	if (self = [super init])
		{
		_frame 	= frame;
		_bounds	= [AZRect rectWithX:0 y:0 w:_frame.w h:_frame.h];
		}
	return self;
	}

+ (AZView *) viewWithFrame:(AZRect *)frame
	{
	return [[AZView alloc] initWithFrame:frame];
	}

/*****************************************************************************\
|* Return the contentView for any given SDL_Window. If one does not exist it
|* will be created and returned
\*****************************************************************************/
+ (AZView *) contentViewForWindow:(SDL_Window *)window
	{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,
		^{
		_contentViews = [NSMutableDictionary new];
		});

	NSNumber *windowId 		= @(SDL_GetWindowID(window));
	AZView * contentView 	= [_contentViews objectForKey:windowId];
	if (contentView == nil)
		{
		int w, h;
		SDL_GetWindowSize(window, &w, &h);
		AZRect *frame			= [AZRect rectWithX:0 y:0 w:w h:h];
		contentView 			= [AZView viewWithFrame:frame];
		_contentViews[windowId] = contentView;
		}
	return contentView;
	}

@end
