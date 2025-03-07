//
//  AZTextPainter.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 12/14/24.
//

#import <Foundation/Foundation.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

/*****************************************************************************\
|* Type declarations
\*****************************************************************************/
@class AZColour;
@class AZFont;

@protocol AZRenderer;

@interface AZTextPainter : NSObject
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithRenderer:(id<AZRenderer>)renderer;
+ (AZTextPainter *) painterWithRenderer:(id<AZRenderer>)renderer;

/*****************************************************************************\
|* Basic drawing routine
\*****************************************************************************/
- (NSRect) drawAtX:(float)x y:(float)y text:(NSString *)text;

/*****************************************************************************\
|* Draw centered  in both X,Y inside a clipping rectangle, on a single line
\*****************************************************************************/
- (NSRect) drawInBox:(NSRect)box text:(NSString *)text;

/*****************************************************************************\
|* Draw inside a clipping rectangle, moving words to make everything fit
\*****************************************************************************/
- (NSRect) drawColumnsInBox:(NSRect)box text:(NSString *)text;

/*****************************************************************************\
|* Return the width, height of any text string in the current font
\*****************************************************************************/
- (int) textWidthFor:(NSString *)fmt, ...;
- (int) textHeightFor:(NSString *)fmt, ...;

/*****************************************************************************\
|* Rendering method
\*****************************************************************************/
- (NSRect) renderFrom:(NSRect)rect in:(NSInteger)textureId at:(NSPoint)p;

/*****************************************************************************\
|* Utility method - return an initialised effect structure
\*****************************************************************************/
+ (AZFontEffect) mkEffect:(AZTextAlignment)align
					    r:(uint8_t)r
					    g:(uint8_t)g
					    b:(uint8_t)b
					    a:(uint8_t)a;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Renderer for drawing with
@property(assign, nonatomic) id<AZRenderer>					renderer;

// Font to use
@property(strong, nonatomic) AZFont *						font;

// Colour to draw in
@property(strong, nonatomic) AZColour *						colour;

// Text alignment
@property(assign, nonatomic) AZTextAlignment				alignment;

// Text scaling factors
@property(assign, nonatomic) AZScale						scale;

// Angle to draw at (0, 90, 180, 270)
@property(assign, nonatomic) int							angle;

@property(assign, nonatomic) NSPoint						rotateAbout;
@end

NS_ASSUME_NONNULL_END
