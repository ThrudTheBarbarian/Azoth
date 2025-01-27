//
//  AZSlider.h
//  Azoth
//
//  Created by Simon Gornall on 12/18/24.
//

#import <Azoth/AZControl.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum
	{
	SliderTypeHorizontal		= 0,
	SliderTypeVertical			= 3,
	SliderTypeCircular			= 6,
	} AZSliderType;


@interface AZSlider : AZControl
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame;
+ (AZSlider *) sliderWithFrame:(NSRect)frame;

// Linear or circular
@property(assign, nonatomic) AZSliderType						type;

// Maximum allowed value
@property(assign, nonatomic) double								minValue;

// Minimum allowed value
@property(assign, nonatomic) double								maxValue;

// Whether to show (and snap to) tick-marks
@property(assign, nonatomic) int								tickCount;

@end

NS_ASSUME_NONNULL_END
