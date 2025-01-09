//
//  CVItemViewController.h
//  AZCollectionView
//
//  Created by Simon Gornall on 1/8/25.
//

#import <Azoth/Azoth.h>

NS_ASSUME_NONNULL_BEGIN

@interface CVItemViewController : AZViewController

@property (strong, nonatomic) IBOutlet AZImageView *image;
@property (strong, nonatomic) IBOutlet AZLabel *label;
@end

NS_ASSUME_NONNULL_END
