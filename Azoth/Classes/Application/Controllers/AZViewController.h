//
//  AZViewController.h
//  Azoth
//
//  Created by Simon Gornall on 1/1/25.
//

#import <Azoth/AZResponder.h>

@class AZView;

NS_ASSUME_NONNULL_BEGIN

@interface AZViewController : AZResponder

/*****************************************************************************\
|* Initialisation
\*****************************************************************************/
- (instancetype) initWithNibName:(NSString *)name
						  bundle:(nullable NSBundle*)bundle;


/*****************************************************************************\
|* Load the view
\*****************************************************************************/
- (void)loadView;

/*****************************************************************************\
|* Properties
\*****************************************************************************/

// The name of the NIB we were initialised with
@property(copy, nonatomic) NSString *						nibName;

// The bundle within which the NIB resides
@property(strong, nonatomic, nullable) NSBundle *			bundle;

// The represented object for this view controller
@property(strong, nonatomic) id								representedObject;

// The title
@property(copy, nonatomic) NSString *						title;

// The view we're managing
@property(strong, nonatomic) AZView *						view;
@end

NS_ASSUME_NONNULL_END
