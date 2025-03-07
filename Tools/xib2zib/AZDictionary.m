//
//  AZDictionary.m
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/2/25.
//

#import "AZDictionary.h"

@interface AZDictionary()
@property(strong, nonatomic) NSMutableArray *						xmlStack;
@property(strong, nonatomic) NSMutableString * 						xmlBody;
@property(strong, nonatomic) NSString * 							xmlErrorMsg;
@end

// Add attributes using prefixed keys to prevent collision with
// children. Ex: <a this="is a"><this>collision</this></a>
static NSString* const AttributeKeyPrefix 		= @"";
static NSString* const DictionaryInnerTextKey 	= @"InnerText";
#define PREFIX(key) [AttributeKeyPrefix stringByAppendingString:key]

// Define the error domain for the parser
NSErrorDomain const NSDictionaryXMLErrorDomain = @"NSDictionaryXMLErrorDomain";



@implementation AZDictionary
	
/*****************************************************************************\
|* Create a dictionary from XML
\*****************************************************************************/
+ (NSDictionary *) dictionaryWithXML:(NSData *)xml andError:(NSError **)error
	{
	return [self loadXMLData:xml withError:error];
	}

/*****************************************************************************\
|* Load XML from an NSData
\*****************************************************************************/
+ (NSDictionary *) loadXMLData:(NSData *)xml withError:(NSError **)error
	{
	AZDictionary *dictionary = [AZDictionary new];

	// Create stack with root dictionary at the bottom
	dictionary.xmlStack	= @[NSMutableDictionary.new].mutableCopy;
	dictionary.xmlBody 	= NSMutableString.new;

	// Check for nil data
	if (!xml)
		{
		*error = [AZDictionary error:NSDictionaryXMLErrorNilData with:@""];
        return nil;
		}

    NSXMLParser* parser = [NSXMLParser.alloc initWithData:xml];
    parser.delegate = dictionary;

    BOOL isParsingSuccessful = [parser parse];
	if (isParsingSuccessful)
		{
		dictionary = dictionary.xmlStack.firstObject;
		dictionary = dictionary.copy;
		}
	else
		{
		*error = [AZDictionary error:NSDictionaryXMLErrorParsingFailed
								with:dictionary.xmlErrorMsg];
		dictionary = nil;
		}

	return dictionary;
	}

// MARK: XML parsing methods

/*****************************************************************************\
|* We started an element
\*****************************************************************************/
- (void) 	 parser:(NSXMLParser *)parser
	didStartElement:(NSString *)elementName
	   namespaceURI:(NSString *)namespaceURI
	  qualifiedName:(NSString *)qName
	     attributes:(NSDictionary *)attributeDict
	{
    // Handle inner text if it exists, before proceeding with newly
	// starting object
    self.xmlBody = [self trim:self.xmlBody];
    if (self.xmlBody.length > 0)
		{
		[self handleInnerTextInDictionary:self.xmlStack.lastObject];
		self.xmlBody = NSMutableString.new;
		}

    // Create a new empty dictionary for newly starting object
    NSMutableDictionary* newObj = NSMutableDictionary.new;

    // Add attributes using prefixed keys
    NSMutableDictionary* prefixedAttributeDict = NSMutableDictionary.new;
    for(NSString* key in attributeDict)
        prefixedAttributeDict[PREFIX(key)] = attributeDict[key];
    [newObj addEntriesFromDictionary:prefixedAttributeDict];

    // If there is no existing object, just set it. Otherwise convert it to
    // an array
    id existingObj = self.xmlStack.lastObject[elementName];
    if (!existingObj)
        self.xmlStack.lastObject[elementName] = newObj;
    else if ([existingObj isKindOfClass:NSMutableArray.class])
        [existingObj addObject:newObj];
    else
        self.xmlStack.lastObject[elementName] = @[existingObj, newObj].mutableCopy;

    // Push the new value to stack
    [self.xmlStack addObject:newObj];
	}

