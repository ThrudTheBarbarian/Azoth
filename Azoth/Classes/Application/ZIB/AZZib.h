//
//  AZZib.h
//  Azoth
//
//  Created by Simon Gornall on 1/3/25.
//

#import <Foundation/Foundation.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kZibObjects;
extern NSString * const kZibClassname;
extern NSString * const kZibConnect;
extern NSString * const kZibIdentifier;
extern NSString * const kZibOwner;
extern NSString * const kZibWindow;
extern NSString * const kZibContentRect;
extern NSString * const kZibStyle;
extern NSString * const kZibClosable;
extern NSString * const kZibTitle;
extern NSString * const kZibView;
extern NSString * const kZibFrame;
extern NSString * const kZibResizeMask;
extern NSString * const kZibSubviews;
extern NSString * const kZibType;

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
