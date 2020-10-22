//
//  RouteViewController.swift
//  Assignment1
//
//  Created by Sherwin Gonsalves on 2020-10-19.
//

import UIKit
import CoreLocation
import MapKit


protocol RouteViewContDelegate : AnyObject {
    
    func routedraw(sender: RouteViewController ,selectedTableValue: Int , fromCorrdinate: CLLocationCoordinate2D , toCorrdinate: CLLocationCoordinate2D,allRoutes: [ String] , from: String , to: String)
    
}

class RouteViewController: UIViewController, CLLocationManagerDelegate , MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet var myTableView : UITableView!
    @IBOutlet var FromLocation : UITextField!
    @IBOutlet var ToLocation : UITextField!
    @IBOutlet var RoutesButton : UIButton!
    
    weak var delegate : RouteViewContDelegate?
    var globaltoLocation = CLLocation()
    var globalFromLocation = CLLocation()
    var locationData = CLLocationManager()
    var fromlocation : String = ""
    var toLocation : String = ""
    var selectedIndex : Int = 0
    var manageRoutes = [""]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        myTableView.delegate = self
        myTableView.dataSource = self
        
        // MARK: - if user come backs to route view controller after going to map view controller will display previous routes and locations
        if fromlocation.isEmpty
        {
            FromLocation.text = "Current Location"
            
        }
        else if self.manageRoutes.count > 0
        {
            FromLocation.text = fromlocation
            ToLocation.text = toLocation
            myTableView.reloadData()
            let indexPath = IndexPath(row:selectedIndex, section:0)
            myTableView.selectRow(at:indexPath, animated:true,scrollPosition:UITableView.ScrollPosition.none)
            convertToAddress()
        }
        

        
    }
    
    
    // MARK: - When route button is pressed will do error handling as well as calling the route fucntin
    @IBAction func routePressed(_sender: Any)
    {
        
        if ((ToLocation.text == "") && (FromLocation.text == ""))
        
        {
            let alertController = UIAlertController(title: "Error", message: "Please do not leave From Location and To Location blank", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
            alertController.addAction(okAction)
            present(alertController,animated: true)

        }
        else if (ToLocation.text == "")
        {
            let alertController = UIAlertController(title: "Error", message: "Please do not leave To Location blank", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
            alertController.addAction(okAction)
            present(alertController,animated: true)

        }
        else if(FromLocation.text == "")
        {
            let alertController = UIAlertController(title: "Error", message: "Please do not leave From Location blank", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
            alertController.addAction(okAction)
            present(alertController,animated: true)

        }
        
        else if (ToLocation.text) != nil
        
        {
            convertToAddress()
            
        }
        
    }
    
    
    // MARK: - function used to convert text field to geo address/coordinate
    func convertToAddress(){
        
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(ToLocation.text ?? ""){
            [self](placemarks,error)
            in guard let placemarks = placemarks,
                     
                     let location = placemarks.first?.location
            else
            {
                
                let alertController = UIAlertController(title: "Error", message: "To location cannot be found", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
                alertController.addAction(okAction)
                present(alertController,animated: true)
                
                return
                
            }
        
        if FromLocation.text == "Current Location"
        {
            let geocoder = CLGeocoder()
            if let fromlocation = locationData.location {
                geocoder.reverseGeocodeLocation((fromlocation), completionHandler:{(placemarks, error) in
                // do nothing if error occurs
                if let error = error
                {
                    let alertController = UIAlertController(title: "Error", message: "From location cannot be found", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
                    alertController.addAction(okAction)
                    present(alertController,animated: true)
                    //  print("[ERROR] " + error.localizedDescription)
                    return
                }
                // found addresses, extract the first one
                if let placemark = placemarks?[0]
                {
                    print("Name: " + (placemark.name ?? ""))
                    
                    print("To : \(ToLocation.text ?? "nil")")
                    if let locationFrom = placemark.location
                    {
                        self.route(from:locationFrom, to: location)
                        globaltoLocation = location
                        globalFromLocation = locationFrom
                    }
                    
                    
                  
                }
                
            })
            }
        }
        else if FromLocation.text != "Current Location"
        {
            
            geocoder.geocodeAddressString(self.FromLocation.text ?? "nil",completionHandler:{(placemarks, error) in
                // do nothing if error occurs
                if let error = error
                {
                    let alertController = UIAlertController(title: "Error", message: "From location cannot be found", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
                    alertController.addAction(okAction)
                    present(alertController,animated: true)
                    //print("[ERROR] " + error.localizedDescription)
                    return
                }
                // found locations, go to the first location
                if let placemark = placemarks?[0],
                   let fromlocation = placemark.location
                {
                    print(fromlocation.coordinate)
                    print("Name: " + (placemark.name ?? ""))
                    print("To : \(ToLocation.text ?? "nil")")
                    
                    if let locationFrom = placemark.location
                    {
                        self.route(from: fromlocation, to: location)
                        globaltoLocation = location
                        globalFromLocation = locationFrom
                    }
                    
           
                }
                
            })
            
            
        }
        
        
        }
        
        
        
    }
    
    
    // MARK: - fucntion will generate the routes based of the from and to location
    func route(from: CLLocation, to: CLLocation)
    {
        
        let request = MKDirections.Request()
        let fromPlacemark = MKPlacemark(coordinate: from.coordinate)
        let toPlacemark = MKPlacemark(coordinate: to.coordinate)
        request.source = MKMapItem(placemark: fromPlacemark)
        request.destination = MKMapItem(placemark: toPlacemark)
        request.requestsAlternateRoutes = true
        request.transportType = .automobile
        
        
        let directions = MKDirections(request: request)
        directions.calculate(completionHandler: { [self] (response, error) in
            if let error = error
            {

                    let alertController = UIAlertController(title: "Error", message: "No Routes available", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "ok", style: .cancel) { (result : UIAlertAction) -> Void in
                        manageRoutes.removeAll()
                        myTableView.reloadData()
                        }

                    alertController.addAction(okAction)
                    present(alertController,animated: true)
   
            }
            
            if let routes = response?.routes
            {
                self.manageRoutes.removeAll()
                for route in routes
                {

                    //Testing Necessary Outputs
                    print("Name: " + route.name)
                    print("Distance: \(route.distance)")
                    print("Expected Travel Time: \(route.expectedTravelTime)")
                    
                    //Mark - Convertiing the Distance to Km
                    let distanceInKm = (route.distance/1000)
                    let distancFormatted = String(format: "%.2f",distanceInKm )
                    
                    //Mark - assigning Function to variable to convert Secods to HH:MM:SS
                    
                    let totalTravelTime = (self.secondsTohrMMSS(seconds: Int(route.expectedTravelTime)))

                    //Mark - Updating The array manage routes with the new data so it can load the new rputes
                    
                    self.manageRoutes.append("via " + route.name + ": \(distancFormatted) Km" + ", \(totalTravelTime)"  )
                    
                    
                }
                
                
                self.myTableView.reloadData()
            }
            
            
        }
        
        )
        
    }
    
    
    // MARK: - Fucntion that are used to load the table with data
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      
        return manageRoutes.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedlocation = manageRoutes[indexPath.row]
        let tabelCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let selectedValue = indexPath.row
        
        //Testing Necessary Outputs
        print( "Selected Route \(selectedlocation)")
        print("Location From :\(String(describing: FromLocation.text))")
        print("Selected Index value \(selectedValue)")
        
        self.delegate?.routedraw(sender: self ,
                                 selectedTableValue: selectedValue,
                                 fromCorrdinate: globalFromLocation.coordinate,
                                 toCorrdinate: globaltoLocation.coordinate,
                                 allRoutes: manageRoutes ,
                                 from: FromLocation.text ?? "" ,
                                 to: ToLocation.text ?? "" )
        
        self.navigationController?.popViewController(animated: true)
        
        
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let tabelCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let index = indexPath.row
        
        tabelCell.textLabel?.text = manageRoutes[index] 
        
        return tabelCell
    }
    
    
}


extension RouteViewController
{
    
    // MARK: - function is used to cnvert seconds t0 HH:MM:SS
    
    func secondsTohrMMSS(seconds: Int) ->  (String){
        
        let hh = seconds/3600
        
        let mm = ((seconds/60)%60)
        
        let ss = ((seconds)%60)
        
        //return "\(hh):\(mm):\(ss)"
        return String(format: "%02d:%02d:%02d", hh, mm, ss)
        
    }
    
}
