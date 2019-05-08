//
//  ViewController.swift
//  Breweries
//
//  Created by Edvin Lellhame on 3/18/19.
//  Copyright © 2019 Edvin Lellhame. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import GooglePlaces



class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var locationLabel: UILabel!
    
    private let locationManager = CLLocationManager()
    private var locationCoordinate: CLLocationCoordinate2D!
    private var locations = [Location]()
    private var searchedCity = ""
    
    var cachedConstraints: [NSLayoutConstraint] = []
    var isPopupEnabled = false
    var location: Location!
    
    
    
    //MARK: Programmatically Views
    let categoryView: UIView = {
        let view = UIView()
        // rgb(178, 190, 195)
        view.backgroundColor = UIColor(red: 178.0/255.0, green: 190.0/255.0, blue: 195.0/255.0, alpha: 1.0)
        
        return view
    }()
    
    let nameLabel: UILabel = {
       let label = UILabel()
        label.font = UIFont(name: "Avenir Next", size: 18)
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        
        return label
    }()
    
    let locationMapView: MKMapView = {
        let mapView = MKMapView()
        mapView.isScrollEnabled = false
        mapView.isRotateEnabled = false
        return mapView
    }()
    
    let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "close_button"), for: .normal)
        button.contentMode = .scaleAspectFill
        return button
    }()
    
    let phoneButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Phone"), for: .normal)
        button.contentMode = .scaleAspectFill
        return button
    }()
    
    let directionsButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Directions"), for: .normal)
        button.contentMode = .scaleAspectFill
        return button
    }()
    
    let websiteButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Website"), for: .normal)
        button.contentMode = .scaleAspectFill
        return button
    }()
    
    
    
    
   
    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        navigationController?.navigationBar.isHidden = true
        
        updateViewsAndConstraints()
        addButtonTargets()
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        layout.itemSize = CGSize(width: collectionView.bounds.width/3, height: collectionView.bounds.width/3)
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        collectionView.collectionViewLayout = layout
        
        locationManager.requestWhenInUseAuthorization()
      
        var cityString = ""
        
        if let location = locationManager.location {
            reverseGeocode(location: location) { (city, state) in
                guard let city = city, let state = state else { return }
                cityString = "\(city),\(state)"
                
                guard let url = URL(string: "\(Constants.Keys.url)/\(cityString)\(Constants.Keys.json)") else {
                    return
                }
                URLSession.shared.dataTask(with: URLRequest(url: url)) { (data, response, error) in
                    if error != nil {
                        print("error")
                    }
                    
                    guard let data = data else {
                        return
                    }
                    
                    do {
                        guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: AnyObject]] else {
                            return
                            
                        }
                        print(json)
                        
                        for i in json {
                            let place = Location(json: i)
                            DispatchQueue.main.async {
                                self.locationLabel.text = "\(city), \(state)"
                                self.locations.append(place)
                                self.collectionView.reloadData()
                            }
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }.resume()
            }
        }
    }
    @IBAction func textFieldTapped(_ sender: Any) {
        searchTextField.resignFirstResponder()
        let controller = GMSAutocompleteViewController()
        controller.delegate = self
        present(controller, animated: true, completion: nil)
    }
    
    // MARK: Target(s)
    @objc func closeButtonPressed() {
        if isPopupEnabled == false {
            animateView(directionUp: true, withLocation: self.location)
            isPopupEnabled = true
        } else {
            animateView(directionUp: false, withLocation: self.location)
            isPopupEnabled = false
        }
    }
    
    @objc func phoneButtonPressed() {
        let trimmedNumber = self.location.phone!.digits
        print(trimmedNumber)
        guard let number = URL(string: "tel://" + trimmedNumber) else {
            print("ERROR GETTING PHONE")
            return
        }
        
        UIApplication.shared.open(number, options: [:], completionHandler: nil)
    }
    
    @objc func websiteButtonPressed() {
        guard let url = URL(string: "http://www." + self.location.url!) else {
            websiteButton.isHidden = true
            return
            
        }
        UIApplication.shared.open(url)
    }
    
    @objc func directionsButtonPressed() {
        
        let coordinate = CLLocationCoordinate2DMake(self.locationCoordinate.latitude, self.locationCoordinate.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
        guard let name = self.location.name else {
            return
        }
        mapItem.name = name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
    }
    
    @objc func tapGestureCloseCategoryView() {
        animateView(directionUp: false, withLocation: self.location)
    }
    
    //MARK: Method(s)
    private func updateViewsAndConstraints() {
        view.addSubview(categoryView)
        categoryView.addSubview(closeButton)
        categoryView.addSubview(nameLabel)
        categoryView.addSubview(locationMapView)
        categoryView.addSubview(phoneButton)
        categoryView.addSubview(directionsButton)
        categoryView.addSubview(websiteButton)
        
        
        cachedConstraints = categoryView.anchor(top: nil, paddingTop: 0, leading: view.leadingAnchor, paddingLeading: 0, bottom: view.bottomAnchor, paddingBottom: 0, trailing: view.trailingAnchor, paddingTrailing: 0, width: 0, height: 0, withCached: self.cachedConstraints)
        
        closeButton.anchor(top: categoryView.topAnchor, paddingTop: 5, leading: nil, paddingLeading: 0, bottom: nil, paddingBottom: 0, trailing: categoryView.trailingAnchor, paddingTrailing: 5, width: 26, height: 26)
        
        nameLabel.anchor(top: categoryView.topAnchor, paddingTop: 10, leading: categoryView.leadingAnchor, paddingLeading: 5, bottom: nil, paddingBottom: 0, trailing: categoryView.trailingAnchor, paddingTrailing: 5, width: 0, height: 30)
        
        locationMapView.anchor(top: nameLabel.bottomAnchor, paddingTop: 5, leading: categoryView.leadingAnchor, paddingLeading: 0, bottom: nil, paddingBottom: 0, trailing: categoryView.trailingAnchor, paddingTrailing: 0, width: 0, height: 150)
        
        phoneButton.anchor(top: locationMapView.bottomAnchor, paddingTop: 5, leading: categoryView.leadingAnchor, paddingLeading: 5, bottom: nil, paddingBottom: 0, trailing: nil, paddingTrailing: 0, width: 90, height: 33)
        
        websiteButton.anchor(top: locationMapView.bottomAnchor, paddingTop: 5, leading: phoneButton.trailingAnchor, paddingLeading: 45, bottom: nil, paddingBottom: 0, trailing: nil, paddingTrailing: 0, width: 90, height: 33)
        
        directionsButton.anchor(top: locationMapView.bottomAnchor, paddingTop: 5, leading: nil, paddingLeading: 0, bottom: nil, paddingBottom: 0, trailing: categoryView.trailingAnchor, paddingTrailing: 5, width: 90, height: 33)
    }
    
    private func animateView(directionUp: Bool, withLocation location: Location) {
        if directionUp == true {
            // Animates the view up and updates it's labels
            UIView.animate(withDuration: 0.6, animations: {
                self.cachedConstraints = self.categoryView.anchor(top: nil, paddingTop: 0, leading: self.view.leadingAnchor, paddingLeading: 0, bottom: self.view.bottomAnchor, paddingBottom: 0, trailing: self.view.trailingAnchor, paddingTrailing: 0, width: 0, height: 300, withCached: self.cachedConstraints)
                
                let geocoder = CLGeocoder()
                if let street = location.street, let city = location.city, let state = location.state {
                    
                    let address = "\(street) \(city), \(state)"
                    
                    geocoder.geocodeAddressString(address, completionHandler: { (placemark, error) in
                        guard let placemark = placemark else {
                            print("ERROR")
                            return
                        }
                        
                        for i in placemark {
                            self.locationCoordinate = i.location?.coordinate
                        }
                        
                        let viewRegion = MKCoordinateRegion(center: self.locationCoordinate, latitudinalMeters: 200, longitudinalMeters: 200)
                        self.locationMapView.setRegion(viewRegion, animated: false)
                        self.locationMapView.showsUserLocation = true
                       
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = self.locationCoordinate
                        DispatchQueue.main.async {
                            self.locationMapView.addAnnotation(annotation)
                        }
                    })
                }
                
                DispatchQueue.main.async {
                    self.phoneButton.isHidden = false
                    self.websiteButton.isHidden = false
                    
                    if let name = location.name {
                        self.nameLabel.text = name
                    } else {
                        self.nameLabel.text = "Error"
                    }
                    
                    if let website = location.url {
                        print(website)
                    } else {
                        self.websiteButton.setImage(UIImage(named: "WebsiteNull"), for: .normal)
                        self.websiteButton.isEnabled = false
                    }
                    
                    if let phone = location.phone {
                        print(phone)
                        if phone == "" {
                            self.phoneButton.setImage(UIImage(named: "PhoneNull"), for: .normal)
                            self.phoneButton.isEnabled = false
                        }
                    } else {
                        self.phoneButton.setImage(UIImage(named: "PhoneNull"), for: .normal)
                        self.phoneButton.isEnabled = false
                    }
                }
                self.view.layoutIfNeeded()
            })
        } else {
            // Animates the view down and updates it's labels back to empty
            UIView.animate(withDuration: 0.4, animations: {
                self.cachedConstraints = self.categoryView.anchor(top: nil, paddingTop: 0, leading: self.view.leadingAnchor, paddingLeading: 0, bottom: self.view.bottomAnchor, paddingBottom: 0, trailing: self.view.trailingAnchor, paddingTrailing: 0, width: 0, height: 0, withCached: self.cachedConstraints)
                
                self.view.layoutIfNeeded()
            })
            
        }
        // COME BACK TO ADD TAP GESTURE RECOGNIZER**************************
//        for gesture in self.view.gestureRecognizers!
//        {
//            if let recognizer = gesture as? UITapGestureRecognizer {
//                self.view.removeGestureRecognizer(recognizer)
//            }
//        }
    }
    
    private func addButtonTargets() {
        closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
        phoneButton.addTarget(self, action: #selector(phoneButtonPressed), for: .touchUpInside)
        websiteButton.addTarget(self, action: #selector(websiteButtonPressed), for: .touchUpInside)
        directionsButton.addTarget(self, action: #selector(directionsButtonPressed), for: .touchUpInside)
    }

    private func reverseGeocode(location: CLLocation, completion:@escaping (_ city: String?, _ state: String?) -> Void) {
        let geoCoder = CLGeocoder()
        
        geoCoder.reverseGeocodeLocation(location) { (placemark, error) in
            if error != nil {
                completion(nil, nil)
            }
            
            if let city = placemark?.first?.locality, let state = placemark?.first?.administrativeArea {
                
                completion(city, state)
                
            }
        }
    }
    
}


extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return locations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! LocationCell
        
        let location = locations[indexPath.item]
        
        if location.city == nil {
            print("null")
            cell.updateLabelsWithNullBreweries()
        } else {
            cell.updateLabels(location: location)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.location = locations[indexPath.item]
        
        
            if location.city != nil {
                if isPopupEnabled == false {
                    animateView(directionUp: true, withLocation: self.location)
                    isPopupEnabled = true
                }
                
            }
        
        
        
       
    }
    
}

extension ViewController: GMSAutocompleteViewControllerDelegate {
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        locations.removeAll()
        
        guard let originalFormattedAddress = place.formattedAddress else { return }
        print(originalFormattedAddress)
        
        let delimiter = ", "
        let tokens = originalFormattedAddress.components(separatedBy: delimiter)
        
        var finalStr = ""
        for (index,token) in tokens.enumerated() {
            let replace =  token.replacingOccurrences(of: " ", with: "_")
            print("index: \(index)")
            print("tokens.count: \(tokens.count)")
            if index == (tokens.count - 1) {
                print("last index of array.")
                finalStr = finalStr + replace
            } else {
                finalStr = finalStr + replace + ","
            }
            
        }
        
        let endIndex = originalFormattedAddress.index(originalFormattedAddress.endIndex, offsetBy: -5)
        searchedCity = originalFormattedAddress.substring(to: endIndex)
        
        locationLabel.text = searchedCity
        
        guard let url = URL(string: "\(Constants.Keys.url)/\(finalStr)\(Constants.Keys.json)") else {
            return
        }
        
        URLSession.shared.dataTask(with: URLRequest(url: url)) { (data, response, error) in
            if error != nil {
                print("error")
            }
            
            guard let data = data else {
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: AnyObject]]
                for i in json! {
                    let place = Location(json: i)
                    print(i)
                    
                    DispatchQueue.main.async {
                        
                        self.locations.append(place)
                        self.collectionView.reloadData()
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
            }.resume()
        
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error: \(error.localizedDescription)")
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = collectionView.bounds.size.width/3.0 - 2

        return CGSize(width: width, height: width)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
}


