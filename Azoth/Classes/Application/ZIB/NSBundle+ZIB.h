//
//  NSBundle+ZIB.h
//  Azoth
//
//  Created by Simon Gornall on 1/3/25.
//

#import <Foundation/Foundation.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

extern AZZibOptionsKey const AZZibExternalObjects;

@interface NSBundle (ZIB)

/*****************************************************************************\
|* Load a named ZIB, assigning ownership of the 'owner' field to the passed
|* object, with a class check, and accepting options to replace the placeholder
|* objects with real concrete ones.
|*
|* Returns an array to the top-level objects in the ZIB, not including the
|* owner or any replaced-placeholder objects.
\*****************************************************************************/
- (NSArray *)loadNibNamed:(NSString *)name
                    owner:(NSObject *)owner 
                  options:(NSDictionary<AZZibOptionsKey, id> *)options;
@end

NS_ASSUME_NONNULL_END
