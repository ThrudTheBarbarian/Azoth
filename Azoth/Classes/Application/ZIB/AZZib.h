//
//  AZZib.h
//  Azoth
//
//  Created by Simon Gornall on 1/3/25.
//

#import <Foundation/Foundation.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kZibAction;
extern NSString * const kZibCircular;
extern NSString * const kZibClassname;
extern NSString * const kZibClosable;
extern NSString * const kZibColumns;
extern NSString * const kZibConnect;
extern NSString * const kZibContentRect;
extern NSString * const kZibDestination;
extern NSString * const kZibEditable;
extern NSString * const kZibFrame;
extern NSString * const kZibId;
extern NSString * const kZibIdentifier;
extern NSString * const kZibHasHeaderView;
extern NSString * const kZibHLineScroll;
extern NSString * const kZibHPageScroll;
extern NSString * const kZibHScroller;
extern NSString * const kZibLabel;
extern NSString * const kZibMaxValue;
extern NSString * const kZibMaxWidth;
extern NSString * const kZibMinValue;
extern NSString * const kZibMinWidth;
extern NSString * const kZibObjects;
extern NSString * const kZibOutlet;
extern NSString * const kZibOwner;
extern NSString * const kZibProperty;
extern NSString * const kZibPullsDown;
extern NSString * const kZibResizeMask;
extern NSString * const kZibRound;
extern NSString * const kZibRowHeight;
extern NSString * const kZibSegments;
extern NSString * const kZibSelect;
extern NSString * const kZibSelectMultiple;
extern NSString * const kZibSelector;
extern NSString * const kZibStyle;
extern NSString * const kZibSubviews;
extern NSString * const kZibTarget;
extern NSString * const kZibTextColour;
extern NSString * const kZibTitle;
extern NSString * const kZibType;
extern NSString * const kZibValue;
extern NSString * const kZibVertical;
extern NSString * const kZibView;
extern NSString * const kZibVLineScroll;
extern NSString * const kZibVPageScroll;
extern NSString * const kZibVScroller;
extern NSString * const kZibWidth;
extern NSString * const kZibWindow;

@interface NSObject (AZZib)
- (void) awakeFromNib;
@end


@interface AZZib : NSObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithFile:(NSString *)path;
+ (AZZib *) zibWithFile:(NSString *)path;

/*****************************************************************************\
|* Inflate the ZIB file so we have real objects, not a dictionary representation
\*****************************************************************************/
- (BOOL) inflateWithOwner:(NSObject *)owner
			   andOptions:(NSDictionary<AZZibOptionsKey, id> *)options;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

@end

NS_ASSUME_NONNULL_END
