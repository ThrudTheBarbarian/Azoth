//
//  ArgParser.m
//  Azoth
//
//  Created by ThrudTheBarbarian for Azoth.
//

#import "ArgParser.h"

@interface ArgParser()

// Store args
@property(strong, nonatomic) NSArray<NSString *> *					args;

// Program name
@property(copy, nonatomic) NSString *								name;

// Help text
@property(strong, nonatomic)
NSMutableDictionary<NSString *, NSString *>	*						help;

// Remaining args after processing
@property(strong, nonatomic)
NSMutableDictionary<NSNumber *, NSString *>	*						remaining;

@end

@implementation ArgParser

/*****************************************************************************\
|* Convenience initialiser
\*****************************************************************************/
+ (ArgParser *) parserWith:(int)argc and:(const char **)argv
	{
	NSMutableArray *args 			= [NSMutableArray new];
	for (int i=1; i<argc; i++)
		[args addObject:[NSString stringWithUTF8String:argv[i]]];

	ArgParser *parser = [[ArgParser alloc] initWithList:args];
	[parser setName:[NSString stringWithUTF8String:argv[0]]];
	return parser;
	}

/*****************************************************************************\
|* Create a parser
\*****************************************************************************/
- (instancetype) initWithList:(NSArray<NSString *> *)args
	{
	if (self = [super init])
		{
		_args 			= args;
		_help 			= [NSMutableDictionary new];
		_remaining 		= [NSMutableDictionary new];
		_usageString	= @"Usage: %@ [args], where [args] are from:";
		_suffixString	= @"\n\nEnjoy.";

		int i = 0;
		for (NSString *arg in args)
			{
			_remaining[@(i)] = arg;
			i++;
			}
		}

	return self;
	}

/*****************************************************************************\
|* Remaining args
\*****************************************************************************/
- (NSArray<NSString *> *) remainingArgs
	{
	NSMutableArray<NSString *> *remainder = [NSMutableArray new];
	for (NSInteger i=0; i<_args.count; i++)
		{
		NSString *token = _remaining[@(i)];
		if (token)
			[remainder addObject:token];
		}
	return remainder;
	}

/*****************************************************************************\
|* Search for a string argument
\*****************************************************************************/
- (NSString *) stringFor:(NSString *)arg
					  or:(NSString *)alt
		     withDefault:(NSString *)dflt
					help:(NSString *)msg
	{
	[self _addHelpFor:arg and:alt with:msg];

	NSInteger idx = 0;
	for (NSString *entry in _args)
		{
		if (([arg isEqualToString:entry]) || ([alt isEqualToString:entry]))
			if (idx < _args.count - 1)
				{
				[_remaining removeObjectForKey:@(idx)];
				[_remaining removeObjectForKey:@(idx+1)];
				return _args[idx+1];
				}
		idx ++;
		}
	return dflt;
	}

/*****************************************************************************\
|* Search for an integer argument
\*****************************************************************************/
- (int) intFor:(NSString *)arg
  		    or:(NSString *)alt
   withDefault:(int)dflt
  		  help:(NSString *)msg
	{
	[self _addHelpFor:arg and:alt with:msg];

	NSInteger idx = 0;
	for (NSString *entry in _args)
		{
		if (([arg isEqualToString:entry]) || ([alt isEqualToString:entry]))
			if (idx < _args.count - 1)
				{
				[_remaining removeObjectForKey:@(idx)];
				[_remaining removeObjectForKey:@(idx+1)];
				return _args[idx+1].intValue;
				}
		idx ++;
		}
	return dflt;
	}

/*****************************************************************************\
|* Search for a double argument
\*****************************************************************************/
- (int) doubleFor:(NSString *)arg
  		       or:(NSString *)alt
      withDefault:(int)dflt
  		     help:(NSString *)msg
	{
	[self _addHelpFor:arg and:alt with:msg];

	NSInteger idx = 0;
	for (NSString *entry in _args)
		{
		if (([arg isEqualToString:entry]) || ([alt isEqualToString:entry]))
			if (idx < _args.count - 1)
				{
				[_remaining removeObjectForKey:@(idx)];
				[_remaining removeObjectForKey:@(idx+1)];
				return _args[idx+1].doubleValue;
				}
		idx ++;
		}
	return dflt;
	}


/*****************************************************************************\
|* Search for a flag argument
\*****************************************************************************/
- (BOOL) flagFor:(NSString *)arg
			  or:(NSString *)alt
		    help:(NSString *)msg
	{
	[self _addHelpFor:arg and:alt with:msg];

	int idx = 0;
	for (NSString *entry in _args)
		{
		if (([arg isEqualToString:entry]) || ([alt isEqualToString:entry]))
			{
			[_remaining removeObjectForKey:@(idx)];
			return YES;
			}
		idx ++;
		}
	return NO;
	}

/*****************************************************************************\
|* Show the help text
\*****************************************************************************/
- (void) showHelp
	{
	NSString *prog = [_name lastPathComponent];
	NSString *fmt  = [NSString stringWithFormat:_usageString, prog];

	printf("%s\n", fmt.UTF8String);

	// Find the max lengths of both short and total args
	NSInteger maxLen 	= 0;
	NSInteger maxFirst	= 0;

	for (NSString *arg in _help)
		{
		maxLen = (arg.length > maxLen) ? arg.length : maxLen;

		NSArray<NSString *> *split = [arg componentsSeparatedByString:@"|"];
		if (split.count != 2)
			fprintf(stderr, "Warning: badly formatted help, skipping %s\n",
							arg.UTF8String);
		else
			maxFirst = (split[0].length > maxFirst)
					 ? split[0].length
					 : maxFirst;
		}

		NSArray *argList = [_help.allKeys sortedArrayUsingComparator:
			^NSComparisonResult(NSString *s1, NSString *s2)
				{
				return [s1 compare:s2];
				}];

	for (NSString *arg in argList)
		{
		NSArray<NSString *> *split = [arg componentsSeparatedByString:@"|"];
		NSInteger len0 = split[0].length;
		NSInteger len1 = split[1].length;

		NSInteger pad1 = maxFirst - len0;
		for (NSInteger i=0; i<pad1; i++)
			printf(" ");
		printf("  %s|%s", split[0].UTF8String, split[1].UTF8String);

		int pad2 = (int)(maxLen - len0 -len1 - 1 - pad1);
		for (int i=0; i<pad2; i++)
			printf(" ");

		printf(" : %s\n", _help[arg].UTF8String);
		}

	printf("\n%s\n\n", _suffixString.UTF8String);
	}


// Private methods

/*****************************************************************************\
|* Build the help info
\*****************************************************************************/
- (void) _addHelpFor:(NSString *)arg and:(NSString *)alt with:(NSString *)msg
	{
	NSString *key = [NSString stringWithFormat:@"%@|%@", arg, alt];
	_help[key]    = msg;
	}

@end
