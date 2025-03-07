//
//  AZDraggingItem.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/9/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AZImage;

@protocol AZPasteboardWriting;

@interface AZDraggingItem : NSObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithPasteboardWriter:(id<AZPasteboardWriting>)writer;
+ (instancetype) itemWithPasteboardWriter:(id<AZPasteboardWriting>)writer;

/*****************************************************************************\
|* Set the dragging frame and the content within it
\*****************************************************************************/
- (void) setDraggingFrame:(NSRect)rect contents:(AZImage *)img;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The frame of the dragging item
@property(assign, nonatomic) NSRect								draggingFrame;

// The image we're using for rendering with
@property(strong, nonatomic) AZImage *							image;

// Hold on to the writer
@property(strong, nonatomic) id<AZPasteboardWriting>			writer;
@end

NS_ASSUME_NONNULL_END
