//
//  AppDelegate.m
//  NibTest
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import "AppDelegate.h"

/*****************************************************************************\
|* Types used by the noise pipeline
\*****************************************************************************/
typedef struct
	{
	float 		height;				// The Z-value of the perlin noise
	float 		period;				// Repeatable limit, after which we wrap
	float 		persistence;		// octave persistence for perlin noise
	uint32_t	octaves;			// Number of octaves
	float 		threshold;			// Below which, there is only darkness
	uint32_t	seed;				// Cubic seed value in random generator
	uint32_t	cperiod;			// Cubic spatial domain extent
	uint32_t 	algorithms;			// Which noise algorithms to use
	} NoiseUniforms;


#define ROW_HEIGHT  (35.f)

/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AppDelegate ()

// From the ZIB file
@property (strong) IBOutlet AZImageView *						output;
@property (strong) IBOutlet AZImageView *						tile;
@property (strong) IBOutlet AZImageView *						map;
@property (strong) IBOutlet AZSlider *							threshold;
@property (strong) IBOutlet AZSlider *							period;
@property (strong) IBOutlet AZSlider *							height;
@property (strong) IBOutlet AZSlider *							persist;
@property (strong) IBOutlet AZPopupButton *						octaves;

// The path to the input tile
@property (copy, nonatomic) NSString *							tilePath;

// The output image from the shader
@property (strong, nonatomic) AZImage *							result;

// The map image, only a is used in the shader
@property (strong, nonatomic) AZImage *							mapImage;

// The compute pipeline for the shader
@property (strong, nonatomic) AZComputePipeline *				noisePL;

// Samplers for the input tile and regions-map
@property (strong, nonatomic) AZSampler *						tileSampler;
@property (strong, nonatomic) AZSampler *						mapSampler;

@end

@implementation AppDelegate

/*****************************************************************************\
|* Application entry point
\*****************************************************************************/
- (void) applicationDidFinishLaunching:(NSNotification *)notification
	{
	/*************************************************************************\
	|* Create an initial white image for the result
	\*************************************************************************/
	_result = [AZImage imageWithSize:NSMakeSize(4096, 4096)];
	AZPainter *painter = [_result lockFocus:NO];
	[painter rectangleWithRect:_result.bounds
						filled:YES
						colour:AZColour.white];
	[_result unlockFocusWithPainter:painter];
	_output.image = _result;

	/*************************************************************************\
	|* Create an initial black image for the result
	\*************************************************************************/
	NSSize imgSize 	= _result.bounds.size;
	_mapImage 		= [AZImage imageWithSize:imgSize];

	id<AZRenderer> azr  = AZRenderer.renderer;
	[azr setTexture:_mapImage.texture blendMode:SDL_BLENDMODE_NONE];
	[self SetMapToUnityPressed:self];

	/*************************************************************************\
	|* Create the noise compute pipeline
	\*************************************************************************/
	AZComputeStorageInfo info =
		{
		.roBuffers  = 0,
		.rwBuffers  = 0,
		.roTextures = 0,
		.rwTextures = 1,
		.samplers   = 2
		};

	_noisePL = [AZComputePipeline pipelineNamed:@"noise"
										storage:info
										threads:(AZThreadSize){8,8,1}];
	[_noisePL build];

	/*************************************************************************\
	|* Create the sampler for the tile
	\*************************************************************************/
	_tileSampler = [AZSampler withMinFilter:SDL_GPU_FILTER_NEAREST
								  magFilter:SDL_GPU_FILTER_NEAREST
								 mipMapMode:SDL_GPU_SAMPLERMIPMAPMODE_NEAREST
								addressMode:SDL_GPU_SAMPLERADDRESSMODE_REPEAT];
	[_tileSampler build];

	/*************************************************************************\
	|* Create the sampler for the regions-map
	\*************************************************************************/
	_mapSampler = [AZSampler withMinFilter:SDL_GPU_FILTER_NEAREST
								 magFilter:SDL_GPU_FILTER_NEAREST
								mipMapMode:SDL_GPU_SAMPLERMIPMAPMODE_NEAREST
							   addressMode:SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE];
	[_mapSampler build];
	}


// MARK: Actions from the UI controls

