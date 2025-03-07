//
//  AZLabel.m
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/7/25.
//

#import <SDL3/SDL.h>

#import "AZApplication.h"
#import "AZColour.h"
#import "AZFont.h"
#import "AZLabel.h"
#import "AZNotifications.h"
#import "AZPainter.h"
#import "AZRenderer.h"
#import "AZWindow.h"
#import "AZZib.h"
#import "NSDictionary+ZIB.h"

@implementation AZLabel

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame
	{
	if (self = [super initWithFrame:frame])
		{
		[self _commonLabelInit];
		self.stringValue 		= @"Label";
		}
	return self;
	}

+ (AZLabel *) labelWithFrame:(NSRect)frame
	{
	return [[AZLabel alloc] initWithFrame:frame];
	}

+ (AZLabel *) labelWithText:(NSString *)text at:(NSPoint)p
	{
	return [self labelWithText:text at:p withFont:AZApp.controlFont];
	}

+ (AZLabel *) labelWithText:(NSString *)text
						 at:(NSPoint)p
				   withFont:(AZFont *)font
	{
	int width  			= [font textWidthFor:text];
	NSRect frame		= NSMakeRect(p.x, p.y, width, font.height);
	AZLabel *label		= [[AZLabel alloc] initWithFrame:frame];
	label.stringValue	= text;
	label.font			= font;
	return label;

	}

/*****************************************************************************\
|* Configuration via dictionary. This is called by the NIB loader, but is a
|* valid way to create the view
\*****************************************************************************/
- (instancetype) initWithDictionary:(NSDictionary *)info;
	{
	if (self = [super initWithDictionary:info])
		{
		[self _commonLabelInit];
		self.stringValue 		= [info AZStringWithKey:kZibTitle
											  orDefault:@"Label"];
		NSString *align = info[kZibAlignment];
		if ([align isEqualToString:@"right"])
			_alignment = AZTextAlignmentRight;
		else if ([align isEqualToString:@"center"])
			_alignment = AZTextAlignmentCenter;
		else
			_alignment = AZTextAlignmentLeft;
		}
	return self;
	}

/*****************************************************************************\
|* Common initialisation between -withFrame and -withDictionary
\*****************************************************************************/
- (void) _commonLabelInit
	{
	self.backgroundColour 	= AZColour.clear;
	self.textColour			= AZColour.black;
	self.alignment			= AZTextAlignmentLeft;
	}

/*****************************************************************************\
|* Draw the label
\*****************************************************************************/
- (void) drawInRect:(NSRect)dirtyRect withPainter:(AZPainter *)painter
	{
	[super drawInRect:dirtyRect withPainter:painter];

	[painter setTextColour:_textColour];
	[painter setTextAlignment:_alignment];

	NSRect box = NSInsetRect(self.bounds, 0, 2);
	[painter setFont:self.font];
	[painter textInBox:box text:self.stringValue];
	}

@end
