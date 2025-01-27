//
//  AZSlider.m
//  Azoth
//
//  Created by Simon Gornall on 12/18/24.
//
#import <SDL3/SDL.h>

#import "AZApplication.h"
#import "AZColour.h"
#import "AZEvent.h"
#import "AZPainter.h"
#import "AZRenderer.h"
#import "AZSlider.h"
#import "AZWindow.h"
#import "AZZib.h"
#import "NSDictionary+ZIB.h"

enum
	{
	STATE_N	= 0,					// Normal
	STATE_H,						// Highlighted
	STATE_D,						// Disabled

	STATE_NUM
	};

static NSRect	_trackL[STATE_NUM];	// Horizontal, Left
static NSRect	_trackM[STATE_NUM];	// Horizontal, Middle
static NSRect	_trackR[STATE_NUM];	// Horizontal, Right

static NSRect	_trackB[STATE_NUM];	// Vertical, Bottom
static NSRect	_trackC[STATE_NUM];	// Vertical, Center
static NSRect	_trackT[STATE_NUM];	// Vertical, Top

static NSRect	_circ[STATE_NUM];	// Circular, bezel
static NSRect	_cKnob[STATE_NUM];	// Circular, knob

static NSRect	_knob[STATE_NUM];	// knobs

@interface AZSlider()
@property(assign, nonatomic) NSRect							active;
@property(assign, nonatomic) NSRect							track;
@end

@implementation AZSlider

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super initWithFrame:frame])
		{
		[self _commonSliderInit];
		}
	return self;
	}

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithDictionary:(NSDictionary *)info;
	{
	if (self = [super initWithDictionary:info])
		{
		[self _commonSliderInit];

		self.doubleValue 	= [info AZStringWithKey:kZibValue
										  orDefault:@"0.5"].doubleValue;
		self.minValue 		= [info AZStringWithKey:kZibMinValue
									     orDefault:@"0.0"].doubleValue;
		self.maxValue 		= [info AZStringWithKey:kZibMaxValue
									     orDefault:@"1.0"].doubleValue;

		if ([info[kZibEnabled] isEqualToString:@"NO"])
			self.state = AZControlStateDisabled;
		else
			self.state = AZControlStateNormal;
			
		if (self.doubleValue < self.minValue)
			self.doubleValue = self.minValue;
		if (self.doubleValue > self.maxValue)
			self.doubleValue = self.maxValue;

		if ([info[kZibType] isEqualToString:kZibCircular])
			self.type = SliderTypeCircular;

		_tickCount = ((NSString *)(info[kZibTicks])).intValue;
		}
	return self;
	}

/*****************************************************************************\
|* Common initialisation
\*****************************************************************************/
- (void) _commonSliderInit
	{
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken,
			^{
			[self _fetchRects];
			});

		self.backgroundColour	= AZColour.clear;
		self.doubleValue 		= 0.5;
		self.minValue			= 0.0;
		self.maxValue			= 1.0;
		self.tickCount			= 0;
		
		NSRect frame			= self.frame;
		_type		 			= frame.size.width > frame.size.height
								? SliderTypeHorizontal
								: frame.size.width == frame.size.height
								? SliderTypeCircular
								: SliderTypeVertical;
	}


+ (AZSlider *) sliderWithFrame:(NSRect)frame
	{
	return [[AZSlider alloc] initWithFrame:frame];
	}

// MARK: Drawing

/*****************************************************************************\
|* Draw the slider
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[super drawInRect:dirtyRect withPainter:painter];
	switch (_type)
		{
		case SliderTypeHorizontal:
			[self _drawHorizontalInRect:dirtyRect with:painter];
			break;
		case SliderTypeVertical:
			[self _drawVerticalInRect:dirtyRect with:painter];
			break;
		case SliderTypeCircular:
			[self _drawCircularInRect:dirtyRect with:painter];
			break;
		default:
			SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
				"Asked to draw nonexistent slider type %d!", _type);
			break;
		}
	}

// MARK: Events


/*****************************************************************************\
|* Handle a mouse down
\*****************************************************************************/
- (BOOL) mouseDown:(AZEvent *)e
	{
	if (self.state == AZControlStateDisabled)
		return NO;
	return YES;
	}

