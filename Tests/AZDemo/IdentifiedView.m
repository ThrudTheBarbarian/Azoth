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
@property (strong, nonatomic) AZSegmentedControl *ctrl;
@property (strong, nonatomic) AZButton *cb;
@property (strong, nonatomic) AZButton *rb1;
@property (strong, nonatomic) AZButton *rb2;
//@property (strong, nonatomic) AZScroller *hs;
//@property (strong, nonatomic) AZScroller *vs;
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

	NSRect r;

	AZButton *btn = [AZButton buttonWithText:@"Button test" at:NSMakePoint(30,220)];
	[btn setTarget:self];
	[btn setAction:@selector(buttonPressed:)];
	[self addSubview:btn];

	int w = btn.frame.size.width;

	r = NSMakeRect(30, 250, w, 34);
	_text = [AZTextField textfieldWithFrame:r];
	[_text setTarget:self];
	[_text setAction:@selector(textEntered:)];
	[self addSubview:_text];

	r = NSMakeRect(30, 280, w, 29);
	_slider = [AZSlider sliderWithFrame:r];
	[_slider setTarget:self];
	[_slider setAction:@selector(sliderValue:)];
	[_slider setContinuous:YES];
	[self addSubview:_slider];

	AZMenu *menu = [AZMenu new];
	[menu addItemWithTitle:@"item 1" action:nil keyEquivalent:@""];
	[menu addItemWithTitle:@"item 2" action:nil keyEquivalent:@""];
	AZPopupButton *pbtn = [AZPopupButton pullDownButtonWithTitle:@"Test pulldown"
															menu:menu];
	[pbtn setFrameOrigin:NSMakePoint(30,320)];
	[pbtn setTarget:self];
	[pbtn setAction:@selector(pbuttonPressed:)];
	[self addSubview:pbtn];
	int pbw = pbtn.frame.size.width;

	menu = [AZMenu new];
	[menu addItemWithTitle:@"item 1" action:nil keyEquivalent:@""];
	[menu addItemWithTitle:@"item 2" action:nil keyEquivalent:@""];
	pbtn = [AZPopupButton popupButtonWithTitle:@"Test popup"
										  menu:menu];
	[pbtn setFrameOrigin:NSMakePoint(50+pbw,320)];
	[pbtn setTarget:self];
	[pbtn setAction:@selector(pbuttonPressed:)];
	[self addSubview:pbtn];

	_cb = [AZButton buttonWithText:@"Checkbox test" at:NSMakePoint(220,220)];
	_cb.type = ButtonTypeCheckbox;
	_cb.enabled = NO;

	[_cb setTarget:self];
	[_cb setAction:@selector(cbPressed:)];
	[self addSubview:_cb];

	_rb1 = [AZButton buttonWithText:@"Radio test #1" at:NSMakePoint(180,260)];
	_rb1.type = ButtonTypeRadio;
	_rb1.radioGroup = @"test";

	[_rb1 setTarget:self];
	[_rb1 setAction:@selector(rbPressed:)];
	[self addSubview:_rb1];

	_rb2 = [AZButton buttonWithText:@"Radio test #2" at:NSMakePoint(180,285)];
	_rb2.type = ButtonTypeRadio;
	_rb2.radioGroup = @"test";

	[_rb2 setTarget:self];
	[_rb2 setAction:@selector(rbPressed:)];
	[self addSubview:_rb2];

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
	[_menu addItemWithTitle:@"The Angry Man" action:nil keyEquivalent:@""];
	[[_menu lastItem] setState:AZControlStateValueOn];
	[_menu addItemWithTitle:@"The quiet thinker" action:nil keyEquivalent:@""];
	[_menu addItemWithTitle:@"The xylophone" action:nil keyEquivalent:@""];
	[_menu addItemWithTitle:@"The card-carrying gunslinger" action:nil keyEquivalent:@""];

	int segx = NSMaxX(pbtn.frame) + 20;

	NSArray<NSString *> *labels = @[@"Car", @"Bus", @"Bike"];
	_ctrl = [AZSegmentedControl withLabels:labels
								trackingMode:AZSegmentSwitchTrackingSelectOne
								target:self
								action:@selector(segmentClicked:)];
	[_ctrl setFrameOrigin:NSMakePoint(segx,320)];
		[_ctrl setEnabled:YES];
	[self addSubview:_ctrl];

