//
//  AZView+Internal.m
//  Azoth
//
//  Created by Simon Gornall on 12/12/24.
//

#import <Foundation/Foundation.h>
#import <SDL3/SDL.h>

#import "AZApp.h"
#import "AZColour.h"
#import "AZGeometry.h"
#import "AZPainter.h"
#import "AZView.h"
#import "AZView+Internal.h"
#import "AZWindow.h"

@implementation AZView (Internal)


/*****************************************************************************\
|* Process a mouse event through the subview list recursively, seeing if the
|* view wants to handle it
\*****************************************************************************/
- (BOOL) processMouseEvent:(SDL_Event *)e atPoint:(NSPoint)p
	{
	static AZView * dragView = nil;

	/*************************************************************************\
	|* We do a depth-first search (so all subviews first), procedure is:
	|*  - Does the event co-ordinate lie within the subview
	|*  - if so, does -hitTest() respond back with YES (does by default)
	|*  - if so, does the specific mouse-handler return YES ?
	|*  - if so, we're done
	|*  - if not, loop to next subview
	|*  - if all subviews deny the event, then try ourselves (since this is a
	|*    recursive call)
	|*  - return whether handled
	\*************************************************************************/

	BOOL done 	= NO;
	for (AZView *subview in self.subviews)
		{
		done = [subview processMouseEvent:e atPoint:p];
		if (done)
			break;
		}

	/*************************************************************************\
	|* This is where we do the test and propagate 'done' back up the callchain
	\*************************************************************************/
	if (!done)
		{
		NSRect global 	= [self frame];
		global.origin	= [self convertPoint:global.origin toView:nil];

		if (NSPointInRect(p, global))
			{
			NSPoint local	= [self convertPoint:p fromView:nil];

			if ([self hitTestAtPoint:local])
				{
				SDL_MouseMotionEvent *mme = (SDL_MouseMotionEvent *)e;
				SDL_MouseButtonEvent *mbe = (SDL_MouseButtonEvent *)e;
				SDL_MouseWheelEvent  *mwe = (SDL_MouseWheelEvent *)e;

				switch (e->type)
					{
					case SDL_EVENT_MOUSE_BUTTON_DOWN:
						done = [self mouseDown:mbe];
						dragView = self;
						break;

					case SDL_EVENT_MOUSE_BUTTON_UP:
						done = (dragView != nil)
							 ? [dragView mouseUp:mbe]
							 : [self mouseUp:mbe];
						dragView = nil;
						break;

					case SDL_EVENT_MOUSE_MOTION:
						// If we're no longer pressing the button, we might
						// have dragged out of window and released it. Zero out
						// the dragging-view
						if ((mme->state & SDL_BUTTON_LEFT) == 0)
							dragView = nil;

						done = (dragView != nil)
							 ? [dragView mouseDragged:mme]
							 : [self mouseMoved:mme];
						break;

					case SDL_EVENT_MOUSE_WHEEL:
						done = [self mouseWheeled:mwe];
						break;

					default:
						SDL_Log("Got unknown mouse event type:%d", e->type);
						break;
					}
				}
			}
		}

	return done;
	}



