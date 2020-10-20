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

    func routedraw(sender: RouteViewController ,selectedTableValue: Int , fromCorrdinate: CLLocationCoordinate2D , toCorrdinate: CLLocationCoordinate2D,allRoutes: [ String] )
 
}

class RouteViewController: UIViewController, CLLocationManagerDelegate , MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource {
 
    
   
    @IBOutlet var myTableView : UITableView!
    @IBOutlet var FromLocation : UITextField!
    @IBOutlet var ToLocation : UITextField!
    @IBOutlet var RoutesButton : UIButton?
    var manageRoutes = [""]
    weak var delegate : RouteViewContDelegate?
    var globaltoLocation = CLLocation()
    var globalFromLocation = CLLocation()
    var locationData = CLLocationManager()
    var datafromMap = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        FromLocation.text = "Current Location"
        myTableView.delegate = self
        myTableView.dataSource = self


    }
    
    // MARK: - function is used to cnvert seconds t0 HH:MM:SS

    func secondsTohrMMSS(seconds: Int) ->  (String){
            let hh = seconds/3600

            let mm = ((seconds/60)%60)

            let ss = ((seconds)%60)

        return "\(hh):\(mm):\(ss)"
           
        }

    // MARK: - When route button is pressed will do error handling as well as calling the route fucntin
    @IBAction func routePressed(_sender: Any)
    {
        
        if ((ToLocation.text!.isEmpty) && (FromLocation.text!.isEmpty))
        
        {
            let alertController = UIAlertController(title: "Error", message: "Please do not leave FromLocation and ToLocation blank", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController,animated: true)

            
            
        }
        else if (ToLocation.text!.isEmpty)
        {
            
            let alertController = UIAlertController(title: "Error", message: "Please do not leave ToLocation blank", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController,animated: true)
            
            
        }
        else if(FromLocation.text!.isEmpty)
        {
            let alertController = UIAlertController(title: "Error", message: "Please do not leave FromLocation blank", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController,animated: true)
            
            
        }

        else if (ToLocation.text?.isEmpty) != nil
        
        {
            convertToAddress()

        }

    }

    
    // MARK: - function used to convert text field to geo address/coordinate
    func convertToAddress(){
        
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(ToLocation.text!)
        { [self]
            (placemarks,error)
            in guard let placemarks = placemarks,
            
                     let location = placemarks.first?.location
            else
            {
                
                let alertController = UIAlertController(title: "Error", message: "To location cannot be found", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
                alertController.addAction(cancelAction)
                present(alertController,animated: true)
              
                return
                
            }

        if FromLocation.text == "Current Location"
        {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation((locationData.location)!,
                                            completionHandler:{(placemarks, error) in
            // do nothing if error occurs
            if let error = error
            {
                let alertController = UIAlertController(title: "Error", message: "From location cannot be found", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
                alertController.addAction(cancelAction)
                present(alertController,animated: true)
          //  print("[ERROR] " + error.localizedDescription)
            return
            }
            // found addresses, extract the first one
            if let placemark = placemarks?[0]
            {
            print("Name: " + (placemark.name ?? ""))
                print("To : \(ToLocation.text!)")
            self.route(from:placemark.location!, to: location)
                globaltoLocation = location
                globalFromLocation = placemark.location!
            }
                                                
                                                })
        }
        else if FromLocation.text != "Current Location"
        {

            geocoder.geocodeAddressString(self.FromLocation.text!, completionHandler:{(placemarks, error) in
            // do nothing if error occurs
            if let error = error
            {
                let alertController = UIAlertController(title: "Error", message: "From location cannot be found", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "ok", style: .cancel, handler: nil)
                alertController.addAction(cancelAction)
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
                print("To : \(ToLocation.text!)")
                
                self.route(from: fromlocation, to: location)
                globaltoLocation = location
                globalFromLocation = placemark.location!
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
        directions.calculate(completionHandler:
                                
                                { (response, error) in
            if let error = error
            {
     
                return
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

            print( "Selected Route \(selectedlocation)")
            print("Location From :\(String(describing: FromLocation.text))")
            print("Selected Index value \(selectedValue)")

        self.delegate?.routedraw(sender: self , selectedTableValue: selectedValue, fromCorrdinate: globalFromLocation.coordinate, toCorrdinate: globaltoLocation.coordinate,allRoutes: manageRoutes)
        
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
