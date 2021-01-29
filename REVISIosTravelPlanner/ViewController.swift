//Trying out route creation
//  ContentView.swift
//  REVISIosTravelPlanner
//
//  Created by Taofeek Akinosho on 11/05/2020.
//  Copyright © 2020 Taofeek Akinosho. All rights reserved.
//
import SwiftUI
import Mapbox
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import GooglePlaces
class ViewController: UIViewController,MGLMapViewDelegate {
    var mapView: NavigationMapView!
    var drivingRoutes, cyclingRoutes, walkingRoutes: [Route]!
    var navigateButton, emissionButton: UIButton!
    var startTextField, destinationTextField: UITextField!
    var drivingButton, cyclingButton, walkingButton: UIButton!
    var currentRoute: Route? {
        get {
            return routes?.first
        }
        set {
            guard let selected = newValue else { routes?.remove(at: 0); return }
            guard let routes = routes else { self.routes = [selected]; return }
            self.routes = [selected] + routes.filter { $0 != selected }
        }
    }
    var routes: [Route]? {
        didSet {
            guard let routes = routes, let current = routes.first else { mapView?.removeRoutes(); return }
            mapView?.showRoutes(routes)
            mapView?.showWaypoints(current)
        }
    }
    var originCoordinate,destinationCoordinate : CLLocationCoordinate2D!
    let navigationDisabledImage = UIImage(named: "disabled.png")
    let navigationEnabledImage = UIImage(named: "go.png")
    let emissionEnabledImage = UIImage(named: "green_emission.png")
    let emissionDisabledImage = UIImage(named: "red_emission.png")
    var routeOptions: NavigationRouteOptions!
    let startIcon = UIImage(named: "start")
    let destinationIcon = UIImage(named: "end")
    let originAnnotation = MGLPointAnnotation()
    var destinationAnnotation = MGLPointAnnotation()
    //just for demonstration. counts the number of times route change was clicked  and sets  the AQI based on the count
    var firstRoute: Route!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView = NavigationMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)
        mapView.delegate = self
        mapView.navigationMapViewDelegate = self
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(.follow, animated: true, completionHandler: nil)
        mapView.trafficHeavyColor =  UIColor(red: 0.9995597005, green: 0, blue: 0, alpha: 1)
        mapView.trafficLowColor = UIColor(red: 0.4275, green: 0.6471, blue: 0.4353, alpha: 1.0)
        mapView.trafficModerateColor =  UIColor(red: 1, green: 0.6184511781, blue: 0, alpha: 1)
        mapView.trafficSevereColor =  UIColor(red: 0.7458544374, green: 0.0006075350102, blue: 0, alpha: 1)
        mapView.trafficUnknownColor = UIColor(red: 0.4275, green: 0.6471, blue: 0.4353, alpha: 1.0)
        addUIButtons()
        addUITextFields()
    }
    func addUIButtons() {
        drivingButton = UIButton(frame: CGRect(x: view.frame.width - 370, y: view.frame.height - 130, width: 100, height: 50))
        cyclingButton = UIButton(frame: CGRect(x: view.frame.width - 250, y: view.frame.height - 130, width: 100, height: 50))
        walkingButton = UIButton(frame: CGRect(x: view.frame.width - 130, y: view.frame.height - 130, width: 100, height: 50))
        //cyclingButton.backgroundColor = UIColor(red: 0.8627, green: 0.5294, blue: 0.2627, alpha: 1.0)
        setButtonAttributes(button: drivingButton, title: "Driving")
        setButtonAttributes(button: cyclingButton, title: "Cycling")
        setButtonAttributes(button: walkingButton, title: "Walking")
        navigateButton = UIButton(frame: CGRect(x: view.frame.width - 70, y: view.frame.height - 245, width: 60, height: 60))
        emissionButton = UIButton(frame: CGRect(x: view.frame.width - 70, y: view.frame.height - 345, width: 60, height: 60))
        navigateButton.setBackgroundImage(navigationDisabledImage, for: .disabled)
        navigateButton.setBackgroundImage(navigationEnabledImage, for: .normal)
        emissionButton.setBackgroundImage(emissionEnabledImage, for: .selected)
        emissionButton.setBackgroundImage(emissionDisabledImage, for: .normal)
        navigateButton.isEnabled = false
        emissionButton.isSelected = true
        //navigateButton.setTitle("NAVIGATE", for: .normal)
        //navigateButton.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 18)
        navigateButton.layer.shadowOffset = CGSize(width: 0, height: 10)
        navigateButton.layer.shadowColor = UIColor.black.cgColor
        navigateButton.layer.shadowRadius = 5
        navigateButton.layer.shadowOpacity = 0.3
        navigateButton.addTarget(self, action: #selector(navigateButtonWasPressed(sender:)), for: .touchUpInside)
        emissionButton.addTarget(self, action: #selector(emissionButtonWasPressed(sender:)), for: .touchUpInside)
        view.addSubview(navigateButton)
        view.addSubview(emissionButton)
        view.addSubview(drivingButton)
        view.addSubview(cyclingButton)
        view.addSubview(walkingButton)
    }
    func addUITextFields() {
        startTextField =  UITextField(frame: CGRect(x: 40, y: 100, width: view.frame.width - 70, height: 40))
        destinationTextField =  UITextField(frame: CGRect(x: 40, y: 150, width: view.frame.width - 70, height: 40))
        setTextFieldAttributes(textField: startTextField, placeholder: "Your location", img: startIcon!)
        setTextFieldAttributes(textField: destinationTextField, placeholder: "Search Destination", img: destinationIcon!)
        startTextField.text = "Your location"
        startTextField.tag = 1
        destinationTextField.tag = 2
        view.addSubview(startTextField)
        view.addSubview(destinationTextField)
    }
    func setButtonAttributes(button: UIButton, title: String){
        button.backgroundColor = UIColor(red: 0.8667, green: 0.8667, blue: 0.8667, alpha: 1.0)
        button.setTitleColor(UIColor(red: 0.20, green: 0.29, blue: 0.36, alpha: 1.00), for: .normal)
        button.setTitleColor(.white,for: .selected)
        button.layer.cornerRadius = 15
        button.layer.borderColor = UIColor(red: 0.20, green: 0.29, blue: 0.36, alpha: 1.00).cgColor
        button.layer.borderWidth = 1.0
        button.isEnabled = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        if(title == "Driving"){
            button.setImage(UIImage(named: "car"), for: .normal)
        }
        else if(title == "Cycling"){
            button.setImage(UIImage(named: "cycling"), for: .normal)
        }
        else{
            button.setImage(UIImage(named: "walking"), for: .normal)
        }
        button.addTarget(self, action: #selector(profileButtonWasPressed(sender:)), for: .touchUpInside)
    }
    func setTextFieldAttributes(textField: UITextField, placeholder: String, img: UIImage){
        textField.placeholder = placeholder
        textField.font = UIFont.systemFont(ofSize: 15)
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        textField.autocorrectionType = UITextAutocorrectionType.no
        textField.keyboardType = UIKeyboardType.default
        textField.returnKeyType = UIReturnKeyType.done
        textField.clearButtonMode = UITextField.ViewMode.whileEditing
        textField.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        addLeftImage(textField: textField, andImage: img)
        textField.addTarget(self, action: #selector(autocompleteClicked(sender:)), for: .touchDown)
    }
    func addLeftImage(textField: UITextField, andImage img: UIImage){
        let leftImageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: img.size.width, height: img.size.height))
        leftImageView.image =  img
        textField.leftView = leftImageView
        textField.leftViewMode = .always
    }
    func plotRoutesOnMap(profile: String, routes: [Route]){
        
        self.routes = routes
        self.currentRoute = routes.first
        //demonstration
        self.firstRoute = routes.first
        if(!mapView.selectedAnnotations.isEmpty){
            mapView.deselectAnnotation(destinationAnnotation, animated: false)
        }
        
        self.destinationAnnotation.title = getRouteDistance(route: self.currentRoute!)
        self.destinationAnnotation.coordinate = self.destinationCoordinate
        //self.destinationAnnotation.subtitle = getRouteDuration(route: self.currentRoute!)
        
        self.destinationAnnotation.subtitle = "CO2: 10 of 40μg/m3"
        //mapView.addAnnotation(destinationAnnotation)
        mapView.selectAnnotation(destinationAnnotation, animated: false, completionHandler: nil)
        
        let coordinateBounds = MGLCoordinateBounds(sw: self.destinationCoordinate, ne: self.originCoordinate)
        let insets = UIEdgeInsets(top: 150, left: 50, bottom: 150, right: 50)
        let routeCam = self.mapView.cameraThatFitsCoordinateBounds(coordinateBounds, edgePadding: insets)
        self.mapView.setCamera(routeCam, animated: true)
    }
    @objc func autocompleteClicked( sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        if(sender.tag == 1){
            autocompleteController.view.tag = 1
        }
        else{
            autocompleteController.view.tag = 2
        }
        // Specify the place data types to return.
        let fields: GMSPlaceField =         GMSPlaceField(rawValue:UInt(GMSPlaceField.name.rawValue) |
            UInt(GMSPlaceField.placeID.rawValue) |
            UInt(GMSPlaceField.coordinate.rawValue) |
            GMSPlaceField.addressComponents.rawValue |
            GMSPlaceField.formattedAddress.rawValue)!
        autocompleteController.placeFields = fields
        // Specify a filter.
        /**let filter = GMSAutocompleteFilter()
         filter.type = .address
         autocompleteController.autocompleteFilter = filter**/
        // Display the autocomplete view controller.
        present(autocompleteController, animated: true, completion: nil)
    }
    @objc func profileButtonWasPressed( sender: UIButton){
        let buttonProfile = sender.titleLabel?.text
        if(buttonProfile  == "Driving"){
            self.drivingButton.isSelected = true
            self.cyclingButton.isSelected = false
            self.walkingButton.isSelected = false
            plotRoutesOnMap(profile:"Driving", routes: drivingRoutes)
        }
        else if(buttonProfile  == "Cycling"){
            self.drivingButton.isSelected = false
            self.cyclingButton.isSelected = true
            self.walkingButton.isSelected = false
            plotRoutesOnMap(profile:"Cycling",routes: cyclingRoutes)
        }
        else if(buttonProfile  == "Walking"){
            self.drivingButton.isSelected = false
            self.cyclingButton.isSelected = false
            self.walkingButton.isSelected = true
            plotRoutesOnMap(profile:"Walking", routes: walkingRoutes)
        }
    }
    @objc func navigateButtonWasPressed( sender: UIButton){
        let options = NavigationOptions(styles: [CustomDayStyle()])
        let navigationVC = NavigationViewController(for: currentRoute!,routeOptions: self.routeOptions, navigationOptions: options)
        navigationVC.modalPresentationStyle = .fullScreen
        present(navigationVC, animated: true, completion: nil)
        /**let annotation = MGLPointAnnotation()
         annotation.coordinate = destinationCoordinate
         annotation.title = "Start Navigation"
         mapView.addAnnotation(annotation)**/
    }
    @objc func emissionButtonWasPressed( sender: UIButton){
        if(self.emissionButton.isSelected){
            self.emissionButton.isSelected = false
        }
        else{
            self.emissionButton.isSelected = true
        }
        if(originCoordinate != nil && destinationCoordinate != nil){
            launchRouteGenerator(from: originCoordinate, to: destinationCoordinate)
        }
    }
    func calculateRoute(from originCoor: CLLocationCoordinate2D, to destinationCoor: CLLocationCoordinate2D, profile: MBDirectionsProfileIdentifier, completion: @escaping (Route?, Error?) -> Void) {
        let origin = Waypoint(coordinate: originCoor, coordinateAccuracy: -1, name: "Start")
        let destination = Waypoint(coordinate: destinationCoor, coordinateAccuracy: -1, name: "Finish")
        let options = NavigationRouteOptions(waypoints: [origin, destination], profileIdentifier: profile)
        options.attributeOptions = [.congestionLevel]
        options.includesSteps = true
        self.routeOptions = options
        let emissionEnabled = self.emissionButton.isSelected
        var congestionLevels = [CongestionLevel]()
        //ERProgressHud.sharedInstance.showBlurView(withTitle: "Getting Routes...")
        Directions.shared.calculate(routeOptions) { [weak self] (session, result)  in
        switch result {
        case .failure(let error):
            print(error.localizedDescription)
        case .success(let response):
            //guard let route = response.routes?.first, let strongSelf = self else {
             //   return
            //}
            if(response.routes?.count != 0){
                if(emissionEnabled){
                    
                    for route in response.routes!{
                        let congestionCount = route.legs[0].segmentCongestionLevels?.count
                        congestionLevels.removeAll()
                        for i in 0..<congestionCount!{
                            let congestion = route.legs[0].segmentCongestionLevels![i]
                            if(i < 20 || congestionCount!/2 ... (congestionCount!/2)+40 ~= i || congestionCount!/3 ... (congestionCount!/3)+40 ~= i){
                                congestionLevels.append(CongestionLevel.moderate)
                            }
                            else if(congestion == CongestionLevel.severe || congestion == CongestionLevel.heavy || congestion == CongestionLevel.low || congestion == CongestionLevel.moderate){
                                congestionLevels.append(CongestionLevel.unknown)
                            }
                            else{
                                congestionLevels.append(congestion)
                            }
                        }
                        route.legs[0].segmentCongestionLevels = congestionLevels
                    }
                }
                
                if(profile == .automobileAvoidingTraffic){
                    self!.drivingRoutes = response.routes
                    self!.drivingButton.isEnabled = true
                    self!.drivingButton.isSelected = true
                    self!.drivingButton.backgroundColor = UIColor(red: 0.86, green: 0.53, blue: 0.26, alpha: 1.00)
                    self!.plotRoutesOnMap(profile:"Driving", routes: self!.drivingRoutes)
                }
                else if(profile == .cycling){
                    self!.cyclingRoutes = response.routes
                    self!.cyclingButton.isEnabled = true
                    self!.cyclingButton.backgroundColor = UIColor(red: 0.86, green: 0.53, blue: 0.26, alpha: 1.00)
                }
                else{
                    self!.walkingRoutes = response.routes
                    self!.walkingButton.isEnabled = true
                    self!.walkingButton.backgroundColor = UIColor(red: 0.86, green: 0.53, blue: 0.26, alpha: 1.00)
                }
            }
            }
        
        /**_ = Directions.shared.calculate(options, completionHandler: { (waypoints, routes, error) in
            if(routes?.count != 0){
                if(profile == .automobileAvoidingTraffic){
                    self.drivingRoutes = routes
                    self.drivingButton.isEnabled = true
                    self.drivingButton.isSelected = true
                    self.drivingButton.backgroundColor = UIColor(red: 0.86, green: 0.53, blue: 0.26, alpha: 1.00)
                    self.plotRoutesOnMap(profile:"Driving", routes: self.drivingRoutes)
                }
                else if(profile == .cycling){
                    self.cyclingRoutes = routes
                    self.cyclingButton.isEnabled = true
                    self.cyclingButton.backgroundColor = UIColor(red: 0.86, green: 0.53, blue: 0.26, alpha: 1.00)
                }
                else{
                    self.walkingRoutes = routes
                    self.walkingButton.isEnabled = true
                    self.walkingButton.backgroundColor = UIColor(red: 0.86, green: 0.53, blue: 0.26, alpha: 1.00)
                }
            }
        })**/
        //ERProgressHud.sharedInstance.hide()
        }
    }
    func launchRouteGenerator(from originCoor: CLLocationCoordinate2D, to destinationCoor: CLLocationCoordinate2D){
        
        ERProgressHud.sharedInstance.showBlurView(withTitle: "Getting Routes...")
        
        self.calculateRoute(from: (originCoor), to: destinationCoor, profile: .automobileAvoidingTraffic) { (route, error) in
            if error != nil {
                print("Error getting route")
            }
        }
        self.calculateRoute(from: (originCoor), to: destinationCoor, profile: .cycling) { (route, error) in
            if error != nil {
                print("Error getting route")
            }
        }
        self.calculateRoute(from: (originCoor), to: destinationCoor, profile: .walking) { (route, error) in
            if error != nil {
                print("Error getting route")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            ERProgressHud.sharedInstance.hide()
        }
        
    }
    func drawRoute(routes: [Route]) {
        destinationAnnotation.coordinate = destinationCoordinate
        originAnnotation.coordinate = originCoordinate
        mapView.addAnnotation(destinationAnnotation)
        //mapView.addAnnotation(originAnnotation)
        /**for route in routes {
         print(route)
         guard route.coordinateCount > 0 else {return}
         var routeCoordinates = route.coordinates!
         let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)
         if let source = mapView.style?.source(withIdentifier: "route-source") as? MGLShapeSource{
         source.shape = polyline
         }
         else {
         let source = MGLShapeSource(identifier: "route-source", features: [polyline], options: nil)
         let lineStyle = MGLLineStyleLayer(identifier: "route-style", source: source)
         lineStyle.lineColor = NSExpression(forConstantValue: UIColor(red: 0.4275, green: 0.6471, blue: 0.4353, alpha: 1.0))
         lineStyle.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'exponential', 1.5, %@)", [14: 6, 18: 20])
         mapView.style?.addSource(source)
         mapView.style?.addLayer(lineStyle)
         }
         }**/
        //self.mapView.showRoutes(routes)
    }
    func getRouteDuration(route: Route)-> String{
        let routeDuration = route.expectedTravelTime.stringFromTimeInterval()
        return routeDuration
    }
    func getRouteDistance(route: Route)-> String{
        let routeDistance = String(format:"%.2f", route.distance/1609) + " mi\n"
        return routeDistance
    }
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    func mapView(_ mapView: MGLMapView, tapOnCalloutFor annotation: MGLAnnotation) {
        /**let navigationVC = NavigationViewController(for: currentRoute!)
         present(navigationVC, animated: true, completion: nil)**/
    }
    func mapView(_ mapView: MGLMapView, leftCalloutAccessoryViewFor annotation: MGLAnnotation) -> UIView? {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 50))
        //label.textColor = UIColor(red: 0.81, green: 0.71, blue: 0.23, alpha: 1)
        label.font = label.font.withSize(13)
        if(self.currentRoute ==  self.firstRoute){
            label.textColor = UIColor(red: 0.4275, green: 0.6471, blue: 0.4353, alpha: 1.0)
            label.text = "AQI Good"
        }
        else{
            label.textColor = UIColor(red: 1.00, green: 0.00, blue: 0.00, alpha: 1.00)
            label.text = "AQI Poor"
        }
        
        
        return label
    }
    func mapView(_ mapView: MGLMapView, rightCalloutAccessoryViewFor annotation: MGLAnnotation) -> UIView? {
        var image: UIImage?
        if (drivingButton.isSelected) {
            // Callout height is fixed; width expands to fit its content.
            image = UIImage(named:"car")
        }
        else if (cyclingButton.isSelected) {
            // Callout height is fixed; width expands to fit its content.
            image = UIImage(named:"cycling")
        }
        else{
            image = UIImage(named:"walking")
        }
        let imageView = UIImageView(image: image!)
        return imageView
    }
}
extension ViewController: NavigationMapViewDelegate {
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        self.currentRoute = route
        self.destinationAnnotation.title = getRouteDistance(route: self.currentRoute!)
        //self.destinationAnnotation.subtitle = getRouteDuration(route: self.currentRoute!)
        if(route == self.firstRoute){
            self.destinationAnnotation.subtitle = "CO2: 10 of 40μg/m3"
        }
        else{
            self.destinationAnnotation.subtitle = "CO2: 30 of 40μg/m3"
        }
        mapView.selectAnnotation(destinationAnnotation, animated: false, completionHandler: nil)
        
    }
}
extension ViewController: GMSAutocompleteViewControllerDelegate {
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        if(viewController.view.tag == 1){
            startTextField.text = place.name
            originCoordinate = CLLocationCoordinate2D(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            originAnnotation.coordinate = originCoordinate
            mapView.addAnnotation(originAnnotation)
        }
        else{
            destinationTextField.text = place.name
            print(place.coordinate.longitude)
            print(place.coordinate.latitude)
            destinationCoordinate = CLLocationCoordinate2D(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            navigateButton.isEnabled = true
            mapView.setUserTrackingMode(.none, animated: true, completionHandler: nil)
            if(originCoordinate == nil){
                originCoordinate = mapView.userLocation!.coordinate
            }
        }
        dismiss(animated: true, completion: nil)
        if(originCoordinate != nil && destinationCoordinate != nil){
            launchRouteGenerator(from: originCoordinate, to: destinationCoordinate)
        }
    }
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print(error.localizedDescription)
    }
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
}
extension TimeInterval{
    func stringFromTimeInterval() -> String {
        let time = NSInteger(self)
        _ = Int((self.truncatingRemainder(dividingBy: 1)) * 1000) //ms
        _ = time % 60 //secs
        let minutes = (time / 60) % 60
        let hours = (time / 3600)
        return String(format: "%0.2dhr %0.2d mins",hours,minutes)
    }
}
/**extension CongestionLevel{
 var currentRoute: Route? {
 get {
 return routes?.first
 }
 set {
 guard let selected = newValue else { routes?.remove(at: 0); return }
 guard let routes = routes else { self.routes = [selected]; return }
 self.routes = [selected] + routes.filter { $0 != selected }
 }
 }
 public  var myown: String{
 }
 }**/
