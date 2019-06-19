//
//  ViewController.swift
//  MGM app
//
//  Created by Brian Unggul on 6/13/19.
//  Copyright © 2019 Brian Unggul. All rights reserved.
//

import UIKit
import CoreLocation


class ViewController: UIViewController, CLLocationManagerDelegate {
	
	let locationManager = CLLocationManager()
	let path = "./propertyGeofences-min"
	var geofences = [String: [[String: Any]]]()
	var monitoredProperties = [[String: Any]]()
	var inCircPropNames = Set<String>()
	var inRectPropNames = Set<String>()
	
	
	// MARK: Properties
	@IBOutlet weak var diningButton: UIButton!
	@IBOutlet weak var showsButton: UIButton!
	@IBOutlet weak var nightlifeButton: UIButton!
	@IBOutlet weak var roomsButton: UIButton!
	@IBOutlet weak var latLonLabel: UILabel!
	@IBOutlet weak var locationLabel: UILabel!
	@IBOutlet weak var resortLabel: UILabel!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		locationManager.delegate = self as CLLocationManagerDelegate
		locationManager.requestAlwaysAuthorization()
		locationManager.startUpdatingLocation()
		geofences = getFromFile(path: path)!
		var startedMonitoring = false
		_ = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) {
			(_) in
			let loc = self.locationManager.location
			if loc != nil {
				self.latLonLabel.text = "Lat/Lon: " + String("\(loc!)".prefix(28))
				if !startedMonitoring {
					let monitoredRegions = self.locationManager.monitoredRegions
					for region in monitoredRegions{
						self.locationManager.stopMonitoring(for: region)
					}
					let lat = loc?.coordinate.latitude
					let long = loc?.coordinate.longitude
					self.monitorRelevantProps(lat: lat!, long: long!)
					startedMonitoring = true
				}
			}
		}
	}
	
	// Monitors the relevant properties (inside vs outside Las Vegas)
	func monitorRelevantProps(lat: Double, long: Double) {
		var relProps = [[String: Any]]()
		if userIsInVegas(lat: lat, long: long) {
			relProps = geofences["lvPropertyGeofences"]!
		} else {
			relProps = geofences["regionalPropertyGeofences"]!
		}
		var locations = [String]()
		for property in relProps {
			let centerLat = (property["centerLat"] as! NSString).doubleValue
			let centerLong = (property["centerLong"] as! NSString).doubleValue
			let coordinate = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLong)
			let radius = (property["radius"] as! NSString).doubleValue
			let identifier = property["propertyName"] as! String
			monitorRegionAtLocation(center: coordinate, radius: radius, identifier: identifier)
			monitoredProperties.append(property)
			locations.append(identifier)
		}
		print(locations) // For debugging purposes
		currNearbyCircProps(props: relProps, lat: lat, long: long)
		currNearbyRectProps(props: relProps, lat: lat, long: long)
	}
	
	// Determines if the device is within the Las Vegas geo-fence
	func userIsInVegas(lat: Double, long: Double) -> Bool {
		let latMin = 35.889705
		let latMax = 36.323522
		let longMin = -115.335087
		let longMax = -114.838299
		return (lat >= latMin && lat <= latMax && long >= longMin && long <= longMax);
	}
	
	// Start monitoring the circular geo-fence from specified coordinate and radius
	func monitorRegionAtLocation(center: CLLocationCoordinate2D, radius: Double, identifier: String) {
		if CLLocationManager.authorizationStatus() == .authorizedAlways {
			if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
				let region = CLCircularRegion(center: center, radius: radius, identifier: identifier)
				region.notifyOnEntry = true
				region.notifyOnExit = true
				locationManager.allowsBackgroundLocationUpdates = true
				locationManager.startMonitoring(for: region)
				locationManager.desiredAccuracy = kCLLocationAccuracyBest
				locationManager.startUpdatingLocation()
			}
		}
	}
	
	// Used only when device starts to turn on locationing;
	// Fills inCircPropNames with property names whose circular geo-fences the device
	// is currently within.
	func currNearbyCircProps(props: [[String: Any]], lat: Double, long: Double) {
		let currLoc = CLLocation(latitude: lat, longitude: long)
		for property in props {
			let centerLat = (property["centerLat"] as! NSString).doubleValue
			let centerLong = (property["centerLong"] as! NSString).doubleValue
			let propLoc = CLLocation(latitude: centerLat, longitude: centerLong)
			let radius = (property["radius"] as! NSString).doubleValue
			let identifier = property["propertyName"] as! String
			if (currLoc.distance(from: propLoc) < radius) {
				inCircPropNames.insert(identifier)
				locationManager.startMonitoringSignificantLocationChanges()
				locationManager.pausesLocationUpdatesAutomatically = true
			}
		}
	}
	
	// Used only when device starts to turn on locationing;
	// Fills inRectPropNames with property names whose rectangular geo-fences the
	// device is currently within.
	func currNearbyRectProps(props: [[String: Any]], lat: Double, long: Double) {
		for property in props {
			let minLat = (property["latMinimum"] as! NSString).doubleValue
			let minLong = (property["longMinimum"] as! NSString).doubleValue
			let maxLat = (property["latMaximum"] as! NSString).doubleValue
			let maxLong = (property["longMaximum"] as! NSString).doubleValue
			let identifier = property["propertyName"] as! String
			if (lat >= minLat && lat <= maxLat && long >= minLong && long <= maxLong) {
				inRectPropNames.insert(identifier)
			}
		}
	}
	
	// Delegate function: Triggered when device enters circular geo-fence
	// Changes the text of locationLabel ("curr_location")
	func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
		let identifier = region.identifier
		print("enter " + identifier)
		if region is CLCircularRegion {
			inCircPropNames.insert(identifier)
			displayNearbyLocs()
			locationManager.startMonitoringSignificantLocationChanges()
			locationManager.pausesLocationUpdatesAutomatically = true
		}
	}
	
	// Delegate function: Triggered when device exits circular geo-fence
	// Changes the text of locationLabel ("curr_location")
	func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
		let identifier = region.identifier
		print("exit " + identifier)
		if region is CLCircularRegion {
			inCircPropNames.remove(identifier)
			if inCircPropNames.count > 0 {
				displayNearbyLocs()
			} else {
				locationLabel.text = "Just walking... not near any resorts"
				print("Just walking... not near any resorts")
				locationManager.stopMonitoringSignificantLocationChanges()
			}
		}
	}
	
	// Helper function for displaying nearby locations on device
	func displayNearbyLocs() {
		var toPrint = "I am near "
		let sortedNames = inCircPropNames.sorted()
		for (i, name) in sortedNames.enumerated() {
			if inCircPropNames.count > 1 && i == inCircPropNames.count - 1 {
				toPrint += " and "
			} else if i > 0 {
				toPrint += ", "
			}
			toPrint += name
		}
		print(toPrint)
		locationLabel.text = toPrint
	}
	
	// Delegate function: Triggered when significant location change is detected when inside the circular geo-fence
	func locationManager(_ manager: CLLocationManager,  didUpdateLocations locations: [CLLocation]) {
		let currLocation = locations.last!
		for propName in inCircPropNames {
			for property in monitoredProperties {
				let tempPropName = property["propertyName"] as! String
				if (propName == tempPropName) {
					let currLat = currLocation.coordinate.latitude
					let currLong = currLocation.coordinate.longitude
					let minLat = (property["latMinimum"] as! NSString).doubleValue
					let minLong = (property["longMinimum"] as! NSString).doubleValue
					let maxLat = (property["latMaximum"] as! NSString).doubleValue
					let maxLong = (property["longMaximum"] as! NSString).doubleValue
					let identifier = property["propertyName"] as! String
					if (currLat >= minLat && currLat <= maxLat && currLong >= minLong && currLong <= maxLong) {
						inRectPropNames.removeAll()
						inRectPropNames.insert(identifier)
					} else {
						inRectPropNames.remove(identifier)
					}
					displayResort()
					break
				}
			}
		}
	}
	
	func displayResort() {
		assert(inRectPropNames.count <= 1)
		if inRectPropNames.count == 1 {
			resortLabel.text = "Inside: " + inRectPropNames.first!
		} else {
			resortLabel.text = "Not inside any building"
		}
	}
	
	// Reads json file and turns into dict (only works with [String: [[String: Any]]])
	func getFromFile(path: String) -> [String: [[String: Any]]]? {
		if let path = Bundle.main.path(forResource: path, ofType: "json") {
			do {
				let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
				let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
				if let jsonResult = jsonResult as? [String: [[String: Any]]] {
					return jsonResult
				}
				return nil
			} catch {
				print("error")
			}
		}
		return nil
	}

	// MARK: Actions
	@IBAction func diningButton(_ sender: UIButton) {}
	@IBAction func showsButton(_ sender: UIButton) {}
	@IBAction func nightlifeButton(_ sender: UIButton) {}
	@IBAction func roomsButton(_ sender: UIButton) {}
	@IBAction func unwindToHome(_ sender: UIStoryboardSegue) {}
	
}

