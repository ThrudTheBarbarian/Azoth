//
//  AZLabel.h
//  Azoth
//
//  Created by Simon Gornall on 1/7/25.
//

#import <Azoth/AZControl.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

@class AZFont;

@interface AZLabel : AZControl

/*****************************************************************************\
|* Initialisation (as well as -initWithFrame:, -initWithDictionary:)
\*****************************************************************************/
+ (AZLabel *) labelWithFrame:(NSRect)frame;
+ (AZLabel *) labelWithText:(NSString *)text at:(NSPoint)p;
+ (AZLabel *) labelWithText:(NSString *)text
						 at:(NSPoint)p
				   withFont:(AZFont *)font;



/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Colour to draw the text with
@property(strong, nonatomic) AZColour *							textColour;

// Text alignment within the frame
@property(assign, nonatomic) AZTextAlignment					alignment;
@end

NS_ASSUME_NONNULL_END
