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
|* Fills out an array with the top-level objects in the ZIB, not including the
|* owner
\*****************************************************************************/
- (BOOL)loadZibNamed:(NSString *)nibName
               owner:(id)owner
	 topLevelObjects:(nullable NSMutableArray *)topLevelObjects;

@end

NS_ASSUME_NONNULL_END
