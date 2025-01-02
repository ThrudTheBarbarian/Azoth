//
//  Node.h
//  AZOutline
//
//  Created by Simon Gornall on 12/31/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Node : NSObject

- (instancetype) initWithName:(NSString *)name;
+ (Node *) nodeWithName:(NSString *)name;

- (BOOL) hasKids;

@property(strong, nonatomic) NSString *							name;
@property(strong, nonatomic) NSMutableArray<Node *> *			kids;
@end

NS_ASSUME_NONNULL_END
