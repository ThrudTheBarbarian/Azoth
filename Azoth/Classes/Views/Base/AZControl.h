//
//  AZControl.h
//  Azoth
//
//  Created by Simon Gornall on 12/15/24.
//

#import <Azoth/AZObject.h>
#import <Azoth/AZView.h>

typedef enum
	{
	ControlStateNormal			= 0,
	ControlStateHighlighted		= 1,
	ControlStateDisabled		= 2
	} AZControlState;

NS_ASSUME_NONNULL_BEGIN

@interface AZControl : AZView
/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame;

@property(assign, nonatomic) SEL 								action;
@property(strong, nonatomic) NSObject *							target;
@property(assign, nonatomic) AZControlState						state;
@property(strong, nonatomic) NSString *							stringValue;
@end

NS_ASSUME_NONNULL_END