/*****************************************************************************\
|* Rendering: Install a SDL_Texture as backing for the view. We choose between
|*
|*  - If the view is a contentView for a window, and that window is of fixed
|*    size, then we choose a texture of that fixed size. Do not call
|*    SDL_SetWindowResizable, set it to be resizeable from the start
|*
|*  - If the view is a contentView for a window, and that window is resizeable
|*    then we choose the size of the primary display as the backing texture
|*    size. Yes this is wasteful, but it means we can cope with resize..
|*
|*  - If the view is not a top-level view, we set the size of the backing
|*    texture to be the view's initial frame size. We catch resizing > existing
|*    size when performing a resize op and will deallocate/reallocate a
|*    backing texture. This isn't wonderful, but it's the tradeoff against
|*    making every texture screen-sized...
\*****************************************************************************/
- (BOOL) _installBackingTexture
	{
	BOOL ok = YES;
	int w	= 0;
	int h	= 0;

	/*************************************************************************\
	|* The content-view case
	\*************************************************************************/
	if (self.superview == nil)
		{
		BOOL resize = NO;
		NSUInteger windowFlags = SDL_GetWindowFlags(self.window.window);
		if (windowFlags & SDL_WINDOW_RESIZABLE)
			resize = YES;

		if (resize)
			{
			SDL_DisplayID dpy = SDL_GetPrimaryDisplay();

			SDL_Rect bounds;
			SDL_GetDisplayUsableBounds(dpy, &bounds);
			w = bounds.w;
			h = bounds.h;
			}
		else
			{
			if (!SDL_GetWindowMaximumSize(self.window.window, &w, &h))
				{
				ok = NO;
				SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
							 "Failed to get window max size : %s",
							 SDL_GetError());
				}
			}
		}

	/*************************************************************************\
	|* Everything else
	\*************************************************************************/
	else
		{
		w = self.frame.size.width;
		h = self.frame.size.height;
		}

	/*************************************************************************\
	|* Create the texture if we can
	\*************************************************************************/
	if (w*h > 0)
		{
		SDL_Renderer *renderer = AZApp.sharedInstance.window.renderer;
		if (self.bg)
			SDL_DestroyTexture(self.bg);

		self.bg		 = SDL_CreateTexture(renderer,
										 SDL_PIXELFORMAT_RGBA8888,
										 SDL_TEXTUREACCESS_TARGET,
										 w,
										 h);

		/*********************************************************************\
		|* Cue up a 'clear this texture' operation when the next render-
		|* presentation happens
		\*********************************************************************/
		SDL_SetRenderTarget(renderer, self.bg);
		SDL_SetRenderDrawColor(renderer, self.bgColour.red,
										 self.bgColour.green,
										 self.bgColour.blue,
										 1.f);
		SDL_RenderClear(renderer);
		SDL_FRect area = SDLFRectFromNSRect(self.bounds);
		SDL_RenderRect(renderer,&area);
		SDL_SetRenderTarget(renderer, NULL);

		/*********************************************************************\
		|* And tell the view it needs to redraw
		\*********************************************************************/
		self.dirty = self.bounds;
		}

	return ok;
	}


/*****************************************************************************\
|* Rendering: Render the texture to the screen.
\*****************************************************************************/
- (void) _renderToScreen
	{
	SDL_Renderer *renderer = AZApp.sharedInstance.window.renderer;

	/*************************************************************************\
	|* Draw to the screen
	\*************************************************************************/
	SDL_SetRenderTarget(renderer, NULL);

	/*************************************************************************\
	|* Set up the frame correctly
	\*************************************************************************/
	NSRect frame  	= self.frame;
	NSPoint p		= [self convertPoint:frame.origin toView:nil];
	frame.origin	= p;

	/*************************************************************************\
	|* Work out source, destination and clip
	\*************************************************************************/
	SDL_FRect src 	= SDLFRectFromNSRect(self.bounds);
	SDL_FRect dst	= SDLFRectFromNSRect(frame);

	// We also want to clip to the parent view's frame
	NSRect parent	= self.superview.frame;
	p 				= [self.superview convertPoint:parent.origin toView:nil];
	parent.origin	= p;
	parent 			= NSIntersectionRect(parent, frame);

	SDL_Rect clip	= SDLRectFromNSRect(parent);


	/*************************************************************************\
	|* Handle the transparency of alpha
	\*************************************************************************/
	SDL_BlendMode mode = self.isOpaque ? SDL_BLENDMODE_NONE
									   : SDL_BLENDMODE_ADD_PREMULTIPLIED;
	SDL_SetRenderDrawBlendMode(renderer, mode);

	/*************************************************************************\
	|* Draw ourselves first...
	\*************************************************************************/
	SDL_SetRenderClipRect(renderer, &clip);
	SDL_RenderTexture(renderer, self.bg, &src, &dst);
	SDL_SetRenderClipRect(renderer, NULL);

	/*************************************************************************\
	|* ... then call the subviews recursively in reverse order
	\*************************************************************************/
	for (AZView *subview in [self.subviews reverseObjectEnumerator])
		{
		SDL_BlendMode mode = subview.isOpaque ? SDL_BLENDMODE_NONE
											  : SDL_BLENDMODE_ADD_PREMULTIPLIED;
		SDL_SetRenderDrawBlendMode(renderer, mode);
		[subview _renderToScreen];
		}
	}


/*****************************************************************************\
|* Update the current view and then all its subviews in-order
\*****************************************************************************/
- (void) _redrawViewAndSubviews
	{
	if (!NSEqualRects(self.dirty, NSZeroRect))
		[self _drawDirtyRect];

	for (AZView *view in self.subviews)
		[view _redrawViewAndSubviews];
	}

/*****************************************************************************\
|* Actually draw the dirty-rect
\*****************************************************************************/
- (void) _drawDirtyRect
	{
	AZPainter *painter = [AZPainter painterForView:self];
	[painter execute];
	}

@end
