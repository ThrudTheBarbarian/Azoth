//
//  PointView.h
//  Azoth
//
//  Created by Simon Gornall on 3/18/25.
//

#import <Azoth/Azoth.h>

NS_ASSUME_NONNULL_BEGIN

@interface PointView : AZView

// IBOutlets
@property(strong) IBOutlet AZLabel *								point1;
@property(strong) IBOutlet AZLabel *								point2;
@end

NS_ASSUME_NONNULL_END
