//
//  RsrcMaker.m
//  genRsrc
//
//  Created by Simon Gornall on 12/15/24.
//

#import <SDL3/SDL.h>
#import <SDL3_image/SDL_image.h>

#import "RsrcMaker.h"

@interface RsrcMaker()
@property(strong, nonatomic) NSMutableArray<NSString *> *			help;
@property(strong, nonatomic) NSMutableDictionary *					meta;
@property(assign, nonatomic) int									x;
@property(assign, nonatomic) int									y;
@property(assign, nonatomic) int									maxH;
@property(assign, nonatomic) int									w;
@property(assign, nonatomic) int									h;
@end

@implementation RsrcMaker

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithArgs:(NSArray *)args
	{
	if (self = [super init])
		{
		_meta	= [NSMutableDictionary new];
		_help 	= [NSMutableArray new];
		[_help addObject:@"Usage: genRsrc <options> where options are from:\n"];
		[self _process:args];
		}
	return self;
	}

/*****************************************************************************\
|* Process the arguments and run the program
\*****************************************************************************/
- (void) _process:(NSArray *)args
	{
	NSString *rsrc = [[NSBundle bundleForClass:[self class]] resourcePath];
	NSString *src = [self _findArg:@"-d"
						  longform:@"--source-dir"
							  from:args
						    reason:@"specify the source directory"
					   withDefault:rsrc];

	NSString *output = [self _findArg:@"-o"
						  longform:@"--output-file-stem"
							  from:args
						    reason:@"specify the output file stem"
					   withDefault:@"rsrc"];

	NSString *oWidth = [self _findArg:@"-x"
						     longform:@"--output-x-size"
						   	     from:args
							   reason:@"width of the atlas image (512)"
					      withDefault:@"512"];

	NSString *oHeight = [self _findArg:@"-y"
						      longform:@"--output-y-size"
							      from:args
						        reason:@"height of the atlas image (512)"
					       withDefault:@"512"];

	BOOL help 		 = [self _findFlag:@"-h"
							  longform:@"--help"
							      from:args
								reason:@"This wonderful help"];
	if (help)
		[self _usage];

	/*************************************************************************\
	|* Create the atlas texture
	\*************************************************************************/
	_w = oHeight.intValue;
	_h = oWidth.intValue;
	SDL_Surface *atlas = SDL_CreateSurface(_w, _h, SDL_PIXELFORMAT_ABGR8888);
	if (!atlas)
		{
		SDL_Log("Cannot create surface of size %dx%d", _w, _h);
		exit(0);
		}

	/*************************************************************************\
	|* Read the images and copy to the atlas
	\*************************************************************************/
	NSFileManager *fm 		   = NSFileManager.defaultManager;
	NSError *error  		   = nil;
	NSArray<NSString *> *paths = [fm contentsOfDirectoryAtPath:src error:&error];
	for (NSString *path in paths)
		{
		NSString *fullpath = [NSString stringWithFormat:@"%@/%@", src, path];
		[self _copy:fullpath to:atlas];
		}

	/*************************************************************************\
	|* Write out the atlas
	\*************************************************************************/
	NSString *oFile = [NSString stringWithFormat:@"%@.png", output];
	NSLog(@"Saving to %@", oFile);
	IMG_SavePNG(atlas, oFile.UTF8String);
	SDL_DestroySurface(atlas);

	/*************************************************************************\
	|* Write out the metadata
	\*************************************************************************/
	oFile = [NSString stringWithFormat:@"%@.plist", output];
	[_meta writeToFile:oFile atomically:NO];
	}

/*****************************************************************************\
|* Copy a PNG to the atlas image
\*****************************************************************************/
- (void) _copy:(NSString *)png to:(SDL_Surface *)img
	{
	SDL_Surface *glyph = IMG_Load(png.fileSystemRepresentation);
	int w = glyph->w;
	int h = glyph->h;

	if (_x + w > _w)
		{
		if (_y + h > _h)
			{
			SDL_Log("Aborting, cannot fit image into atlas");
			exit(0);
			}
		_y += _maxH;
		_x  = 0;
		_maxH = 0;
		}

	// Create the metadata
	NSDictionary *info =
		@{
			@"x" : [NSNumber numberWithInt:_x],
			@"y" : [NSNumber numberWithInt:_y],
			@"w" : [NSNumber numberWithInt:w],
			@"h" : [NSNumber numberWithInt:h],
		};
	NSString *name = [png lastPathComponent];
	name = [name stringByDeletingPathExtension];
	_meta[name] = info;

	// Blit the image
	_maxH = (h > _maxH) ? h : _maxH;
	SDL_Rect dst = (SDL_Rect){_x, _y, w, h};
	SDL_BlitSurface(glyph, NULL, img, &dst);
	SDL_DestroySurface(glyph);
	_x += w+1;
	}

/*****************************************************************************\
|* Find an argument in the list and register the help text too
\*****************************************************************************/
- (NSString *) _findArg:(NSString *)option
			   longform:(NSString *)longOpt
			       from:(NSArray<NSString *> *)args
			     reason:(NSString *)info
			withDefault:(NSString *)dflt
	{
	NSString *help = [NSString stringWithFormat:@"  %@|%@", option, longOpt];
	help = [help stringByPaddingToLength:25 withString:@" " startingAtIndex:0];
	help = [NSString stringWithFormat:@"%@:%@", help, info];
	[_help addObject:help];

	int idx = 1;
	for (NSString *item in args)
		{
		BOOL found = [item isEqualToString:option]
				  || [item isEqualToString:longOpt];
		if (found && idx < args.count)
			return args[idx];
		idx ++;
		}
	return dflt;
	}

/*****************************************************************************\
|* Find an argument in the list and register the help text too
\*****************************************************************************/
- (BOOL) _findFlag:(NSString *)option
	      longform:(NSString *)longOpt
		      from:(NSArray<NSString *> *)args
		    reason:(NSString *)info
	{
	NSString *help = [NSString stringWithFormat:@"  %@|%@", option, longOpt];
	help = [help stringByPaddingToLength:25 withString:@" " startingAtIndex:0];
	help = [NSString stringWithFormat:@"%@: %@", help, info];
	[_help addObject:help];

	for (NSString *item in args)
		{
		if ([item isEqualToString:option] || [item isEqualToString:longOpt])
			return YES;
		}
	return NO;
	}

/*****************************************************************************\
|* Show the generated help text and die
\*****************************************************************************/
- (void) _usage
	{
	for (NSString *line in _help)
		printf("%s\n", line.UTF8String);
	exit(0);
	}

@end
