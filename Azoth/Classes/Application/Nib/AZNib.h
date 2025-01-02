//
//  AZNib.h
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const AZNibOwner;
extern NSString * const AZNibTopLevelObjects;


@interface AZNib : NSObject <NSKeyedUnarchiverDelegate>

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithContentsOfFile:(NSString *)path;
+ (AZNib *) nibWithContentsOfFile:(NSString *)path;

- initWithContentsOfURL:(NSURL *)url;
+ (AZNib *) nibWithContentsOfURL:(NSURL *)url;

- initWithNibNamed:(NSString *)name bundle:(NSBundle *)bundle;
+ nibWithName:(NSString *)name bundle:(NSBundle *)bundle;

/*****************************************************************************\
|* Entry points once the NIB has loaded to get the object hierarchy
\*****************************************************************************/
- (BOOL)instantiateNibWithExternalNameTable:(NSDictionary *)nameTable;
- (BOOL)instantiateNibWithOwner:owner
				topLevelObjects:(NSArray *_Nullable*_Nullable)objects;

@end

NS_ASSUME_NONNULL_END
