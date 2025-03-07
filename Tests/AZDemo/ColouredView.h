//
//  ColouredView.h
//  AZDemo
//
//  Created by ThrudTheBarbarian on 12/24/24.
//

#import <Azoth/Azoth.h>

NS_ASSUME_NONNULL_BEGIN

@interface ColouredView : AZView

- (instancetype) initWithFrame:(NSRect)frame colour:(AZColour *)colour;

@property(assign, nonatomic) int angle;
@end

NS_ASSUME_NONNULL_END
