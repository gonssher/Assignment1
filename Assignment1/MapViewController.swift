//
//  ViewController.swift
//  Assignment1
//
//  Created by Sherwin Gonsalves on 2020-10-16.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController,CLLocationManagerDelegate , MKMapViewDelegate, RouteViewContDelegate {

    @IBOutlet weak var mapView : MKMapView!
    @IBOutlet weak var segmentValue : UISegmentedControl!
    
    var locationManager = CLLocationManager()
    
    // MARK: - Declarations which are used for passing data to the next controller
    
    var routes = [""]
    var fromlocation : String = ""
    var toLocation : String = ""
    var selectedIndex : Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewWillAppear()
    }
    
    func viewWillAppear() {
        
        getMyCurrrentLocation()
        mapView.delegate = self
        showCompass()
        locationManager.delegate = self
        mapView.delegate = self
        locationManager.requestWhenInUseAuthorization()
        mapTrackButton()
        showScale()
        
    }
    
    // MARK: - Function to draw the route on the mapview controller with data from routeview controller
    func routedraw(sender: RouteViewController, selectedTableValue: Int, fromCorrdinate: CLLocationCoordinate2D, toCorrdinate: CLLocationCoordinate2D, allRoutes: [String],from: String, to: String) {
        
        let routesToGo = allRoutes
        routes = routesToGo
        let fromToGo = from
        fromlocation = fromToGo
        let toGo = to
        toLocation = toGo
        let selectedValue = selectedTableValue
        selectedIndex = selectedValue
        
        
        let request = MKDirections.Request()
        let fromPlacemark = MKPlacemark(coordinate: fromCorrdinate )
        let toPlacemark = MKPlacemark(coordinate: toCorrdinate )
        request.source = MKMapItem(placemark: fromPlacemark)
        request.destination = MKMapItem(placemark: toPlacemark)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        // MARK: - Removing overlays if any existed for annotations and maps
        
        let overlays = self.mapView.overlays
        mapView.removeOverlays(overlays)
        let allAnnotations = self.mapView.annotations
        self.mapView.removeAnnotations(allAnnotations)
        
        let directions = MKDirections(request: request)
        directions.calculate(completionHandler: { [self] (response, error) in
            if let err = error
            {
               // print("[ERROR] " + err.localizedDescription)
                
                let alertController = UIAlertController(title: "Error", message: "No directions Available please try again", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
                alertController.addAction(okAction)
                present(alertController,animated: true)
                
                return
            }
            
            if let routes = response?.routes[selectedTableValue]
            {
                
                print("selected route : \(routes.name)")
                print("Table index value : \(selectedTableValue)")
                
                self.mapView.addOverlay(routes.polyline,level:MKOverlayLevel.aboveRoads)
                self.mapView.setVisibleMapRect(routes.polyline.boundingMapRect, animated:true)
            }
        })
        
        if (locationManager.location?.coordinate.latitude == fromCorrdinate.latitude)
        
        {
            print("Annotation not needed as location is current location")
            
            let anot = MKPointAnnotation()
            anot.coordinate = toCorrdinate
            anot.title = to
            mapView.addAnnotation(anot)
            
      //      print("All passed Routes \(allRoutes)")
        }
        
        else
        
        {
            print("Annotation Required as current location is different")
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = fromCorrdinate
            annotation.title = from
            mapView.addAnnotation(annotation)
            
            let toAnnotation = MKPointAnnotation()
            toAnnotation.coordinate = toCorrdinate
            toAnnotation.title = to
            mapView.addAnnotation(toAnnotation)
            
            locationManager.stopUpdatingLocation()
            mapView.showsUserLocation = false
            
        }
        
    }
    
    // MARK: - will get your current location
    func getMyCurrrentLocation() {
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let finlocation:CLLocation = locations[0] as CLLocation
        let center = CLLocationCoordinate2D(latitude: finlocation.coordinate.latitude, longitude: finlocation.coordinate.longitude)
        let mRegion = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        mapView.setRegion(mRegion, animated: true)
        mapView.showsUserLocation = true
        
    }
    
    // MARK: - Used to send data to another controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Mark : Preparing to Send Current Location of User
        
        if segue.identifier == "MainToRoute"
        {
            if let vc = segue.destination as? RouteViewController
            {
                // passing data to RouteViewController
                
                vc.delegate = self
                vc.locationData = locationManager
                vc.manageRoutes = routes
                vc.fromlocation = fromlocation
                vc.toLocation = toLocation
                vc.selectedIndex = selectedIndex
                
                
                
            }
        }
        
        
    }
    
    
    // MARK: - Used to draw map overlay
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer
    {
        // if overlay is polyline, return MKPolylineRenderer
        if let polyline = overlay as? MKPolyline
        {
            let renderer = MKPolylineRenderer(polyline:polyline)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 2
            return renderer
        }
        //routeView(fromCorrdinate: newlocationFromPlacemark, toCorrdinate: newFromLocationPlacemark)
        
        // otherwise, overlay renderer
        return MKOverlayRenderer(overlay:overlay)
    }
    
    
    ///MARK: -BONUSES
    
    // MARK: - Used to switch Map Type
    @IBAction func segmentControlChange (sender: UISegmentedControl!) {
        
        if (sender.selectedSegmentIndex == 0 )
        {
            mapView.mapType = MKMapType.standard
        }
        
        else if (sender.selectedSegmentIndex == 1)
        {
            mapView.mapType = MKMapType.satellite
        }
        else if (sender.selectedSegmentIndex == 2)
        {
            mapView.mapType = MKMapType.hybrid
        }
    }
    
    
    
    
    // MARK: - Used to show compass on top right of the map
    func showCompass()
    {
        mapView.showsCompass = false
        let compassButton = MKCompassButton(mapView: mapView)
        compassButton.compassVisibility = .visible
        mapView.addSubview(compassButton)
        compassButton.translatesAutoresizingMaskIntoConstraints = false
        compassButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -1).isActive = true
        compassButton.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 12).isActive = true
    }
    
    // MARK: - Used to show trackbutton on top right of the map
    func mapTrackButton(){
        let trackButton = MKUserTrackingButton(mapView: mapView)
        mapView.addSubview(trackButton)
        trackButton.translatesAutoresizingMaskIntoConstraints = false
        trackButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: 1).isActive = true
        trackButton.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 50).isActive = true
        
    }
    
    // MARK: - Used to show scale on top left of the map
    func showScale() {
        let scale = MKScaleView(mapView: mapView)
        scale.frame = CGRect(origin: CGPoint(x:0, y: 0), size: CGSize(width: 200, height: 35))
        mapView.addSubview(scale)
    }
    
    
}

