//
//  AZIconAtlas.h
//  Azoth
//
//  Created by Simon Gornall on 12/28/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AZIconAtlas : NSObject
/*****************************************************************************\
|* Initialisation: with a pre-determined texture/metadata-map
\*****************************************************************************/
- (instancetype) initWithTexture:(NSInteger)texture metadata:(NSDictionary *)map;

/*****************************************************************************\
|* Initialisation: more conveniently...
\*****************************************************************************/
+ (AZIconAtlas *) atlasWithTexture:(NSInteger)texture metadata:(NSDictionary *)map;

/*****************************************************************************\
|* Initialisation: or load in from disk. The name is the file within the
|* Resources/ directory of the framework
\*****************************************************************************/
+ (AZIconAtlas *) atlasWithName:(NSString *)name;


// This is the dictionary holding the image name/offset/size
// within the texture
@property(strong, nonatomic) NSDictionary *							metadata;

// This is the index into the texture-list held by the
// renderer
@property(assign, nonatomic) NSInteger								texture;
@end

NS_ASSUME_NONNULL_END
