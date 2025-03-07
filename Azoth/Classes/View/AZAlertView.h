//
//  AZAlertView.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/22/25.
//

#import <Azoth/AZView.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZAlertView : AZView

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithMessage:(NSString *)lines ofType:(AZAlertType)type;
+ (instancetype) withMessage:(NSString *)lines ofType:(AZAlertType)type;

@end

NS_ASSUME_NONNULL_END
