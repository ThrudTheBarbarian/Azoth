//
//  AZButton.h
//  Azoth
//
//  Created by Simon Gornall on 12/15/24.
//

#import <Azoth/AZControl.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum
	{
	ButtonTypePlain 			= 0,
	ButtonTypeDefault			= 3,
	ButtonTypeRounded			= 6,
	ButtonTypeRoundedDefault	= 9,
	ButtonTypeCheckbox			= 12,
	ButtonTypeRadio				= 15
	} AZButtonType;

@interface AZButton : AZControl
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame;
+ (AZButton *) buttonWithFrame:(NSRect)frame;
+ (AZButton *) buttonWithText:(NSString *)text at:(NSPoint)p;
+ (AZButton *) buttonWithText:(NSString *)text
						   at:(NSPoint)p
					 withFont:(AZFont *)font;

@property(assign, nonatomic) AZButtonType						type;
@property(assign, nonatomic) AZCellImagePosition				imagePosition;
@property(strong, nonatomic) NSString *							radioGroup;
@end

NS_ASSUME_NONNULL_END
