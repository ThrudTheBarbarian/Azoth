//
//  AZPainter.h
//  Azoth
//
//  Created by Simon Gornall on 12/12/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AZView;

@interface AZPainter : NSObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithView:(AZView *)view;
+ (AZPainter *) painterForView:(AZView *)view;


// MARK: Execution of the draw routine

/*****************************************************************************\
|* Set up the context and draw
\*****************************************************************************/
- (void) execute;


// MARK: drawing routines


// MARK: Properties

@property(strong, nonatomic) AZView * 							view;
@end

NS_ASSUME_NONNULL_END