/*****************************************************************************\
|* Handle a mouse drag
\*****************************************************************************/
- (BOOL) mouseDragged:(AZEvent *)e
	{
	switch (_type)
		{
		case SliderTypeHorizontal:
			return [self _horizontalDrag:e];
			break;
		case SliderTypeVertical:
			return [self _verticalDrag:e];
			break;
		case SliderTypeCircular:
			return [self _circleDrag:e];
			break;
		default:
			SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
				"Asked to drag mouse in nonexistent slider type %d!", _type);
			break;
		}
	return NO;
	}

/*****************************************************************************\
|* Handle a mouse up
\*****************************************************************************/
- (BOOL) mouseUp:(AZEvent *)e
	{
	[self sendAction:self.action to:self.target];
	return YES;
	}

/*****************************************************************************\
|* Handle a drag on the horizontal track
\*****************************************************************************/
- (BOOL) _horizontalDrag:(AZEvent *)e
	{
	NSPoint p = [self convertPoint:e.locationInWindow fromView:nil];

	double X = _track.origin.x;
	double W = _track.size.width;

	if (p.x < X)
		p.x = X;

	if (p.x >= X + W)
		p.x = X + W;

	if (_tickCount > 0)
		p.x =  [self _tickPositionForMousePosition:p.x
											 start:_track.origin.x
											length:_track.size.width];

	self.doubleValue = ((p.x - X) / W)
					 * (self.maxValue - self.minValue)
					 + self.minValue;

	[self setNeedsDisplay:YES];

	if (self.continuous)
		[self sendAction:self.action to:self.target];
	return YES;
	}

/*****************************************************************************\
|* Handle a drag on the vertical track
\*****************************************************************************/
- (BOOL) _verticalDrag:(AZEvent *)e
	{
	NSPoint p = [self convertPoint:e.locationInWindow fromView:nil];

	double Y = _track.origin.y;
	double H = _track.size.height;

	if (p.y < Y)
		p.y = Y;

	if (p.y >= Y + H)
		p.y = Y + H;

	self.doubleValue = (1.0 - (p.y - Y) / H)
					 * (self.maxValue - self.minValue)
					 + self.minValue;
	[self setNeedsDisplay:YES];

	if (self.continuous)
		[self sendAction:self.action to:self.target];
	return YES;
	}

/*****************************************************************************\
|* Handle a drag on the circular slider
\*****************************************************************************/
- (BOOL) _circleDrag:(AZEvent *)e
	{
	NSPoint p = [self convertPoint:e.locationInWindow fromView:nil];

	float X = _track.origin.x;
	float W = _track.size.width;
	float C = X + W/2;

	if (p.x < C - 5.f*W)
		p.x = C - 5.f*W;

	if (p.x >= C + 5.f*W)
		p.x =  C + 5.f*W;

	self.doubleValue  	= (((p.x - C) / (W * 10.f) + 0.5f))
						* (self.maxValue - self.minValue)
						+ self.minValue;

	[self setNeedsDisplay:YES];

	if (self.continuous)
		[self sendAction:self.action to:self.target];
	return YES;
	}

// MARK: Private methods


/*****************************************************************************\
|* Figure out which tick we are going to land on
\*****************************************************************************/
- (float) _tickPositionForMousePosition:(float)mx
								  start:(float)X
								 length:(float)W
	{
	float dT = W / (self.tickCount-1);

	if (mx < X + dT/2)
		return X;

	if (mx > X + W - dT/2)
		return X+W;

	int ticks = (mx - X) / dT;
	return X + dT * ticks;
	}


