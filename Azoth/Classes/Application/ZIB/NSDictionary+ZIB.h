//
//  NSDictionary+ZIB.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/4/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (ZIB)


/*****************************************************************************\
|* Decode an integer resize-mask from the constants in the dictionary
\*****************************************************************************/
- (int) AZResizeMask;


/*****************************************************************************\
|* Return a rectangle that matches a key, eg a 'frame' rect might be defined as
|* <rect key="frame" x="158" y="132" width="163" height="96"/>
\*****************************************************************************/
- (NSRect) AZRectWithKey:(NSString *)key;

/*****************************************************************************\
|* Return a string or a fallback
\*****************************************************************************/
- (NSString *) AZStringWithKey:(NSString *)key orDefault:(NSString *)fallback;

@end

NS_ASSUME_NONNULL_END
