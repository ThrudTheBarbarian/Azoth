//
//  AZSegmentedControl.h
//  Azoth
//
//  Created by Simon Gornall on 12/20/24.
//

#import <Azoth/AZControl.h>

@class AZImage;

NS_ASSUME_NONNULL_BEGIN

typedef enum
	{
	AZSegmentSwitchTrackingSelectOne	= 1,
	AZSegmentSwitchTrackingSelectAny	= 2,
	AZSegmentSwitchTrackingMomentary	= 3
	} AZSegmentSwitchTracking;

@interface AZSegmentedControl : AZControl
/*****************************************************************************\
|* Initialisation with a set of strings
\*****************************************************************************/
+ (instancetype) withLabels:(NSArray<NSString *> *) labels
               trackingMode:(AZSegmentSwitchTracking)mode
					 target:(id) target
					 action:(SEL) action;

/*****************************************************************************\
|* Initialisation with a set of images
\*****************************************************************************/
+ (instancetype) withImages:(NSArray<AZImage *> *) images
				    padding:(int)padding
			   trackingMode:(AZSegmentSwitchTracking)mode
                     target:(id) target
					 action:(SEL) action;

// MARK: Configuring the segment text

/*****************************************************************************\
|* Returns the label of the specified segment
\*****************************************************************************/
- (nullable NSString *) labelForSegment:(NSInteger)segment;

/*****************************************************************************\
|* Sets the label for the specified segment
\*****************************************************************************/
- (void) setLabel:(NSString *)label forSegment:(NSInteger)segment;

/*****************************************************************************\
|* Sets the alignment of the specified segment
\*****************************************************************************/
- (void) setAlignment:(AZTextAlignment) alignment forSegment:(NSInteger)segment;

/*****************************************************************************\
|* Returns the alignment of the specified segment
\*****************************************************************************/
- (AZTextAlignment) alignmentForSegment:(NSInteger) segment;


// MARK: Managing the selected segment

/*****************************************************************************\
|* Returns the index of the selected segment
\*****************************************************************************/
- (NSInteger) indexOfSelectedItem;

/*****************************************************************************\
|* Selects the segment with the specified tag
\*****************************************************************************/
- (BOOL) selectSegmentWithTag:(NSInteger) tag;

/*****************************************************************************\
|* Sets the selection state of the specified segment
\*****************************************************************************/
- (void) setSelected:(BOOL)yn forSegment:(NSInteger)segment;

/*****************************************************************************\
|* Returns a Boolean value indicating whether the specified segment is selected
\*****************************************************************************/
- (BOOL) isSelectedForSegment:(NSInteger) segment;


// MARK: Adjusting the segment spacing


/*****************************************************************************\
|* Sets the width of the specified segment
\*****************************************************************************/
- (void) setWidth:(float)width forSegment:(NSInteger) segment;

/*****************************************************************************\
|* Returns the width of the specified segment
\*****************************************************************************/
- (float) widthForSegment:(NSInteger)segment;


// MARK: Enabling and disabling segments

/*****************************************************************************\
|* Sets the enabled state of the specified segment
\*****************************************************************************/
- (void) setEnabled:(BOOL) enabled forSegment:(NSInteger) segment;

/*****************************************************************************\
|* Returns a Boolean value indicating whether the specified segment is enabled
\*****************************************************************************/
- (BOOL) isEnabledForSegment:(NSInteger) segment;


// MARK: Tags..

/*****************************************************************************\
|* Return the tag of the specified segment
\*****************************************************************************/
- (NSInteger) tagForSegment:(NSInteger) segment;

/*****************************************************************************\
|* Set a tag on a specified segment
\*****************************************************************************/
- (void) setTag:(NSInteger) tag forSegment:(NSInteger) segment;

// The number of segments in the control
@property(assign, nonatomic) NSInteger							segmentCount;

// The currently selected segment
@property(assign, nonatomic) NSInteger 							selectedSegment;

// The current tracking mode
@property(assign, nonatomic) AZSegmentSwitchTracking 			trackingMode;
@end

NS_ASSUME_NONNULL_END