/*****************************************************************************\
|* Draw the horizontal slider
\*****************************************************************************/
- (void) _drawHorizontalInRect:(NSRect)dirtyRect with:(AZPainter *)painter
	{
	NSRect sK	= _knob[self.state];

	int which	= self.state == AZControlStateHighlighted
				? AZControlStateNormal
				: self.state;
	NSRect sL	= _trackL[which];
	NSRect sM	= _trackM[which];
	NSRect sR	= _trackR[which];

	float K2	= sK.size.width/3.f;
	float W		= self.bounds.size.width;
	float H		= self.bounds.size.height;

	// Draw the track
	NSRect dL	= {K2,
				  (H-sL.size.height)/2,
				  sL.size.width,
				  sL.size.height};

	_track		= (NSRect) {sL.size.width + K2,
				  (H-sM.size.height)/2,
				  W-sL.size.width-sR.size.width - K2 - K2,
				  sM.size.height};

	NSRect dR	= {W-sR.size.width - K2,
				  (H-sR.size.height)/2,
				  sR.size.width,
				  sR.size.height};

	id<AZRenderer> azr	= AZRenderer.renderer;
	NSInteger ui	= [AZApp textureFor:kUiMap];

	[azr setBlendMode:SDL_BLENDMODE_ADD];

	[azr blitFrom:ui src:sL dst:dL];
	[azr tileFrom:ui src:sM dst:_track];
	[azr blitFrom:ui src:sR dst:dR];

	[azr setBlendMode:SDL_BLENDMODE_NONE];
	// Draw any ticks
	if (_tickCount > 0)
		{
		float x 	= _track.origin.x-1;
		float y 	= _track.origin.y;
		float w		= _track.size.width;
		float dT	= w / (_tickCount-1);

		for (int i=0; i<_tickCount; i++)
			{
			[painter lineAtX:x y:y-6 toX:x y:y-2 colour:AZColour.grey37];
			x += dT;
			}
		}

	// Draw the knob
	float range		= self.maxValue - self.minValue;
	float value		= (self.doubleValue - self.minValue) / range;

	double where	= _track.origin.x + value * _track.size.width;
	_active			= (NSRect){where - sK.size.width/2,
					  (H - sK.size.height)/2,
					  sK.size.width,
					  sK.size.height};
	[azr blitFrom:ui src:sK dst:_active];
	}

/*****************************************************************************\
|* Draw the vertical slider
\*****************************************************************************/
- (void) _drawVerticalInRect:(NSRect)dirtyRect with:(AZPainter *)painter
	{
	NSRect sK	= _knob[self.state];

	int which	= self.state == AZControlStateHighlighted
				? AZControlStateNormal
				: self.state;
	NSRect sB	= _trackB[which];
	NSRect sC	= _trackC[which];
	NSRect sT	= _trackT[which];

	float K2	= sK.size.width/3.f;
	float W		= self.bounds.size.width;
	float H		= self.bounds.size.height;
	float W2	= W/2;

	// Draw the track
	NSRect dT	= {W2-sT.size.width/2,
				  K2,
				  sT.size.width,
				  sT.size.height};

	_track		= (NSRect) {W2 - sC.size.width/2,
				  sT.size.height + K2,
				  sC.size.width,
				  H-sB.size.height-sT.size.height - K2 - K2};

	NSRect dB	= {W2-sB.size.width/2,
				  H-sB.size.height -K2,
				  sB.size.width,
				  sB.size.height};

	id<AZRenderer> azr	= AZRenderer.renderer;
	NSInteger ui	= [AZApp textureFor:kUiMap];

	[azr setBlendMode:SDL_BLENDMODE_ADD];

	[azr blitFrom:ui src:sB dst:dB];
	[azr tileFrom:ui src:sC dst:_track];
	[azr blitFrom:ui src:sT dst:dT];

	// Draw the knob
	float range		= self.maxValue - self.minValue;
	float value		= (self.doubleValue - self.minValue) / range;
	double where	= _track.origin.y + value * _track.size.height;
	_active			= (NSRect){W2 - sK.size.width/2,
					  H - where - sK.size.width/2,
					  sK.size.width,
					  sK.size.height};
	[azr blitFrom:ui src:sK dst:_active];
	}