//	NSRect b = self.bounds;
//	b.origin.y = b.size.height - 10;
//	b.size.height = 10;
//	_hs = [[AZScroller alloc] initWithFrame:b];
//	[_hs setAction:@selector(scrollerMoved:)];
//	[_hs setTarget:self];
//	[self addSubview:_hs];
//
//	b = self.bounds;
//	b.origin.x = b.size.width - 10;
//	b.size.width = 10;
//	_vs = [[AZScroller alloc] initWithFrame:b];
//	[_vs setAction:@selector(scrollerMoved:)];
//	[_vs setTarget:self];
//		_vs.knobProportion = 0.2;
//	[self addSubview:_vs];
	return self;
	}

/*****************************************************************************\
|* Mouse-button-down event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseDown:(AZEvent *)e
	{
	NSPoint p = [self convertPoint:e.locationInWindow fromView:nil];

	NSLog(@"Down in %@ at (%d,%d) (from %d,%d)",
		self.identifier, (int)p.x, (int)p.y,
		(int)e.locationInWindow.x,
		(int)e.locationInWindow.y);
	return YES;
	}


/*****************************************************************************\
|* Mouse-button-up event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseUp:(AZEvent *)e
	{
	NSPoint p = [self convertPoint:e.locationInWindow fromView:nil];

	NSLog(@"Up in %@ at (%d,%d) (from %d,%d)",
		self.identifier, (int)p.x, (int)p.y,
		(int)e.locationInWindow.x,
		(int)e.locationInWindow.y);
	[[AZWindow contentViewForWindow:self.window] setNeedsDisplay:YES];
	return YES;
	}


/*****************************************************************************\
|* Mouse-dragged event, return YES if we consume the event
\*****************************************************************************/
- (BOOL) mouseDragged:(AZEvent *)e
	{
	NSPoint p = [self convertPoint:e.locationInWindow fromView:nil];

	NSLog(@"Dragged in %@ at (%d,%d) (from %d,%d)",
		self.identifier, (int)p.x, (int)p.y,
		(int)e.locationInWindow.x,
		(int)e.locationInWindow.y);
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
						colour:[AZColour white]];

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

	[painter setTextAlignment:AZTextAlignmentLeft];
	NSString * text = @"Just a test of reformatting text to be in a column\n\n"
					   "The quick brown fox jumped over the lazy dog who "
					   "barely batted an eye let alone ran after the fox, "
					   "and who are we to say that this is not the correct "
					   "behaviour, I mean the dog still lives and the fox is "
					   "happy too so ... Maybe it's all for the best";

	NSRect r = NSMakeRect(35, 15, 250, 190);
	[painter rectangleWithRect:r colour:[AZColour red]];
	[painter textInBox:r text:text];
	}


- (void) buttonPressed:(id)sender
	{
	[_text setStringValue: @"hi there"];
	NSLog(@"btn: sender:%@", sender);
	if (_vslider.enabled)
		_vslider.enabled = NO;
	else
		_vslider.enabled = YES;

	AZMenuItem *item = [_menu itemAtIndex:2];
	[_menu popUpMenuPositioningItem:item
						 atLocation:NSMakePoint(59,244)
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
	}



- (void) pbuttonPressed:(id)sender
	{
	NSLog(@"popup: sender:%@", sender);
	}

- (void) cbPressed:(id)sender
	{
	NSLog(@"Checkbox: sender:%@", sender);
		_text.enabled = !_text.enabled;
	}


- (void) textEntered:(id)sender
	{
	NSLog(@"sender:%@, text:'%@'", sender, ((AZTextField *)sender).stringValue);
	}

- (void) sliderValue:(id)sender
	{
	//NSLog(@"slider:%@, value:%f", sender, ((AZSlider *)sender).doubleValue);
	_cb.enabled = (((AZSlider *)sender).doubleValue == 0);
	}


- (void) segmentClicked:(id)sender
	{
	NSLog(@"segmented control:%@", sender);

	}

- (void) rbPressed:(id)sender
	{
	NSLog(@"radio button pressed:%@", sender);

//	id<AZRenderer> azr	= AZRenderer.renderer;
//	SDL_Log("renderer:%s", azr.rendererName.UTF8String);
//
//	AZImage *img = [AZImage imageWithContentsOfFile:@"/Volumes/raid/Freya/Mapper/Resources/Backgrounds/Background_10.png"];
//	SDL_Log("Loaded image, texture is %d", (int)img.texture);
//
//	[img saveAs:@"/tmp/test.png" inFormat:AZImageFormatPNG withQuality:10];
	}

//- (void) scrollerMoved:(id)sender
//	{
//	NSLog(@"scroller moved:%@ [%f]", sender, ((AZScroller*)sender).doubleValue);
//	}

@end
