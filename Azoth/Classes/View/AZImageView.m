//
//  AZImageView.m
//  Azoth
//
//  Created by ThrudTheBarbarian on 12/29/24.
//

#import "AZColour.h"
#import "AZImage.h"
#import "AZImageView.h"
#import "AZNotifications.h"
#import "AZPainter.h"
#import "AZRenderer.h"
#import "AZZib.h"


/*****************************************************************************\
|* "Private" properties
\*****************************************************************************/
@interface AZImageView()

// Whether the mouse is over us
@property(assign, nonatomic) BOOL						mouseIsOver;

@end

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
|* Configuration via dictionary. This is called by the NIB loader, but is a
|* valid way to create the view
\*****************************************************************************/
- (instancetype) initWithDictionary:(NSDictionary *)info;
	{
	if (self = [super initWithDictionary:info])
		{
		NSString *scaling = info[kZibImageScaling];
		if ([scaling isEqualToString:@"proportionallyDown"])
			_scaling = AZImageScaleProportionallyDown;
		else if ([scaling isEqualToString:@"proportionallyUpOrDown"])
			_scaling = AZImageScaleProportionallyUpOrDown;
		else if ([scaling isEqualToString:@"axesIndependently"])
			_scaling = AZImageScaleAxesIndependently;
		else
			_scaling = AZImageScaleNone;

		NSString *frame = info[kZibFrameStyle];
		if ([frame isEqualToString:@"grayBezel"])
			_frameStyle = AZImageFrameGrayBezel;
		else if ([frame isEqualToString:@"button"])
			_frameStyle = AZImageFrameButton;
		else if ([frame isEqualToString:@"groove"])
			_frameStyle = AZImageFrameGroove;
		else if ([frame isEqualToString:@"photo"])
			_frameStyle = AZImageFramePhoto;
		else
			_frameStyle = AZImageFrameNone;

		NSString *align = info[kZibAlignment];
		if ([align isEqualToString:@"topLeft"])
			_alignment = AZImageAlignTopLeft;
		else if ([align isEqualToString:@"top"])
			_alignment = AZImageAlignTop;
		else if ([align isEqualToString:@"topRight"])
			_alignment = AZImageAlignTopRight;
		else if ([align isEqualToString:@"left"])
			_alignment = AZImageAlignLeft;
		else if ([align isEqualToString:@"right"])
			_alignment = AZImageAlignRight;
		else if ([align isEqualToString:@"bottomLeft"])
			_alignment = AZImageAlignBottomLeft;
		else if ([align isEqualToString:@"bottom"])
			_alignment = AZImageAlignBottom;
		else if ([align isEqualToString:@"bottomRight"])
			_alignment = AZImageAlignBottomRight;
		else
			_alignment = AZImageAlignCenter;
		}

	return self;
	}

/*****************************************************************************\
|* draw the image
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[super drawInRect:dirtyRect withPainter:painter];

	NSRect imgRect = self.bounds;

	if (_frameStyle != AZImageFrameNone)
		imgRect = [self _calculateNewImageRectBasedOnFrame:painter];

	if (_image)
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
	else if (_noImageText)
		{
		[painter setTextAlignment:AZTextAlignmentCenter];
		[painter textInBox:self.bounds text:_noImageText];
		}

	if (_mouseIsOver)
		{
		[painter rectangleWithRect:NSInsetRect(imgRect,2,2)
							radius:2
							filled:NO
						    colour:AZColour.orange];
		}
	}

// MARK: Drop target

/*****************************************************************************\
|* Set this to be a drop-target
\*****************************************************************************/
- (void) setDropTarget:(BOOL)dropTarget
	{
	_dropTarget = dropTarget;
	if (_dropTarget)
		[self registerForDraggedTypes:@[AZPasteboardTypeImage]];
	}


/*****************************************************************************\
|* Dragging has exited this view
\*****************************************************************************/
- (void)draggingExited:(nonnull id<AZDraggingInfo>)sender
	{
	_mouseIsOver = NO;
	[self setNeedsDisplay:YES];
	}