/*****************************************************************************\
|* We found inner text
\*****************************************************************************/
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
	{
    // Accumulate inner text
    [self.xmlBody appendString:string];
	}

/*****************************************************************************\
|* We finished an element
\*****************************************************************************/
- (void)	parser:(NSXMLParser *)parser
	 didEndElement:(NSString *)elementName
	  namespaceURI:(NSString *)namespaceURI
	 qualifiedName:(NSString *)qName
	{
    // Keep reference to just ended object
    id endedObj = self.xmlStack.lastObject;

    // Pop the stack
    [self.xmlStack removeLastObject];

    // Handle inner text if exist
    self.xmlBody = [self trim:self.xmlBody];
    if (self.xmlBody.length > 0)
		{
        id lastObj = self.xmlStack.lastObject[elementName];

        // If the last object is an empty dictionary, set inner text
        // directly like {"elementName":"value"}
        if ([lastObj isEqual:NSMutableDictionary.new])
            self.xmlStack.lastObject[elementName] = self.xmlBody;

		// If not empty dictionary, set inner text with predefined key
        else if ([lastObj isKindOfClass:NSMutableDictionary.class])
            [self handleInnerTextInDictionary:lastObj];

		// If an array, handled it considering ended object
        else if ([lastObj isKindOfClass:NSMutableArray.class])
			{
            // If ended object is an empty dictionary, replace it directly
            //  with the inner text
            if ([endedObj isEqual:NSMutableDictionary.new])
				{
                [lastObj addObject:self.xmlBody];
                [lastObj removeObject:endedObj];
				}
            else
				// If not empty, set inner text with predefined key
                [self handleInnerTextInDictionary:endedObj];
			}

        self.xmlBody = NSMutableString.new;
		}
	}

/*****************************************************************************\
|* Whoops!
\*****************************************************************************/
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
	{
	self.xmlErrorMsg = parseError.localizedDescription;
	}

// MARK: Private methods



/*****************************************************************************\
|* Trim a string
\*****************************************************************************/
- (NSMutableString *)trim:(NSString *)input
	{
	static NSCharacterSet *cset = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,
		^{
		cset = NSCharacterSet.whitespaceAndNewlineCharacterSet;
		});

    return [input stringByTrimmingCharactersInSet:cset].mutableCopy;
	}


/*****************************************************************************\
|* Handle inner text within a dictionary
\*****************************************************************************/
- (void)handleInnerTextInDictionary:(NSMutableDictionary *)mutableDict
	{
    // If there is no existing inner text, just set it. Otherwise convert
    // it to an array
    id existingInnerText = mutableDict[DictionaryInnerTextKey];

    if (!existingInnerText)
        mutableDict[DictionaryInnerTextKey] = self.xmlBody;
    else if ([existingInnerText isKindOfClass:NSMutableArray.class])
        [existingInnerText addObject:self.xmlBody];
    else
        mutableDict[DictionaryInnerTextKey] = @[existingInnerText,
											    self.xmlBody].mutableCopy;
	}




// MARK: Error handling

/*****************************************************************************\
|* Report an error
\*****************************************************************************/
+ (NSError *)error:(NSInteger)errorCode with:(NSString *)info
	{
    NSMutableDictionary* userInfo = NSMutableDictionary.new;
	NSString *msg = @"";

    switch (errorCode)
		{
        case NSDictionaryXMLErrorNilData:
            msg = [NSString stringWithFormat:@"XML data is nil. %@", info];
			break;

        case NSDictionaryXMLErrorParsingFailed:
            msg = [NSString stringWithFormat:@"Parsing failed. %@", info];
			break;

        default:
            msg = nil;
			break;
		}

	if (msg)
		userInfo[NSLocalizedDescriptionKey] = msg;

    return [NSError errorWithDomain:NSDictionaryXMLErrorDomain
							   code:errorCode
						   userInfo:userInfo.copy];
	}


@end
