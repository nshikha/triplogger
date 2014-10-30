//
//  LLTrip.h
//  LyftLogger
//
//  Created by Shikha R Nalla on 10/28/14.
//  Copyright (c) 2014 Shikha R Nalla. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LLTrip : NSObject
@property (strong, nonatomic) CLLocation *startLocation;
//most recent location found so far, is updated as it changes
//if the device is still for longer than a minute, the trip has ended
@property (strong, nonatomic) CLLocation *lastLocation;
- (instancetype) initWithStartLocation:(CLLocation*)location;
- (NSString *) formattedTime;
- (NSString *) formattedLocations;
- (void) setEndPlacemark:(CLPlacemark *)endGeoLocation;
@end
