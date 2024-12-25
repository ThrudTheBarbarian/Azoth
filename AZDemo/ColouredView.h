//
//  ColouredView.h
//  AZDemo
//
//  Created by Simon Gornall on 12/24/24.
//

#import <Azoth/Azoth.h>

NS_ASSUME_NONNULL_BEGIN

@interface ColouredView : AZView

- (instancetype) initWithFrame:(NSRect)frame colour:(AZColour *)colour;

@end

NS_ASSUME_NONNULL_END