class CustomDayStyle: DayStyle {
    required init() {
        super.init()
        // Use a custom map style.
        mapStyleURL = MGLStyle.satelliteStreetsStyleURL
        previewMapStyleURL = MGLStyle.satelliteStreetsStyleURL
        // Specify that the style should be used during the day.
        styleType = .day
    }
    override func apply() {
        super.apply()
        // Begin styling the UI
        //BottomBannerView.appearance().backgroundColor = .orange
        NavigationMapView.appearance().routeCasingColor = UIColor(red: 0.4275, green: 0.6471, blue: 0.4353, alpha: 1.0)
        NavigationMapView.appearance().trafficHeavyColor =  UIColor(red: 0.9995597005, green: 0, blue: 0, alpha: 1)
        NavigationMapView.appearance().trafficLowColor = UIColor(red: 0.4275, green: 0.6471, blue: 0.4353, alpha: 1.0)
        NavigationMapView.appearance().trafficModerateColor =  UIColor(red: 1, green: 0.6184511781, blue: 0, alpha: 1)
        NavigationMapView.appearance().trafficSevereColor =  UIColor(red: 0.7458544374, green: 0.0006075350102, blue: 0, alpha: 1)
        NavigationMapView.appearance().trafficUnknownColor = UIColor(red: 0.4275, green: 0.6471, blue: 0.4353, alpha: 1.0)
    }
}
