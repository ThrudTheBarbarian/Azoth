//
//  AZNibLoading.h
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// clang has these as builtins, guard against that
#ifndef NIBDEBUG
	#if 0
		#define NIBDEBUG(desc, ...)                                            \
			do {                                                               \
				NSString *location = [NSString stringWithFormat:@			   \
									"%s %ld", __FILE__, (long)__LINE__]; 	   \
				NSString *m = [NSString stringWithFormat:desc, ##__VA_ARGS__]; \
				SDL_Log(@"%s: %s", location.UTF8String, m.UTF8String);         \
			} while(0)
	#else
		#define NIBDEBUG(desc, ...)
	#endif
#endif // !NIBDEBUG

#ifndef IBOutlet
#define IBOutlet
#endif

#ifndef IBAction
#define IBAction void
#endif

@interface NSObject (NSNibLoading)
- (void)awakeFromNib;
@end

/*****************************************************************************\
|* Extend NSBundle to load NIBs
\*****************************************************************************/
@interface NSBundle (NSNibLoading)

+ (BOOL)loadNibFile:(NSString *)path
  externalNameTable:(NSDictionary *)nameTable
		   withZone:(NSZone *)zone;

+ (BOOL)loadNibNamed:(NSString *)name owner:(id)owner;

- (BOOL)loadNibFile:(NSString *)fileName
  externalNameTable:(NSDictionary *)nameTable
		   withZone:(NSZone *)zone;

@end

NS_ASSUME_NONNULL_END
