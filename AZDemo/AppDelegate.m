//
//  AppDelegate.m
//  AZDemo
//
//  Created by Simon Gornall on 12/14/24.
//

#import <Azoth/Azoth.h>
#import <SDL3/SDL.h>
#include <SDL3_ttf/SDL_ttf.h>

#import "AppDelegate.h"

@implementation AppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)notification
	{
	AZApp *app = [AZApp sharedInstance];

	/*************************************************************************\
    |* Make sure we can initialise
    \*************************************************************************/
    if (!SDL_Init(SDL_INIT_VIDEO))
		{
        SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
		AZApp.sharedInstance.viability = SDL_APP_FAILURE;
		}

	/*************************************************************************\
    |* Create the window
    \*************************************************************************/
    SDL_Window *window;
	SDL_Renderer *renderer;

    if (!SDL_CreateWindowAndRenderer("Demo app",
									 1280,
									 960,
									 SDL_WINDOW_RESIZABLE,
									 &window,
									 &renderer))
		{
        SDL_Log("Couldn't create window/renderer: %s", SDL_GetError());
        AZApp.sharedInstance.viability =  SDL_APP_FAILURE;
		}
	else
		{
		app.window   = window;
		app.renderer = renderer;
		}

	/*************************************************************************\
    |* Initialise fonts
    \*************************************************************************/
    if (!TTF_Init())
		{
        SDL_Log("Couldn't initialize TTF: %s\n",SDL_GetError());
        AZApp.sharedInstance.viability =  SDL_APP_FAILURE;
		}
	
	}

@end
