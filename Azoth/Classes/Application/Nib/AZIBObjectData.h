//
//  AZIBObjectData.h
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import <Foundation/Foundation.h>

@class AZMenu;

NS_ASSUME_NONNULL_BEGIN

@interface AZIBObjectData : NSObject

- (void)buildConnectionsWithNameTable:(NSDictionary *)nameTable;

- (AZMenu *)mainMenu;
- (NSArray *)topLevelObjects;

@property(strong, nonatomic) NSSet<NSObject *> *		visibleWindows;
@end

NS_ASSUME_NONNULL_END