/*****************************************************************************\
|* Draw the circular slider
\*****************************************************************************/
- (void) _drawCircularInRect:(NSRect)dirtyRect with:(AZPainter *)painter
	{
	NSRect sK	= _cKnob[self.state];

	int which	= self.state == AZControlStateHighlighted
				? AZControlStateNormal
				: self.state;
	NSRect sC	= _circ[which];

	float W		= self.bounds.size.width;
	float H		= self.bounds.size.height;
	float W2	= W/2;
	float H2	= H/2;

	// Draw the bezel
	_track		= (NSRect) {W2 - sC.size.width/2,
							H2 - sC.size.height/2,
							sC.size.width,
							sC.size.height};

	id<AZRenderer> azr	= AZRenderer.renderer;
	NSInteger ui	= [AZApp textureFor:kUiMap];

	[azr setBlendMode:SDL_BLENDMODE_ADD];

	[azr blitFrom:ui src:sC dst:_track];

	// Draw the knob
	float r		= W2 * 0.5;
	float range	= self.maxValue - self.minValue;
	if (range == 0.0)
		{
		SDL_Log("Range of 0 on circular slider. Aborting");
		return;
		}

	float scale	= (self.doubleValue - self.minValue)/range;
	float angle	= -scale * M_PI * 1.5 -2.25*  M_PI;
	float x		= r * SDL_sin(angle) + NSMidX(_track);
	float y 	= r * SDL_cos(angle)  + NSMidY(_track);

	NSRect knob	= (NSRect){x - sK.size.width/2,
						   y - sK.size.width/2,
						   sK.size.width,
						   sK.size.height};
	[azr blitFrom:ui src:sK dst:knob];
	}

/*****************************************************************************\
|* Populate the rectangles from the UI texture atlas
\*****************************************************************************/
- (void) _fetchRects
	{
	_trackL[STATE_N]	= [AZApp srcRectFor:@"horizontal-track-left" in:kUiMap];
	_trackM[STATE_N]	= [AZApp srcRectFor:@"horizontal-track-center" in:kUiMap];
	_trackR[STATE_N]	= [AZApp srcRectFor:@"horizontal-track-right" in:kUiMap];

	_trackL[STATE_D]	= [AZApp srcRectFor:@"horizontal-track-disabled-left" in:kUiMap];
	_trackM[STATE_D]	= [AZApp srcRectFor:@"horizontal-track-disabled-center" in:kUiMap];
	_trackR[STATE_D]	= [AZApp srcRectFor:@"horizontal-track-disabled-right" in:kUiMap];

	_trackB[STATE_N]	= [AZApp srcRectFor:@"vertical-track-bottom" in:kUiMap];
	_trackC[STATE_N]	= [AZApp srcRectFor:@"vertical-track-center" in:kUiMap];
	_trackT[STATE_N]	= [AZApp srcRectFor:@"vertical-track-top" in:kUiMap];

	_trackB[STATE_D]	= [AZApp srcRectFor:@"vertical-track-disabled-bottom" in:kUiMap];
	_trackC[STATE_D]	= [AZApp srcRectFor:@"vertical-track-disabled-center" in:kUiMap];
	_trackT[STATE_D]	= [AZApp srcRectFor:@"vertical-track-disabled-top" in:kUiMap];

	_knob[STATE_N]		= [AZApp srcRectFor:@"knob" in:kUiMap];
	_knob[STATE_H]		= [AZApp srcRectFor:@"knob-highlighted" in:kUiMap];
	_knob[STATE_D]		= [AZApp srcRectFor:@"knob-disabled" in:kUiMap];

	_circ[STATE_N]		= [AZApp srcRectFor:@"slider-circular-bezel" in:kUiMap];
	_cKnob[STATE_N]		= [AZApp srcRectFor:@"slider-circular-knob" in:kUiMap];
	_circ[STATE_D]		= [AZApp srcRectFor:@"slider-circular-disabled-bezel" in:kUiMap];
	_cKnob[STATE_D]		= [AZApp srcRectFor:@"slider-circular-disabled-knob" in:kUiMap];
	}

@end
