//
//  AZNibHelpConnector.h
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import <Azoth/AZNibConnector.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZNibHelpConnector : AZNibConnector


/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The help file
@property(copy, nonatomic) NSString *						file;

// The help marker
@property(copy, nonatomic) NSString *						marker;
@end

NS_ASSUME_NONNULL_END
