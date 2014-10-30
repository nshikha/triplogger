//
//  LLTrip.m
//  LyftLogger
//
//  Created by Shikha R Nalla on 10/28/14.
//  Copyright (c) 2014 Shikha R Nalla. All rights reserved.
//

#import "LLTrip.h"
#import <AddressBookUI/AddressBookUI.h>

@interface LLTrip ()
@property (strong, nonatomic) CLPlacemark *startPlacemark;
@property (strong, nonatomic) CLPlacemark *endPlacemark;
@end

@implementation LLTrip

- (instancetype) initWithStartLocation:(CLLocation*)location {
    if (self = [super init]) {
        _startLocation = location;
        _lastLocation = location;
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        [geocoder reverseGeocodeLocation:_startLocation
                            completionHandler:^(NSArray *placemarks, NSError *error) {
                                if ([placemarks count] > 0) {
                                    _startPlacemark = [placemarks objectAtIndex:0];
                                }
                            }];
    }
    return self;
}

//Assuming that the user is in a car on land and so the locations are valid, returns the street address
//else for non-valid locations returns "Unknown location" for now.
- (NSString *) formattedLocations {
    NSString *tripLocations = [NSString stringWithFormat:@"%@ > %@", [self _formattedLocation:self.startPlacemark],
                               [self _formattedLocation:self.endPlacemark]];
    return tripLocations;
}

- (NSString *) formattedTime {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *startTime = [dateFormatter stringFromDate:self.startLocation.timestamp];
    NSString *endTime = [dateFormatter stringFromDate:self.lastLocation.timestamp];
    NSUInteger timeInterval = round([self.lastLocation.timestamp timeIntervalSinceDate:self.startLocation.timestamp]);
    NSUInteger minutes = timeInterval/60;
    NSUInteger seconds = timeInterval - minutes*60;
    NSString *duration = nil;
    if (minutes == 0) {
        duration = [NSString stringWithFormat:@"%lu sec", (unsigned long)seconds];
    }
    else {
        duration = [NSString stringWithFormat:@"%lu min, %lu sec", (unsigned long)minutes, (unsigned long)seconds];
    }
    NSString *time = [NSString stringWithFormat:@"%@-%@ (%@)", startTime, endTime, duration];
    return time;
}

#pragma mark - private

- (NSString *) _formattedLocation:(CLPlacemark*)placemark {
    if (!(placemark.subThoroughfare || placemark.thoroughfare)) {
        return @"Unknown Location";
    }
    if (placemark.subThoroughfare) {
        return [NSString stringWithFormat:@"%@ %@", placemark.subThoroughfare, placemark.thoroughfare];
    }
    return [NSString stringWithFormat:@"%@", placemark.thoroughfare];
}



@end
