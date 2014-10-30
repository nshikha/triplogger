
//
//  TripTableViewController.m
//  LyftLogger
//
//  Created by Shikha R Nalla on 10/28/14.
//  Copyright (c) 2014 Shikha R Nalla. All rights reserved.
//

#import "LLTripTableViewController.h"
#import "LLTripTableViewCell.h"
#import "LLTrip.h"
#import <CoreLocation/CoreLocation.h>

@interface LLTripTableViewController () <UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate>
- (IBAction)toggleTripLogging:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *tripLogSwitch;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *trips;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) LLTrip *currentTrip;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) CLGeocoder *geocoder;
@end

static NSString* const kCellIdentifier = @"TripTableViewCell";
static CGFloat const kMinSpeed = 10.0f;
static CGFloat const kStillSecondsBeforeFinish = 60.0f;

@implementation LLTripTableViewController

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _locationManager = [[CLLocationManager alloc] init];
        _geocoder = [[CLGeocoder alloc] init];
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.delegate = self;
        _trips = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    [self.tableView registerNib:[UINib nibWithNibName:@"LLTripTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kCellIdentifier];
    if ([self.tripLogSwitch isOn]) {
        [self.locationManager startUpdatingLocation];
    }
}

- (IBAction)toggleTripLogging:(id)sender {
    if ([self.tripLogSwitch isOn]) {
        [self.locationManager startUpdatingLocation];
    }
    else {
        self.currentTrip = nil;
        [self.locationManager stopUpdatingLocation];
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Error %@", error.description); 
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (locations.count > 0) {
        CLLocation *location = [locations firstObject];
        if (location.speed >= kMinSpeed && !self.currentTrip) {
            self.currentTrip = [[LLTrip alloc] initWithStartLocation:location];
            self.timer = [NSTimer scheduledTimerWithTimeInterval:(1.0) target:self
                                                        selector:@selector(tripFinish) userInfo:nil repeats:YES];
        }
        //update to most recent location
        if ([self isNewLocation:location] && self.currentTrip.lastLocation.speed != 0) {
            self.currentTrip.lastLocation = location;
        }
    }
}

- (BOOL) isNewLocation:(CLLocation*)location {
    CLLocationCoordinate2D currentCoordinate = self.currentTrip.lastLocation.coordinate;
    if (currentCoordinate.latitude == location.coordinate.latitude &&
        currentCoordinate.longitude == location.coordinate.longitude) {
        return NO;
    }
    return YES;
}


//called by timer every second during a trip, to end a trip if the location hasn't changed for a certain period of time
//(here one minute)
- (void) tripFinish {
    if (self.currentTrip && abs([self.currentTrip.lastLocation.timestamp timeIntervalSinceNow]) >= kStillSecondsBeforeFinish) {
        LLTrip *currentTrip = self.currentTrip;
        [self.trips addObject:currentTrip];
        [self.timer invalidate];
        [self.geocoder reverseGeocodeLocation:currentTrip.lastLocation
                            completionHandler:^(NSArray *placemarks, NSError *error) {
                                if (error) {
                                    NSLog(@"Error %@", error.description);
                                }
                                else {
                                    currentTrip.endPlacemark = [placemarks lastObject];
                                    [self.tableView reloadData];
                                }
                            }];
        self.currentTrip = nil;
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.trips count];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LLTripTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[LLTripTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }
    LLTrip *trip = [self.trips objectAtIndex:([self.trips count] - 1 - indexPath.row)];
    cell.locations.text = [trip formattedLocations];
    cell.times.text = [trip formattedTime];
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0;
}

@end