/*****************************************************************************\
|* Dragging has lingered in this view, return what drop is now acceptable
\*****************************************************************************/
- (AZDragOperation)draggingUpdated:(nonnull id<AZDraggingInfo>)sender
	{
	_mouseIsOver = YES;
	[self setNeedsDisplay:YES];
	return [self isAcceptedDrop];
	}


/*****************************************************************************\
|* Inform the sender if we want to be updated (other than exit/enter)
\*****************************************************************************/
- (BOOL)wantsPeriodicDraggingUpdates
	{
	return YES;
	}

/*****************************************************************************\
|* Decide whethere we accept this drop or not
\*****************************************************************************/
- (AZDragOperation) isAcceptedDrop
	{
	return _mouseIsOver ? AZDragOperationCopy : AZDragOperationNone;
	}

/*****************************************************************************\
|* We got a mouse-release in an acceptable drop-target, prepare for the actual
|* drop
\*****************************************************************************/
- (BOOL) prepareForDragOperation:(id<AZDraggingInfo>) sender
	{
	return YES;
	}

/*****************************************************************************\
|* We got a mouse-release in an acceptable drop-target, prepare for the actual
|* drop
\*****************************************************************************/
- (BOOL) performDragOperation:(id<AZDraggingInfo>) sender
	{
	AZPasteboard *pb = [AZPasteboard draggingPasteboard];
	id plist		 = [pb propertyListForType:AZPasteboardTypeImage];

	NSDictionary *info	= ([plist isKindOfClass:NSArray.class])
						? ((NSArray *)plist).firstObject
						: (NSDictionary *)plist;


	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
	[nc postNotificationName:AZImageViewDidReceiveDropNotification
					  object:self
					userInfo:info];
	return YES;
	}

/*****************************************************************************\
|* Clean up after the drop
\*****************************************************************************/
- (void) concludeDragOperation:(id<AZDraggingInfo>)sender
	{
	_mouseIsOver = NO;
	[self setNeedsDisplay:YES];
	}


// MARK: Properties

/*****************************************************************************\
|* Make sure we refresh the view if we change the scaling
\*****************************************************************************/
- (void) setScaling:(AZImageScaling)scaling
	{
	_scaling = scaling;
	[self setNeedsDisplay:YES];
	}

/*****************************************************************************\
|* Make sure we refresh the view if we change the alignment
\*****************************************************************************/
- (void) setAlignment:(AZImageAlignment)alignment
	{
	_alignment = alignment;
	[self setNeedsDisplay:YES];
	}

/*****************************************************************************\
|* Make sure we refresh the view if we change the frame style
\*****************************************************************************/
- (void) setFrameStyle:(AZImageFrameStyle)frameStyle
	{
	_frameStyle = frameStyle;
	[self setNeedsDisplay:YES];
	}

/*****************************************************************************\
|* Make sure we refresh the view if we change the image
\*****************************************************************************/
- (void) setImage:(AZImage *)image
	{
	_image = image;
	[self setNeedsDisplay:YES];
	}



// MARK: Private Methods

/*****************************************************************************\
|* Draw the image, unscaled, using the correct alignment
\*****************************************************************************/
- (void) _drawUnscaledIn:(NSRect)rect withPainter:(AZPainter *)P
	{
	rect = self.bounds;
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
		[P image:_image to:result];
		}
	}

/*****************************************************************************\
|* Draw the image, proportionately scaled to fit, using the correct alignment
\*****************************************************************************/
- (void) _drawScaledIn:(NSRect)rect withPainter:(AZPainter *)P
	{
	rect = self.bounds;
	float W,H;
	float aspect = ((float)_image.width)/_image.height;
	if (aspect > 1.f)
		{
		W = rect.size.width;
		H = W / aspect;
		}
	else
		{
		H = rect.size.height;
		W = H * aspect;
		}

	NSRect result 	= [self _align:rect forWidth:W height:H];
	[P image:_image to:result];
	}

