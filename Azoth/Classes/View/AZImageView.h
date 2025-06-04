//
//  AZImageView.h
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <Azoth/AZView.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

@class AZImage;

@interface AZImageView : AZView

/*****************************************************************************\
|* Initialisation: Create with a frame
\*****************************************************************************/
- (instancetype) initWithFrame:(NSRect)frame;

/*****************************************************************************\
|* Initialisation: Create with an image. Frame calculated from the image size
\*****************************************************************************/
+ (instancetype) imageViewWithImage:(AZImage *) image;

/*****************************************************************************\
|* Initialisation: Create with an image and frame. Image will be sized
|* according to the properties below
\*****************************************************************************/
+ (instancetype) imageViewWithImage:(AZImage *) image inFrame:(NSRect)frame;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The text to display if there is no image
@property(strong, nonatomic, nullable) NSString *					noImageText;

// The image displayed within the frame
@property(strong, nonatomic, nullable) AZImage *					image;

// Which type of image alignment (default: AZImageAlignCenter)
@property(assign, nonatomic) AZImageAlignment						alignment;

// Which type of border (default AZImageFrameNone)
@property(assign, nonatomic) AZImageFrameStyle						frameStyle;

// Which type of scaling (default: AZImageScaleProportionallyDown)
@property(assign, nonatomic) AZImageScaling							scaling;

// Whether we should accept drops
@property(assign, nonatomic) BOOL									dropTarget;
@end

NS_ASSUME_NONNULL_END
