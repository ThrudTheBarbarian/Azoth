//
//  AZTextField.h
//  Azoth
//
//  Created by Simon Gornall on 12/16/24.
//

#import <Azoth/AZControl.h>

typedef enum
	{
	TextFieldSquare 			= 0,
	TextFieldRounded			= 3,
	} AZTextFieldType;

NS_ASSUME_NONNULL_BEGIN

@interface AZTextField : AZControl

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
+ (AZTextField *) textfieldWithFrame:(NSRect)frame;

// Whether it's a rounded or square textfield
@property(assign, nonatomic) AZTextFieldType						type;

// Colour for the text in the textbox, default is black
@property(strong, nonatomic) AZColour *								textColour;
@end

NS_ASSUME_NONNULL_END
