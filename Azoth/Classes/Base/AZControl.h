//
//  AZControl.h
//  Azoth
//
//  Created by Simon Gornall on 12/15/24.
//

#import <Foundation/Foundation.h>
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

/*****************************************************************************\
|* set the enabled/disabled state (enabled by default)
\*****************************************************************************/
- (BOOL) enabled;
- (void) setEnabled:(BOOL)yn;

/*****************************************************************************\
|* Send an action to the target
\*****************************************************************************/
- (void) sendAction:(nullable SEL)action to:(nullable NSObject *)target;

@property(assign, nonatomic) SEL 								action;
@property(assign, nonatomic) SEL 								doubleAction;
@property(strong, nonatomic) NSObject *							target;

@property(assign, nonatomic) AZControlState						state;
@property(assign, nonatomic) BOOL 								enabled;

@property(strong, nonatomic, nullable) NSObject *				objectValue;
@property(copy, nonatomic) NSString *							stringValue;
@property(assign, nonatomic) double								doubleValue;
@property(assign, nonatomic) BOOL								continuous;
@end

NS_ASSUME_NONNULL_END
