# AZCompute

This is an (incomplete) demo of how the SDL3 GPU shaders can be harnessed using the 3D renderer. The application must select the renderer type in main.m via the app delegate, before starting up the main loop, similar to:

```
/*****************************************************************************\
|* Callback: This function is called at startup
\*****************************************************************************/
SDL_AppResult SDL_AppInit(void **appstate, int argc, char *argv[])
	{
    SDL_SetAppMetadata("Azoth compute-shader-testing app",
					   "1.0",
					   "com.moebius-tech.azoth");

	/*************************************************************************\
    |* Create the application.
    \*************************************************************************/
	AZApp.delegate		= [AppDelegate new];
	AZApp.initialFrame	= NSMakeRect(50, 50, 1280, 960);
	AZApp.windowFlags	= SDL_WINDOW_RESIZABLE;
	AZApp.rendererType	= AZRendererType3d;
	*appstate			= (__bridge void *)(AZApp);

	[AZApp startWithArgc:argc argv:argv];

	if (AZApp.viability == SDL_APP_CONTINUE)
		{
		/*********************************************************************\
		|* .. carry on with any initialisation
		\*********************************************************************/
		}
    return AZApp.viability;
	}

```

Note the setting of the "rendererType" property on AZApp. 

The application runs as below

<img src=AZCompute.gif width=816>
