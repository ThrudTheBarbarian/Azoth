//
//  ZibCoder.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/2/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZCoder : NSCoder
#if 0
/*****************************************************************************\
|* Returns a Boolean value that indicates whether an encoded value is available
|* for a string
\*****************************************************************************/
- (BOOL) containsValueForKey:(NSString *)key;


// MARK: Encoding

/*****************************************************************************\
|* Encode a type against a key
\*****************************************************************************/
- (void)encodeBool:(BOOL)value forKey:(NSString *)key;
- (void)encodeDouble:(double)value forKey:(NSString *)key;
- (void)encodeFloat:(float)value forKey:(NSString *)key;
- (void)encodeInt:(int)value forKey:(NSString *)key;
- (void)encodeInteger:(NSInteger)value forKey:(NSString *)key;
- (void)encodeInt32:(int32_t)value forKey:(NSString *)key;
- (void)encodeInt64:(int64_t)value forKey:(NSString *)key;

/*****************************************************************************\
|* Encode an object against a key. The object must conform to NSCoding
\*****************************************************************************/
- (void)encodeObject:(nullable id<NSCoding>)object forKey:(NSString *)key;

/*****************************************************************************\
|* Encode an NSData against a key
\*****************************************************************************/
- (NSData *)encodeDataObject;

/*****************************************************************************\
|* Encode geometry against a key.
\*****************************************************************************/
- (void)encodePoint:(NSPoint)point forKey:(NSString *)key;
- (void)encodeRect:(NSRect)rect forKey:(NSString *)key;
- (void)encodeSize:(NSSize)size forKey:(NSString *)key;

/*****************************************************************************\
|* Encode an octet-stream against a key
\*****************************************************************************/
- (void)encodeBytes:(nullable const uint8_t *)bytes
             length:(NSUInteger)length
             forKey:(NSString *)key;

/*****************************************************************************\
|*
\*****************************************************************************/
- (void)encodeConditionalObject:(nullable id<NSCoding>)object
						 forKey:(NSString *)key;



// MARK: Decoding

/*****************************************************************************\
|* Decode a type against a key
\*****************************************************************************/
- (BOOL)decodeBoolForKey:(NSString *)key;
- (double)decodeDoubleForKey:(NSString *)key;
- (float)decodeFloatForKey:(NSString *)key;
- (int)decodeIntForKey:(NSString *)key;
- (NSInteger)decodeIntegerForKey:(NSString *)key;
- (int32_t)decodeInt32ForKey:(NSString *)key;
- (int64_t)decodeInt64ForKey:(NSString *)key;

/*****************************************************************************\
|* Decode an octet-stream against a key
\*****************************************************************************/
- (nullable const uint8_t *)decodeBytesForKey:(NSString *)key
							   returnedLength:(nullable NSUInteger *)lengthp;


/*****************************************************************************\
|* Encode an object against a key. The object must conform to NSCoding
\*****************************************************************************/
- (id)decodeObjectForKey:(NSString *)key;

/*****************************************************************************\
|* Decode an NSData against a key
\*****************************************************************************/
- (NSData *)decodeDataObject;


/*****************************************************************************\
|* Encode geometry against a key.
\*****************************************************************************/
- (NSPoint)decodePointForKey:(NSString *)key;
- (NSRect)decodeRectForKey:(NSString *)key;
- (NSSize)decodeSizeForKey:(NSString *)key;

/*****************************************************************************\
|* Decode an object hierarchy based on the first instance of a key, optionally
|* restricting the type of object acceptable via its Class
\*****************************************************************************/
- (id)decodeTopLevelObjectOfClass:(Class)aClass 
                           forKey:(NSString *)key 
                            error:(NSError * _Nullable *)error;

- (id)decodeTopLevelObjectForKey:(NSString *)key 
                           error:(NSError * _Nullable *)error;


/*****************************************************************************\
|* Properties
\*****************************************************************************/

// We actually only support keyed-coding....
@property(assign, nonatomic) BOOL 							allowsKeyedCoding;

#endif
@end

NS_ASSUME_NONNULL_END
