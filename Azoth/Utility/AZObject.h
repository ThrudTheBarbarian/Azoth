//
//  AZObject.h
//  Azoth
//
//  Created by Simon Gornall on 12/13/24.
//

/*****************************************************************************\
|* This is jsut a wrapper class for a pointer - the use of which is context
|* dependent, but usually it's so we can store lists of things-that-aren't-
|* objects into NSArray and friends...
|*
|* The hint is just useful to do a final check to make sure whichever operation
|* is about to be done is valid for this type of object
\*****************************************************************************/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZObject : NSObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithPointer:(void *)ptr;
- (instancetype) initWithPointer:(void *)ptr andHint:(NSString *)hint;

+ (AZObject *) objectWithPointer:(void *)ptr;
+ (AZObject *) objectWithPointer:(void *)ptr andHint:(NSString *)hint;

@property(strong, nonatomic) NSString *		hint;
@property(assign, nonatomic) void *			ptr;
@end

NS_ASSUME_NONNULL_END
