//
//  IdentifiedView.m
//  AZDemo
//
//  Created by Simon Gornall on 12/12/24.
//

#import <Azoth/Azoth.h>
#import <SDL3/SDL.h>
#import <SDL3_image/SDL_image.h>

#import "IdentifiedView.h"

@interface IdentifiedView()
@property (strong, nonatomic) NSString * rsrcDir;
@property (assign, nonatomic) SDL_Surface * surface;

@property (strong, nonatomic) AZSlider *slider;
@property (strong, nonatomic) AZSlider *vslider;
@property (strong, nonatomic) AZSlider *circ;
@property (strong, nonatomic) AZTextField *text;
@property (strong, nonatomic) AZMenu *menu;
@end

@implementation IdentifiedView

- (instancetype) initWithFrame:(NSRect)frame andName:(NSString *)name
	{
	if (self = [super initWithFrame:frame])
		{
		self.identifier = name;
		self.autoresizingMask = AZViewHeightSizable|AZViewWidthSizable;

		_rsrcDir = [[NSBundle bundleForClass:[self class]] resourcePath];

		NSString *path = [_rsrcDir stringByAppendingFormat:@"/texture.png"];
		_surface = IMG_Load([path fileSystemRepresentation]);
		}

	AZButton *btn = [AZButton buttonWithText:@"Button test" at:NSMakePoint(30,220)];
	[btn setTarget:self];
	[btn setAction:@selector(buttonPressed:)];
	[self addSubview:btn];

	NSRect r = NSMakeRect(30, 250, 110, 29);
	_text = [AZTextField textfieldWithFrame:r];
	[_text setTarget:self];
	[_text setAction:@selector(textEntered:)];
	[self addSubview:_text];

	r = NSMakeRect(30, 280, 110, 29);
	_slider = [AZSlider sliderWithFrame:r];
	[_slider setTarget:self];
	[_slider setAction:@selector(sliderValue:)];
	[_slider setContinuous:YES];
	[self addSubview:_slider];

	r = NSMakeRect(150, 220, 29, 80);
	_vslider = [AZSlider sliderWithFrame:r];
	[_vslider setTarget:self];
	[_vslider setAction:@selector(sliderValue:)];
	[_vslider setContinuous:YES];
	[self addSubview:_vslider];

	r = NSMakeRect(180, 220, 30, 30);
	_circ = [AZSlider sliderWithFrame:r];
	[_circ setTarget:self];
	[_circ setAction:@selector(sliderValue:)];
	[_circ setContinuous:YES];
	[self addSubview:_circ];

	_menu = [AZMenu menuWithTitle:@"test menu"];
	[_menu addItemWithTitle:@"item 1" action:nil keyEquivalent:@""];
	[_menu addItemWithTitle:@"item 2" action:nil keyEquivalent:@""];
	[[_menu lastItem] setState:ControlStateValueOn];
	[_menu addItemWithTitle:@"item 3" action:nil keyEquivalent:@""];
	return self;
	}