/*****************************************************************************\
|* User wants to load a tile
\*****************************************************************************/
- (IBAction) loadInputTilePressed:(id)sender
	{
	const char *path = _tilePath.fileSystemRepresentation;
	SDL_ShowOpenFileDialog(tileCallback,		// Called on completion
						   NULL,				// Passed to callback
						   self.window.window, 	// Modal for this window
						   NULL, 				// The filter above
						   0, 					// Number of filters
						   path, 				// Default location
						   NO);					// Allow many files
	}

/*****************************************************************************\
|* User wants to load a map
\*****************************************************************************/
- (IBAction) loadInputMapPressed:(id)sender
	{
	}

/*****************************************************************************\
|* User wants to set the map to unity
\*****************************************************************************/
- (IBAction) SetMapToUnityPressed:(id)sender
	{
	AZPainter *painter = [_mapImage lockFocus:NO];
	[painter rectangleWithRect:_mapImage.bounds
						filled:YES
						colour:AZColour.black];
	[_mapImage unlockFocusWithPainter:painter];
	_map.image = _mapImage;
	}

/*****************************************************************************\
|* User wants to set the number of octaves
\*****************************************************************************/
- (IBAction) octavesChanged:(id)sender
	{
	[self _process];
	}

/*****************************************************************************\
|* User wants to set the low-level threshold
\*****************************************************************************/
- (IBAction) thresholdChanged:(id)sender
	{
	[self _process];
	}

/*****************************************************************************\
|* User wants to set the %age of the image width that represents the period
\*****************************************************************************/
- (IBAction) periodChanged:(id)sender
	{
	[self _process];
	}

/*****************************************************************************\
|* User wants to set the height above the noise-field
\*****************************************************************************/
- (IBAction) heightChanged:(id)sender
	{
	[self _process];
	}

/*****************************************************************************\
|* User wants to set the persistence of a noise-field octave
\*****************************************************************************/
- (IBAction) persistenceChanged:(id)sender
	{
	[self _process];
	}



// MARK: Callbacks

/*****************************************************************************\
|* We want to find the tile path
\*****************************************************************************/
static void tileCallback(void *userData, const char * const *files, int filter)
    {
	AppDelegate *ad = (AppDelegate *)AZApp.delegate;

	if (files == NULL)
		SDL_Log("Cannot read file: %s", SDL_GetError());
	else if (files[0] != NULL)
        ad.tilePath = [NSString stringWithUTF8String:files[0]];

	// If no result above, then user cancelled the op. Just ignore
	}



// MARK: Property overrides

/*****************************************************************************\
|* When this is called, we set the image view as well
\*****************************************************************************/
- (void) setTilePath:(NSString *)tilePath
	{
	_tilePath 		= tilePath;
	AZImage *img 	= [AZImage imageWithContentsOfFile:tilePath];
	_tile.image		= img;
	[self _process];
	}



// MARK: Private methods

/*****************************************************************************\
|* Run the compute shader
\*****************************************************************************/
- (void) _process
	{
	AZRenderer3d *azr			= (AZRenderer3d *)AZRenderer.renderer;

	if (_tile.image)
		{
		AZTexture *imgTexture	= _tile.image.asTexture;
		AZTexture *rgnTexture	= _map.image.asTexture;

		int algorithms 			= 4;	// Use the map to mask out the noise

		[_noisePL reset];
		[_noisePL addSampler:_tileSampler forTexture:imgTexture];
		[_noisePL addSampler:_mapSampler forTexture:rgnTexture];
		[_noisePL addOutputTexture:_result.asTexture];

		NoiseUniforms nu =
			{
			.height 		= _height.doubleValue,
			.period 		= _period.doubleValue * _tile.image.width,
			.persistence	= _persist.doubleValue / 100.f,
			.octaves		= (uint32_t)_octaves.selectedItem.tag,
			.threshold		= _threshold.doubleValue / 100.f,
			.seed			= 0,
			.cperiod		= 0,
			.algorithms		= algorithms + 1
			};

		[azr dispatchComputePipeline:_noisePL
					 withUniformData:&nu
							ofLength:sizeof(nu)];
		[_map setNeedsDisplay:YES];
		}
	}


@end
