//
//  AZButton.h
//  Azoth
//
//  Created by Simon Gornall on 12/15/24.
//

#import <Azoth/AZView.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum
	{
	ButtonTypePlain 			= 0,
	ButtonTypeDefault			= 3,
	ButtonTypeRounded			= 6,
	ButtonTypeRoundedDefault	= 9
	} AZButtonType;

@interface AZButton : AZView
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame;
+ (AZButton *) buttonWithFrame:(NSRect)frame;
+ (AZButton *) buttonWithText:(NSString *)text at:(NSPoint)p;


@property(assign, nonatomic) AZButtonType						type;
@end

NS_ASSUME_NONNULL_END
