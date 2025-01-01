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
#import "AZEvent.h"
#import "AZGeometry.h"
#import "AZPainter.h"
#import "AZRenderer.h"
#import "AZView.h"
#import "AZView+Internal.h"
#import "AZWindow.h"

#import "AZScrollView.h"
#import "AZScroller.h"

@implementation AZView (Internal)


/*****************************************************************************\
|* Process a mouse event through the subview list recursively, seeing if the
|* view wants to handle it
\*****************************************************************************/
- (BOOL) processMouseEvent:(AZEvent *)e
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
	NSPoint p		= e.locationInWindow;
	NSRect global 	= [self visibleRect];
	global			= [self convertRect:global toView:nil];

//	if (e.type == AZLeftMouseDown)
//		NSLog(@"click!");

	BOOL done 	= NO;
	for (AZView *subview in self.subviews)
		{
		// Only want to check against visible rect
		if (NSPointInRect(p, global))
			done = [subview processMouseEvent:e];
		if (done)
			break;
		}

	/*************************************************************************\
	|* This is where we do the test and propagate 'done' back up the callchain
	\*************************************************************************/
	if (!done)
		{
		// We use bounds, not frame, because we'll be adding on this view's
		// frame co-ords as part of the process of finding the point's
		// location in the parent. Since we want the frame itself, we want
		// to start at (0,0)
		global 	= [self bounds];
		global	= [self convertRect:global toView:nil];


		if (NSPointInRect(p, global))
			{
			NSPoint local	= [self convertPoint:p fromView:nil];

			if ([self hitTestAtPoint:local])
				{
				switch (e.type)
					{
					case AZLeftMouseDown:
						done = [self mouseDown:e];
						dragView = self;
						break;

					case AZLeftMouseUp:
						done = (dragView != nil)
							 ? [dragView mouseUp:e]
							 : [self mouseUp:e];
						dragView = nil;
						break;

					case AZMouseMoved:
						// If we're no longer pressing the button, we might
						// have dragged out of window and released it. Zero out
						// the dragging-view
						if ((e.state & AZButtonLeft) == 0)
							dragView = nil;

						done = (dragView != nil)
							 ? [dragView mouseDragged:e]
							 : [self mouseMoved:e];
						break;

					case AZScrollWheel:
						done = [self mouseWheeled:e];
						break;

					default:
						SDL_Log("Got unknown mouse event type:%d", e.type);
						break;
					}
				}
			}
		}

	return done;
	}



/*****************************************************************************\
|* Rendering: Install a texture as backing for the view. We choose between
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
		w = self.textureSize.width;
		h = self.textureSize.height;
		}

	/*************************************************************************\
	|* Create the texture if we can
	\*************************************************************************/
	if (w*h > 0)
		{
		AZRenderer *azr = AZRenderer.renderer;

		SDL_LockMutex(self.textureMutex);
		if (self.bg)
			[azr releaseTexture:self.bg];

		self.bg = [azr createTextureOfSize:NSMakeSize(w,h)];
		SDL_UnlockMutex(self.textureMutex);

		/*********************************************************************\
		|* Cue up a 'clear this texture' operation when the next render-
		|* presentation happens
		\*********************************************************************/
		if ([azr lockFocusOn:self.bg])
			{
			[azr clear];
			AZPainter *p = [AZPainter painterForView:self];
			[p rectangleWithRect:[self bounds]
						  filled:YES
						  colour:self.backgroundColour];
			[azr unlockFocus];
			}
		else
			SDL_Log("Cannot lock focus on texture %d", (int)self.bg);

		/*********************************************************************\
		|* And tell the view it needs to redraw
		\*********************************************************************/
		self.dirty = self.bounds;
		}
	else
		ok = NO;

	return ok;
	}


/*****************************************************************************\
|* Rendering: Render the texture to the screen.
\*****************************************************************************/
- (void) _renderToScreen
	{
	AZRenderer *azr = AZRenderer.renderer;

	/*************************************************************************\
	|* If we are hidden, short-circuit the display routine for ourselves and
	|* all descendents, and return now
	\*************************************************************************/
	if (self.hidden)
		return;
		
	/*************************************************************************\
	|* Draw to the screen
	\*************************************************************************/
	[azr unlockFocus];

	/*************************************************************************\
	|* Set up the frame correctly
	|*
	|* We use bounds, not frame, because we'll be adding on this view's
	|* frame co-ords as part of the process of finding the point's
	|* location in the parent. Since we want the frame itself, we want
	|* to start at (0,0)
	\*************************************************************************/
	NSRect frame  	= self.bounds;
	NSPoint p		= [self convertPoint:frame.origin toView:nil];
	frame.origin	= p;

	/*************************************************************************\
	|* Work out source, destination and clip. Same comment applies to the
	|* 'bounds' vs 'frame' as above.
	\*************************************************************************/
	NSRect src 		= self.bounds;
	NSRect dst		= frame;


	/*************************************************************************\
	|* We also want to clip to the every parent view's frame in the list down
	|* from the window's content-view
	\*************************************************************************/
	AZView *view	= self.superview;
	NSRect clip		= [view convertRect:view.bounds toView:nil];
	while (view.superview != nil)
		{
		view = view.superview;
		NSRect frameClip 	= [view convertRect:view.bounds toView:nil];
		clip				= NSIntersectionRect(clip, frameClip);
		}

	/*************************************************************************\
	|* For views that can grow without bound, the backing texture idea is not
	|* sufficient - because GPUs place limits on texture-sizes. So, we allow
	|* these views to render into a window-sized texture instead.
	|*
	|* If a view returns YES from -(BOOL)directRendering then it is
	|* responsible for drawing as if it were at the correct position, and we
	|* will render from (0,0) +-> (W,H), where W,H come from the clip rect
	\*************************************************************************/
	if (self.directRendering)
		{
		src 	   	= NSMakeRect(0, 0, clip.size.width, clip.size.height);
		dst			= clip;
		}

	if ((src.size.width == 0) || (src.size.height == 0))
		return;
	if ((dst.size.width == 0) || (dst.size.height == 0))
		return;

	/*************************************************************************\
	|* Handle the transparency of alpha
	\*************************************************************************/
	SDL_BlendMode mode = self.isOpaque ? SDL_BLENDMODE_NONE
									   : SDL_BLENDMODE_ADD_PREMULTIPLIED;
	[azr setBlendMode:mode];

	/*************************************************************************\
	|* Draw ourselves first...
	\*************************************************************************/
	SDL_LockMutex(self.textureMutex);
	[azr setClip:clip];
	[azr blitFrom:self.bg src:src dst:dst];
	SDL_UnlockMutex(self.textureMutex);
	
	/*************************************************************************\
	|* ... then call the subviews recursively in reverse order
	\*************************************************************************/
	for (AZView *subview in [self.subviews reverseObjectEnumerator])
		{
		SDL_BlendMode mode = subview.isOpaque ? SDL_BLENDMODE_NONE
											  : SDL_BLENDMODE_ADD_PREMULTIPLIED;
		[azr setBlendMode:mode];
		[subview _renderToScreen];
		}
	[azr unsetClip];
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

/*****************************************************************************\
|* Remove a subview
\*****************************************************************************/
- (void) _removeSubview:(AZView *)subview
	{
	[self.subviews removeObject:subview];
	}

@end
