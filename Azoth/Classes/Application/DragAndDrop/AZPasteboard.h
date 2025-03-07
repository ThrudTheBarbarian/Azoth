//
//  AZPasteboard.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/9/25.
//

#import <Foundation/Foundation.h>
#import <Azoth/AZTypes.h>

NS_ASSUME_NONNULL_BEGIN

extern AZPasteboardType const AZPasteboardTypeColour;
extern AZPasteboardType const AZPasteboardTypeImage;
extern AZPasteboardType const AZPasteboardTypeString;
extern AZPasteboardType const AZPasteboardTypeURL;

extern AZPasteboardName const AZPasteboardNameDrag;
extern AZPasteboardName const AZPasteboardNameGeneral;

@class AZPasteboard;

/*****************************************************************************\
|* Objects implementing this protocol can be written to the pasteboard using
|* the -writeObjects method below. Supported object classes in the property
|* list are:
|*
|*  o NSArray
|*  o NSDictionary
|*  o NSString
|*  o NSData
|*  o NSNumber
|*
|* Basically, a property list object must be supported by the methods in
|* NSPropertyListSerialization
\*****************************************************************************/
@protocol AZPasteboardWriting

// Returns an array of AZPasteboardType strings of data types the receiver can
// write to a given pasteboard
- (NSArray<NSString *> *) writableTypesForPasteboard:(AZPasteboard *)pasteboard;

// Returns a plist for the type requested
- (id) pasteboardPropertyListForType:(AZPasteboardType) type;
@end



@interface AZPasteboard : NSObject

/*****************************************************************************\
|* Initialisation. Use the the class method, not -init
\*****************************************************************************/
- (instancetype) init NS_UNAVAILABLE;
+ (nullable AZPasteboard *) pasteboardWithName:(AZPasteboardName) name;

/*****************************************************************************\
|* Sets the property list as the value for the given type in this pasteboard.
|* If you want to set multiple items, encode them as elements within an
|* NSArray or NSDictionary top-level item
\*****************************************************************************/
- (BOOL) setPropertyList:(id)plist forType:(AZPasteboardType)dataType;

/*****************************************************************************\
|* Convenience method to set a string as the pasteboard payload for a type
\*****************************************************************************/
- (BOOL) setString:(NSString *)payload;
- (BOOL) setString:(NSString *)payload forType:(AZPasteboardType)dataType;

/*****************************************************************************\
|* Returns a list of the pasteboard types set within this pasteboard
\*****************************************************************************/
- (NSArray<AZPasteboardType> *) datatypes;

/*****************************************************************************\
|* Returns the data for the specified type from the first item in the
|* receiver that contains the type
\*****************************************************************************/
- (NSData *) dataForType:(AZPasteboardType)dataType;

/*****************************************************************************\
|* Returns the property list for the specified type from the first item in the
|* receiver that contains the type
\*****************************************************************************/
- (id) propertyListForType:(AZPasteboardType)dataType;

/*****************************************************************************\
|* Returns a string value (if it can be decoded) for a given type.
\*****************************************************************************/
- (NSString *) string;
- (NSString *) stringForType:(AZPasteboardType)dataType;

/*****************************************************************************\
|* Clears the existing contents of the pasteboard. Returns the change-count
\*****************************************************************************/
- (NSInteger) clearContents;

/*****************************************************************************\
|* Writes an array of objects to the receiver, assuming they all implement
|* the AZPasteboardWriting protocol
\*****************************************************************************/
- (BOOL) writeObjects:(NSArray<id<AZPasteboardWriting>> *) objects;



/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Return the number of items at the top-level of the ,
// pasteboard which is 1 for most pasteboardsm and
// however many objects were written, if -writeObjects
// was called
@property (assign, nonatomic, readonly) NSInteger			itemCount;

// A number that identifies a pasteboard, changing every
// time the pasteboard does
@property (assign, nonatomic) NSInteger 					changes;

// Class method to return the system pasteboard
@property (class, strong, readonly) AZPasteboard * 		generalPasteboard;

// Class method to return the dragging pasteboard
@property (class, strong, readonly) AZPasteboard * 		draggingPasteboard;
@end

NS_ASSUME_NONNULL_END
