//
//  AZControl.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 12/15/24.
//

#import <Foundation/Foundation.h>
#import <Azoth/AZView.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

@class AZFont;

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

- (void) setFloatingPointFormatLeft:(int)left right:(int)right;

/*****************************************************************************\
|* Wrappers around stringValue
\*****************************************************************************/
- (void) setDoubleValue:(double)doubleValue;
- (void) setIntValue:(int)intValue;

- (double) doubleValue;
- (int) intValue;

/*****************************************************************************\
|* Send an action to the target
\*****************************************************************************/
- (void) sendAction:(nullable SEL)action to:(nullable NSObject *)target;

@property(assign, nonatomic) SEL 						action;
@property(assign, nonatomic) SEL 						doubleAction;
@property(strong, nonatomic) NSObject *					target;

@property(assign, nonatomic) AZControlState				state;
@property(assign, nonatomic) BOOL 						enabled;

@property(strong, nonatomic, nullable) NSObject *		objectValue;
@property(copy, nonatomic) NSString *					stringValue;

@property(assign, nonatomic) BOOL						continuous;

@property(strong, nonatomic) AZFont *					font;

@property(copy, nonatomic) NSString *					fpFormat;

@end
NS_ASSUME_NONNULL_END
