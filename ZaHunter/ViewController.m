//
//  ViewController.m
//  ZaHunter
//
//  Created by Anthony  Severino on 1/22/14.
//  Copyright (c) 2014 Simple Management Solutions, Inc. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>


@interface ViewController () <UITableViewDelegate,UITableViewDataSource,CLLocationManagerDelegate,MKMapViewDelegate>
{
    __weak IBOutlet UITableView *myTableView;
    CLLocation *myCurrentLocation;
    CLLocationManager *locationManager;
    NSArray *locationArray;
    __weak IBOutlet UILabel *tableViewFooterLabel;
    MKRoute *route;
    MKRoute *route2;

    
    double seconds;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    locationManager =[[CLLocationManager alloc]init];
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
}
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *location in locations) {
        if (location.verticalAccuracy > 1000 || location.horizontalAccuracy > 1000) {
            continue;
        }
        myCurrentLocation = location;
        [locationManager stopUpdatingLocation];
    }
    
    MKLocalSearchRequest *localSearchRequest = [MKLocalSearchRequest new];
    MKCoordinateSpan span = MKCoordinateSpanMake(0.3, 0.3);
    MKCoordinateRegion region = MKCoordinateRegionMake(myCurrentLocation.coordinate, span);
    
    localSearchRequest.region = region;
    localSearchRequest.naturalLanguageQuery = @"pizza";
    
    MKLocalSearch *localSearch = [[MKLocalSearch alloc]initWithRequest:localSearchRequest];
    
    [localSearch startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        locationArray = response.mapItems;

        locationArray  = [locationArray sortedArrayUsingComparator:^NSComparisonResult(MKMapItem *obj1, MKMapItem *obj2) {
            CLLocation *location1 = [[CLLocation alloc] initWithLatitude:obj1.placemark.coordinate.latitude longitude:obj1.placemark.coordinate.longitude];
            CLLocation *location2 = [[CLLocation alloc] initWithLatitude:obj2.placemark.coordinate.latitude longitude:obj2.placemark.coordinate.longitude];
            
            CLLocationDistance distance1 = [myCurrentLocation distanceFromLocation:location1];
            CLLocationDistance distance2 = [myCurrentLocation distanceFromLocation:location2];
            
            if (distance1 > distance2) {
                return NSOrderedDescending;
            }
            if (distance1 < distance2) {
                return NSOrderedAscending;
            }
        
            return NSOrderedSame;
        }];
        
        [myTableView reloadData];
        [self calculateTimeForTableFooter];
    }];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [myTableView dequeueReusableCellWithIdentifier:@"PIzzaCellID"];
    MKMapItem *tempMapItem = locationArray[indexPath.row];
    cell.textLabel.text = tempMapItem.name;
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(myCurrentLocation.coordinate.latitude, myCurrentLocation.coordinate.longitude);
    MKPlacemark *tempPlacemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
    MKMapItem *tempMapItem2 = [[MKMapItem alloc] initWithPlacemark:tempPlacemark];
    
    MKDirectionsRequest *directionRequest = [[MKDirectionsRequest alloc]init];
    directionRequest.source = tempMapItem2;
    directionRequest.destination = tempMapItem;
    MKDirections *directions = [[MKDirections alloc]initWithRequest:directionRequest];
    
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        route = response.routes.firstObject;
        CLLocationDistance distance = route.distance;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f meters", distance];
    }];
    
    return cell;
}


-(void)calculateTimeForTableFooter {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(myCurrentLocation.coordinate.latitude, myCurrentLocation.coordinate.longitude);
    MKPlacemark *tempPlacemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
    MKMapItem *currentLocationMapItem = [[MKMapItem alloc] initWithPlacemark:tempPlacemark];

    NSArray *calculateTimeArray = @[currentLocationMapItem, locationArray[0], locationArray[1], locationArray[2], locationArray[3]];
    
    seconds = 0;
    
    for (int i = 0; i < (calculateTimeArray.count - 1); i++) {
 
        MKDirectionsRequest *directionRequest = [[MKDirectionsRequest alloc]init];
        directionRequest.source = calculateTimeArray[i];
        directionRequest.destination = calculateTimeArray[i + 1];
        directionRequest.transportType = MKDirectionsTransportTypeWalking;
        MKDirections *directions = [[MKDirections alloc]initWithRequest:directionRequest];
        
        [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
            route2 = response.routes.firstObject;
            NSLog(@"%f", route2.expectedTravelTime);
            seconds += (double)route2.expectedTravelTime;
            tableViewFooterLabel.text = [NSString stringWithFormat:@"%.0f minutes", ((seconds/60) + 150)];
        }];
    }
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"%@",error);
}

@end
