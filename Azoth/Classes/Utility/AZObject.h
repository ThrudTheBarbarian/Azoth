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
- (instancetype) initWithPointer:(void *)ptr andHint:(nullable NSString *)hint;
- (instancetype) initWithRect:(NSRect)rect;
- (instancetype) initWithRect:(NSRect)rect andHint:(nullable NSString *)hint;
- (instancetype) initWithPoint:(NSPoint)p;
- (instancetype) initWithPoint:(NSPoint)p andHint:(nullable NSString *)hint;

+ (AZObject *) objectWithPointer:(void *)ptr;
+ (AZObject *) objectWithPointer:(void *)ptr andHint:(nullable NSString *)hint;
+ (AZObject *) objectWithPoint:(NSPoint)p;
+ (AZObject *) objectWithPoint:(NSPoint)p andHint:(nullable NSString *)hint;
+ (AZObject *) objectWithRect:(NSRect)rect;
+ (AZObject *) objectWithRect:(NSRect)rect andHint:(nullable NSString *)hint;

@property(copy, nonatomic, nullable) NSString *					hint;
@property(assign, nonatomic) void *								ptr;
@property(assign, nonatomic) NSRect								rect;
@property(assign, nonatomic) NSPoint							p;
@end

NS_ASSUME_NONNULL_END
