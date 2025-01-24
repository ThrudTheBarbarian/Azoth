//
//  main.m
//  xib2zib
//
//  Created by Simon Gornall on 1/2/25.
//

#import <Foundation/Foundation.h>

#import "ArgParser.h"
#import "AZDictionary.h"
#import "AZZibber.h"

int main(int argc, const char * argv[])
	{
	@autoreleasepool
		{
		ArgParser *ap = [ArgParser parserWith:argc and:argv];
		[ap setUsageString:@"Usage: %@ <any args> [path to XIB file]\n\n"
						    "where args are from:\n"];

		[ap setSuffixString:
			@"  [..] indicate required arguments if the option is given\n"
			 "  <..> indicate optional arguments\n\nEnjoy."];

		BOOL dump 	= [ap flagFor:@"-D"
							   or:@"--dump-orig"
							 help:@"Dump XIB dictionary to stdout"];

		BOOL result	= [ap flagFor:@"-d"
							   or:@"--dump-results"
							 help:@"Dump ZIB dictionary to stdout"];

		BOOL help 	= [ap flagFor:@"-h"
							   or:@"--help"
							 help:@"Show this wonderful help and exit"];

		NSString *outFile = [ap stringFor:@"-o"
									   or:@"--output [path]"
							  withDefault:@"main.zib"
									 help:@"Path to write the ZIB to"];

		if (help)
			{
			[ap showHelp];
			return 0;
			}
			
		NSString *path = ap.remainingArgs.firstObject;
		NSString *file = [path.lastPathComponent stringByDeletingPathExtension];
		BOOL isMain	   = [file.lowercaseString isEqualToString:@"main"];

		NSFileManager *fm = NSFileManager.defaultManager;
		if ([fm fileExistsAtPath:path])
			{
			NSData *data 			= [NSData dataWithContentsOfFile:path];
			NSError *error			= nil;
			NSDictionary *parsed	= [AZDictionary dictionaryWithXML:data
															 andError:&error];
			if (error != nil)
				NSLog(@"Error: %@", error);

			if (dump)
				printf("source:\n%s", parsed.description.UTF8String);

			AZZibber *zibber = [AZZibber zibberWithDictionary:parsed];
			zibber.isMainWindow = isMain;
			[zibber process];

			if (result)
				[zibber dump];

			if (outFile.length > 0)
				[zibber save:outFile];
			}
		else
			fprintf(stderr, "Cannot read file at '%s'", path.UTF8String);
		}

	return 0;
	}
