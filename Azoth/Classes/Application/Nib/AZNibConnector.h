//
//  AZNibConnector.h
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZNibConnector : NSObject <NSCoding>


/*****************************************************************************\
|* Replace an original object with another
\*****************************************************************************/
- (void)replaceObject:original withObject:replacement;

/*****************************************************************************\
|* Create the connection
\*****************************************************************************/
- (void)establishConnection;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The "from"
@property(strong, nonatomic) id								source;

// The "to"
@property(strong, nonatomic) id								destination;

// The connection label
@property(copy, nonatomic) NSString *						label;

@end

NS_ASSUME_NONNULL_END
