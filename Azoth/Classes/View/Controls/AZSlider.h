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

@property(assign, nonatomic) AZSliderType						type;
@property(assign, nonatomic) double								minValue;
@property(assign, nonatomic) double								maxValue;
@end

NS_ASSUME_NONNULL_END
