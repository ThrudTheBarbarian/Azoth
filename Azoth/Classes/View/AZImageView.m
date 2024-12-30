//
//  AZImageView.m
//  Azoth
//
//  Created by Simon Gornall on 12/29/24.
//

#import "AZColour.h"
#import "AZImage.h"
#import "AZImageView.h"
#import "AZPainter.h"

@implementation AZImageView

/*****************************************************************************\
|* Initialisation: Create with a frame
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super initWithFrame:frame])
		{
		}
	return self;
	}

/*****************************************************************************\
|* Initialisation: Create with image
\*****************************************************************************/
+ (instancetype) imageViewWithImage:(AZImage *)image
	{
	NSRect frame 	  = NSMakeRect(0,0,image.width, image.height);
	AZImageView *view = [[AZImageView alloc] initWithFrame:frame];
	view.image 		  = image;
	return view;
	}

/*****************************************************************************\
|* Initialisation: Create with an image and frame. Image will be sized
|* according to the properties below
\*****************************************************************************/
+ (instancetype) imageViewWithImage:(AZImage *) image inFrame:(NSRect)frame
	{
	AZImageView *view = [[AZImageView alloc] initWithFrame:frame];
	view.image 		  = image;
	return view;
	}


/*****************************************************************************\
|* draw the image
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	NSRect imgRect = self.bounds;

	if (_frameStyle != AZImageFrameNone)
		imgRect = [self _calculateNewImageRectBasedOnFrame:painter];

	switch (_scaling)
		{
		case AZImageScaleNone:
			[self _drawUnscaledIn:imgRect withPainter:painter];
			break;
		case AZImageScaleAxesIndependently:
			[self _drawToFitIn:imgRect withPainter:painter];
			break;
		case AZImageScaleProportionallyUpOrDown:
			[self _drawScaledIn:imgRect withPainter:painter];
			break;
		case AZImageScaleProportionallyDown:
			[self _drawDownscaledIn:imgRect withPainter:painter];
			break;
		}
	}


/*****************************************************************************\
|* Draw the image, unscaled, using the correct alignment
\*****************************************************************************/
- (void) _drawUnscaledIn:(NSRect)rect withPainter:(AZPainter *)P
	{
	float rw 	= NSWidth(rect);
	float rh 	= NSHeight(rect);
	float w	 	= _image.width;
	float h 	= _image.height;

	/*************************************************************************\
	|* Simple case: the image is too big to fit, just draw all that will fit
	\*************************************************************************/
	if ((w >= rw) && (h >= rh))
		{
		NSRect src = rect;
		src.origin = NSMakePoint(0, 0);
		[P image:_image from:src at:rect.origin];
		}
	else
		{
		NSRect result 	= [self _align:rect forWidth:w height:h];
		NSRect src 		= result;
		src.origin 		= NSMakePoint(0, 0);
		[P image:_image from:src at:rect.origin];
		}
	}

/*****************************************************************************\
|* Draw the image, proportionately scaled to fit, using the correct alignment
\*****************************************************************************/
- (void) _drawScaledIn:(NSRect)rect withPainter:(AZPainter *)P
	{
	float W,H;
	float aspect = ((float)_image.width)/_image.height;
	if (aspect > 1.f)
		{
		W = rect.size.width;
		H = rect.size.width * W / aspect;
		}
	else
		{
		H = rect.size.height;
		W = rect.size.width * H / aspect;
		}

	NSRect result 	= [self _align:rect forWidth:W height:H];
	NSRect src 		= result;
	src.origin 		= NSMakePoint(0, 0);
	[P image:_image from:src at:rect.origin];
	}

/*****************************************************************************\
|* Draw the image, stretched to fit, ignoring alignment
\*****************************************************************************/
- (void) _drawToFitIn:(NSRect)rect withPainter:(AZPainter *)P
	{
	NSRect src = NSMakeRect(0,0,_image.width, _image.height);
	[P image:_image from:src to:rect];
	}

/*****************************************************************************\
|* Draw the image, downscaled to fit, using the correct alignment
\*****************************************************************************/
- (void) _drawDownscaledIn:(NSRect)rect withPainter:(AZPainter *)P
	{
	float xs = rect.size.width  / _image.width;
	float ys = rect.size.height / _image.height;
	float W, H;

	if ((xs >= 1.f) && (ys >= 1.f))
		{
		// both smaller than the available space, scale up by smallest
		float scale = MIN(xs, ys);
		W = _image.width * scale;
		H = _image.height * scale;
		}
	else if ((xs < 1.f) && (ys < 1.f))
		{
		// both larger than available space, scale down by largest
		float scale = MAX(xs, ys);
		W = _image.width / scale;
		H = _image.width / scale;
		}
	else if (ys < 1.f)
		{
		// Y is larger, scale down both by ys
		W = _image.width / ys;
		H = _image.width / ys;
		}
	else
		{
		// X is larger, scale down both by xs
		W = _image.width / xs;
		H = _image.width / xs;
		}

	NSRect result 	= [self _align:rect forWidth:W height:H];
	NSRect src 		= result;
	src.origin 		= NSMakePoint(0, 0);
	[P image:_image from:src at:rect.origin];
	}

/*****************************************************************************\
|* Position rect within another, based on image width, height and original rect
\*****************************************************************************/
- (NSRect) _align:(NSRect)rect forWidth:(float)w height:(float)h
	{
	float rw 	= NSWidth(rect);
	float rh 	= NSHeight(rect);

	float dx = rw - w;
	float dy = rh - h;

	/*************************************************************************\
	|* Are we too wide (in which case we're not tall enough
	\*************************************************************************/
	if (dx < 0)
		{
		switch (_alignment)
			{
			case AZImageAlignCenter:
				rect.origin.y += dy / 2;
				break;
			case AZImageAlignBottom:
			case AZImageAlignBottomLeft:
			case AZImageAlignBottomRight:
				rect.origin.y += dy;
				break;
			default:
				break;
			}
		}

	/*************************************************************************\
	|* Or are we too tall (in which case we're not wide enough
	\*************************************************************************/
	if (dy < 0)
		{
		switch (_alignment)
			{
			case AZImageAlignCenter:
				rect.origin.x += dx / 2;
				break;
			case AZImageAlignTopRight:
			case AZImageAlignBottomRight:
			case AZImageAlignRight:
				rect.origin.x += dx;
				break;
			default:
				break;
			}
		}
	return rect;
	}

/*****************************************************************************\
|* Calculate the new image rect
\*****************************************************************************/
- (NSRect) _calculateNewImageRectBasedOnFrame:(AZPainter *)painter
	{
	NSRect orig = self.bounds;

	switch (_frameStyle)
		{
		case AZImageFrameNone:
			return orig;
		case AZImageFramePhoto:
			[painter rectangleWithRect:self.bounds colour:AZColour.blackColour];
			return NSInsetRect(orig, 1,1);
		case AZImageFrameButton:
			[painter rectangleWithButton:self.bounds withClip:self.bounds];
			return NSInsetRect(orig, 3,3);
		case AZImageFrameGroove:
			[painter rectangleWithGroove:self.bounds withClip:self.bounds];
			return NSInsetRect(orig, 4,4);
		case AZImageFrameGrayBezel:
			[painter rectangleWithBezel:self.bounds withClip:self.bounds];
			return NSInsetRect(orig, 4,4);
		}
	}

@end
