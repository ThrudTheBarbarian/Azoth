//
//  OLDAZTextField.h
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <Azoth/AZControl.h>

typedef enum
	{
	TextFieldSquare 			= 0,
	TextFieldRounded			= 3,
	} AZTextFieldType;

NS_ASSUME_NONNULL_BEGIN

@interface OLDAZTextField : AZControl

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
+ (OLDAZTextField *) textfieldWithFrame:(NSRect)frame;

/*****************************************************************************\
|* Programmatically select everything
\*****************************************************************************/
- (void) selectAll;



/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Whether it's a rounded or square textfield
@property(assign, nonatomic) AZTextFieldType						type;

// Whether it's editable or not
@property(assign, nonatomic) BOOL									editable;

// Colour for the text in the textbox, default is black
@property(strong, nonatomic) AZColour *								textColour;
@end

NS_ASSUME_NONNULL_END