/*****************************************************************************\
|* Mouse-button-down event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseDown:(struct SDL_MouseButtonEvent *)e
	{
	NSPoint p = NSMakePoint(e->x, e->y);
	p 		  = [self convertPoint:p fromView:nil];

	NSLog(@"Down in %@ at (%d,%d) (from %d,%d)",
		self.identifier, (int)p.x, (int)p.y, (int)e->x, (int)e->y);
	return YES;
	}


/*****************************************************************************\
|* Mouse-button-up event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseUp:(struct SDL_MouseButtonEvent *)e
	{
	NSPoint p = NSMakePoint(e->x, e->y);
	p 		  = [self convertPoint:p fromView:nil];

	NSLog(@"Up in %@ at (%d,%d) (from %d,%d)",
		self.identifier, (int)p.x, (int)p.y, (int)e->x, (int)e->y);
	[[AZWindow contentViewForWindow:self.window] setNeedsDisplay:YES];
	return YES;
	}


/*****************************************************************************\
|* Mouse-dragged event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseDragged:(struct SDL_MouseMotionEvent *)e
	{
	NSPoint p = NSMakePoint(e->x, e->y);
	p 		  = [self convertPoint:p fromView:nil];

	NSLog(@"Dragged in %@ at (%d,%d) (from %d,%d)",
		self.identifier, (int)p.x, (int)p.y, (int)e->x, (int)e->y);
	return YES;
	}

/*****************************************************************************\
|* What to override in subclasses to get a view to draw. This renders into the
|* local texture, so is at (0,0) wrt to that texture. Pixel positioning ought
|* to be perfectly aligned. By default the view is cleared to its background
|* colour
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[super drawInRect:dirtyRect withPainter:painter];

	[painter rectangleWithRect:NSInsetRect(dirtyRect, 10, 10)
						radius:20 filled:YES
						colour:[AZColour whiteColour]];

	[painter setUsingAntiAliasing:YES];
//	[painter lineAtX:20 y:20 toX:90 y:70 withR:100 g:200 b:50 a:200];
//	[painter ellipseWithRect:NSMakeRect(200, 200, 300, 100)
//			 filled:YES colour:[AZColour purpleColour]];
//
//	int vx[5] = {50, 100, 200, 100, 100};
//	int vy[5] = {350, 350, 500, 500, 450};
//	[painter polygonWith:5 x:vx y:vy filled:YES withR:240 g:20 b:100 a:255];

//	[painter pieAtX:300 y:300 radius:100 start:0 end:210
//			 filled:YES colour:[AZColour purpleColour]];
//
//	int vx[5] = {50, 100, 200, 100, 100};
//	int vy[5] = {350, 350, 500, 500, 450};
//	[painter texturedPolygonWith:5 x:vx y:vy texture:_surface textureDx:5 textureDy:5];
//
//	int bx[5] = {300, 350, 400, 450, 500};
//	int by[5] = {100, 150, 50, 150, 100};
//	[painter bezierWithPoints:5 x:bx y:by steps:10 colour:[AZColour blackColour]];
//
//	[painter setTextColour:[AZColour orangeColour]];
//
//	[painter setTextAlignment:AZFONT_HALIGN_CENTER];
//	[painter drawAtX:250 y:130
//			format:@"The quick brown fox\njumped over the\nlazy dog"];
//
//	[painter setTextAngle:180];
//	[painter setTextScale:(AZScale){2.f, 1.f}];
//	[painter setTextColour:[AZColour redColour]];
//	[painter drawAtX:450 y:300 format:@"Aiiiiiie! says %@", @"Simon"];

	[painter setTextAlignment:AZFONT_HALIGN_LEFT];
	NSString * text = @"Just a test of reformatting text to be in a column\n\n"
					   "The quick brown fox jumped over the lazy dog who "
					   "barely batted an eye let alone ran after the fox, "
					   "and who are we to say that this is not the correct "
					   "behaviour, I mean the dog still lives and the fox is "
					   "happy too so ... Maybe it's all for the best";

	NSRect r = NSMakeRect(35, 15, 250, 190);
	[painter rectangleWithRect:r colour:[AZColour redColour]];
	[painter drawInBox:r text:text];
	}


- (void) buttonPressed:(id)sender
	{
	[_text setStringValue: @"hi there"];
	NSLog(@"sender:%@", sender);
	if (_vslider.enabled)
		_vslider.enabled = NO;
	else
		_vslider.enabled = YES;

	AZMenuItem *item = [_menu itemAtIndex:0];
	[_menu popUpMenuPositioningItem:item
						 atLocation:NSMakePoint(30,220)
						     inView:self
						   thenCall:^(BOOL menuClicked)
		{
		if (menuClicked)
			{
			NSLog(@"selected '%@'", self.menu.selectedItem.title);
			}
		else
			NSLog(@"Done no-click");
		}];

	NSLog(@"subviews: %@", [[AZWindow contentViewForWindow:self.window] subviews]);
	}


- (void) textEntered:(id)sender
	{
	NSLog(@"sender:%@, text:'%@'", sender, ((AZTextField *)sender).stringValue);
	}

- (void) sliderValue:(id)sender
	{
	NSLog(@"slider:%@, value:%f", sender, ((AZSlider *)sender).doubleValue);
	}

@end
