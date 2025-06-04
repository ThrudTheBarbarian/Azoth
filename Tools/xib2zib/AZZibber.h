//
//  AZZibber.h
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZZibber : NSObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
+ (AZZibber *) zibberWithDictionary:(NSDictionary *)info;
- (instancetype) initWithDictionary:(NSDictionary *)info;

/*****************************************************************************\
|* Run through the XIB, creating the ZIB
\*****************************************************************************/
- (void) process;

/*****************************************************************************\
|* Dump to stdout (mainly debugging)
\*****************************************************************************/
- (void) dump;

/*****************************************************************************\
|* Save the ZIB
\*****************************************************************************/
- (void) save:(NSString *)path;


@property(assign, nonatomic) BOOL							isMainWindow;
@end

NS_ASSUME_NONNULL_END
