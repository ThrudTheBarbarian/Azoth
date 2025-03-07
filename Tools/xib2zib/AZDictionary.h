//
//  AZDictionary.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/2/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_ENUM(NSInteger)
	{
    NSDictionaryXMLErrorNilData 		= 1001,
    NSDictionaryXMLErrorParsingFailed 	= 1002
	};

@interface AZDictionary : NSDictionary <NSXMLParserDelegate>

/*****************************************************************************\
|* Create a dictionary from XML
\*****************************************************************************/
+ (NSDictionary *) dictionaryWithXML:(NSData *)xml andError:(NSError **)error;

/*****************************************************************************\
|* Load XML data into a dictionary
\*****************************************************************************/
+ (NSDictionary *) loadXMLData:(NSData *)xml withError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