/*****************************************************************************\
|* Draw the image, stretched to fit, ignoring alignment
\*****************************************************************************/
- (void) _drawToFitIn:(NSRect)rect withPainter:(AZPainter *)P
	{
	rect = self.bounds;
	NSRect src = NSMakeRect(0,0,_image.width, _image.height);
	[P image:_image from:src to:rect];
	}

/*****************************************************************************\
|* Draw the image, downscaled to fit, using the correct alignment
\*****************************************************************************/
- (void) _drawDownscaledIn:(NSRect)rect withPainter:(AZPainter *)P
	{
	rect = self.bounds;
	float xs = rect.size.width  / _image.width;
	float ys = rect.size.height / _image.height;
	float W, H;

	if ((xs >= 1.f) && (ys >= 1.f))
		{
		// both smaller than the available space, but no scaling up
		W = _image.width;
		H = _image.height;
		}
	else if ((xs < 1.f) && (ys < 1.f))
		{
		// both larger than available space, scale down by largest
		float scale = MIN(xs, ys);
		W = _image.width * scale;
		H = _image.height * scale;
		}
	else if (ys < 1.f)
		{
		// Y is larger, scale down both by ys
		W = _image.width / ys;
		H = _image.height / ys;
		}
	else
		{
		// X is larger, scale down both by xs
		W = _image.width / xs;
		H = _image.height / xs;
		}

	NSRect result 	= [self _align:rect forWidth:W height:H];
	[P image:_image to:result];
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
	|* Are we smaller in both dimensions ?
	\*************************************************************************/
	if ((dx >= 0) && (dy >= 0))
		{
		rect.size.width 	= w;
		rect.size.height 	= h;
		switch (_alignment)
			{
			case AZImageAlignTop:
				rect.origin.y = 0;
				rect.origin.x += dx / 2;
				break;
			case AZImageAlignTopLeft:
				rect.origin.y = 0;
				rect.origin.x = 0;
				break;
			case AZImageAlignTopRight:
				rect.origin.y = 0;
				rect.origin.x = dx;
				break;
			case AZImageAlignLeft:
				rect.origin.x = 0;
				rect.origin.y += dy / 2;
				break;
			case AZImageAlignCenter:
				rect.origin.y += dy / 2;
				rect.origin.x += dx / 2;
				break;
			case AZImageAlignRight:
				rect.origin.y += dy / 2;
				rect.origin.x = dx;
				break;
			case AZImageAlignBottom:
				rect.origin.x += dx / 2;
				rect.origin.y += dy;
				break;
			case AZImageAlignBottomLeft:
				rect.origin.y += dy;
				rect.origin.x = 0;
				break;
			case AZImageAlignBottomRight:
				rect.origin.y += dy;
				rect.origin.x = dx;
				break;
			}
		}

	/*************************************************************************\
	|* Are we larger in both dimensions ?
	\*************************************************************************/
	else if ((dx < 0) && (dy < 0))
		{
		switch (_alignment)
			{
			case AZImageAlignTop:
				rect.origin.y = 0;
				break;
			case AZImageAlignTopLeft:
				rect.origin.y = 0;
				rect.origin.x = 0;
				break;
			case AZImageAlignTopRight:
				rect.origin.y = 0;
				rect.origin.x = -dx;
				break;
			case AZImageAlignLeft:
				rect.origin.x = 0;
				break;
			case AZImageAlignCenter:
				rect.origin.y -= dy / 2;
				rect.origin.x -= dx / 2;
				break;
			case AZImageAlignRight:
				rect.origin.x = dx;
				break;
			case AZImageAlignBottom:
				rect.origin.y -= dy;
				break;
			case AZImageAlignBottomLeft:
				rect.origin.y -= dy;
				rect.origin.x = 0;
				break;
			case AZImageAlignBottomRight:
				rect.origin.y -= dy;
				rect.origin.x = dx;
				break;
			}
		}

	/*************************************************************************\
	|* Or are we too wide (in which case we're not tall enough
	\*************************************************************************/
	else if (dx < 0)
		{
		rect.size.height 	= h;
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
	else if (dy < 0)
		{
		rect.size.width 	= w;
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
			[painter rectangleWithRect:self.bounds colour:AZColour.black];
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
