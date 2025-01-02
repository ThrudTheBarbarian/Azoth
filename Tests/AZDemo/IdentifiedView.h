//
//  IdentifiedView.h
//  AZDemo
//
//  Created by Simon Gornall on 12/12/24.
//

#import <Azoth/Azoth.h>

NS_ASSUME_NONNULL_BEGIN

@interface IdentifiedView : AZView
	
- (instancetype) initWithFrame:(NSRect)frame andName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
