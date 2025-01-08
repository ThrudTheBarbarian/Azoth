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
- (instancetype) initWithFloatR:(float)r g:(float)g b:(float)b a:(float)a;

+ (AZColour *) colourWithByteR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b a:(uint8_t)a;
+ (AZColour *) colourWithFloatR:(float)r g:(float)g b:(float)b a:(float)a;

+ (nullable AZColour *) colourNamed:(NSString *)name;


// MARK: predefined colours

+ (AZColour *) red;
+ (AZColour *) green;
+ (AZColour *) blue;
+ (AZColour *) black;
+ (AZColour *) white;
+ (AZColour *) grey12;
+ (AZColour *) grey25;
+ (AZColour *) grey37;
+ (AZColour *) grey50;
+ (AZColour *) grey75;
+ (AZColour *) grey95;
+ (AZColour *) magenta;
+ (AZColour *) yellow;
+ (AZColour *) brown;
+ (AZColour *) cyan;
+ (AZColour *) orange;
+ (AZColour *) purple;
+ (AZColour *) clear;
+ (AZColour *) control;
+ (AZColour *) controlBackground;
+ (AZColour *) grid;
+ (AZColour *) selectedControl;
+ (AZColour *) selectedText;
+ (AZColour *) text;

+ (NSArray<AZColour *> *) controlAlternatingRowBackgroundColours;



// MARK: property as float

@property(assign, nonatomic) float 						redAsFloat;
@property(assign, nonatomic) float 						greenAsFloat;
@property(assign, nonatomic) float 						blueAsFloat;
@property(assign, nonatomic) float 						alphaAsFloat;

// MARK: property as bytes (native format)

@property(assign, nonatomic) uint8_t					R;
@property(assign, nonatomic) uint8_t					G;
@property(assign, nonatomic) uint8_t					B;
@property(assign, nonatomic) uint8_t					A;
@end

NS_ASSUME_NONNULL_END
