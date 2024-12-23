//
//  AZColour.h
//  Azoth
//
//  Created by Simon Gornall on 12/12/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZColour : NSObject <NSCopying>

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithByteR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;
- (instancetype) initWithR:(float)r g:(float)g b:(float)b a:(float)a;

+ (AZColour *) colourWithByteR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;
+ (AZColour *) colourWithR:(float)r g:(float)g b:(float)b a:(float)a;



// MARK: predefined colours

+ (AZColour *) redColour;
+ (AZColour *) greenColour;
+ (AZColour *) blueColour;
+ (AZColour *) blackColour;
+ (AZColour *) whiteColour;
+ (AZColour *) grey25Colour;
+ (AZColour *) grey50Colour;
+ (AZColour *) grey75Colour;
+ (AZColour *) magentaColour;
+ (AZColour *) yellowColour;
+ (AZColour *) brownColour;
+ (AZColour *) cyanColour;
+ (AZColour *) orangeColour;
+ (AZColour *) purpleColour;
+ (AZColour *) clearColour;
+ (AZColour *) controlColour;
+ (AZColour *) controlBackgroundColour;



// MARK: uint8_t accessors

- (uint8_t) red;
- (uint8_t) green;
- (uint8_t) blue;
- (uint8_t) alpha;



// MARK: property uint8_t

@property(assign, nonatomic) float 						r;
@property(assign, nonatomic) float 						g;
@property(assign, nonatomic) float 						b;
@property(assign, nonatomic) float 						a;
@end

NS_ASSUME_NONNULL_END
