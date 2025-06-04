//
//  AZAlertView.m
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import "AZAlertView.h"
#import "AZApplication.h"
#import "AZButton.h"
#import "AZColour.h"
#import "AZFont.h"
#import "AZPainter.h"
#import "AZRenderer.h"
#import "AZTypes.h"

#define WIDTH       400
#define HEIGHT      170


@interface AZAlertView()

// The lines in the message
@property(assign, nonatomic) NSArray<NSString *> *					msgs;

// Which type of view we are
@property(assign, nonatomic) AZAlertType                            type;
@end


@implementation AZAlertView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithMessage:(NSString *)lines ofType:(AZAlertType)type
	{
	if (self = [super initWithFrame:NSMakeRect(0,0,WIDTH, HEIGHT)])
		{
		_type = type;
		_msgs = [lines componentsSeparatedByString:@"|"];

		NSPoint pt   = NSMakePoint(340, 125);
		AZButton *ok = [AZButton buttonWithText:@"OK" at:pt];
		[ok setAction:@selector(okPressed:)];
		[ok setTarget:self];
		[self addSubview:ok];

		[self setIsOpaque:YES];
			[self setBackgroundColour:AZColour.grey75];
		}
		return self;
	}

+ (instancetype) withMessage:(NSString *)lines ofType:(AZAlertType)type
	{
	return [[AZAlertView alloc] initWithMessage:lines ofType:type];
	}


/*****************************************************************************\
|* Draw the view
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[super drawInRect:dirtyRect withPainter:painter];

	[painter rectangleWithRect:self.bounds colour:AZColour.black];

	NSRect src 	= (_type == AZAlertTypeWarning)
				? [AZApp srcRectFor:@"alert-info" in:kUiMap]
				: [AZApp srcRectFor:@"alert-error" in:kUiMap];
	NSRect dst  = src;
	dst.origin  = NSMakePoint(20,(HEIGHT-src.size.height)/2);

	AZFont *font = [AZApp systemFontWithSize:16];
	[painter setFont:font];
	[painter setTextColour:AZColour.black];

	int x	= 90;
	int y 	= 50;
	for (NSString *msg in _msgs)
		{
		[painter textAtX:x y:y text:msg];
		y += font.height+5;
		}

	id<AZRenderer> azr	= AZRenderer.renderer;
	NSInteger ui		= [AZApp textureFor:kUiMap];
	[azr blitFrom:ui src:src dst:dst];
	}


/*****************************************************************************\
|* User pressed ok
\*****************************************************************************/
- (void) okPressed:(id)sender
	{
	[self removeFromSuperview];
	}
@end
