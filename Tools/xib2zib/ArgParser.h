//
//  ArgParser.h
//  Azoth
//
//  Created by ThrudTheBarbarian on 1/2/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ArgParser : NSObject

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
+ (ArgParser *) parserWith:(int)argc and:(const char *_Nullable*_Nullable)argv;

/*****************************************************************************\
|* Search for a string argument
\*****************************************************************************/
- (NSString *) stringFor:(NSString *)arg
					  or:(NSString *)alt
		     withDefault:(NSString *)dflt
					help:(NSString *)msg;

/*****************************************************************************\
|* Search for an integer argument
\*****************************************************************************/
- (int) intFor:(NSString *)arg
  		    or:(NSString *)alt
   withDefault:(int)dflt
  		  help:(NSString *)msg;

/*****************************************************************************\
|* Search for a double argument
\*****************************************************************************/
- (int) doubleFor:(NSString *)arg
  		       or:(NSString *)alt
      withDefault:(int)dflt
  		     help:(NSString *)msg;

/*****************************************************************************\
|* Search for a flag argument
\*****************************************************************************/
- (BOOL) flagFor:(NSString *)arg
			  or:(NSString *)alt
		    help:(NSString *)msg;


/*****************************************************************************\
|* Remaining args after processing through all the flags
\*****************************************************************************/
- (NSArray<NSString *> *) remainingArgs;

/*****************************************************************************\
|* Show the help message
\*****************************************************************************/
- (void) showHelp;



/*****************************************************************************\
|* Properties
\*****************************************************************************/

// Printed at the top of the usage text. Expects a '%@'
// to demark where the program name should go
@property(strong, nonatomic) NSString *							usageString;

// Printed after all the arguments are displayed
@property(strong, nonatomic) NSString *							suffixString;
@end

NS_ASSUME_NONNULL_END
