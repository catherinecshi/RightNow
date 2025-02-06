import Foundation
import UIKit
import MapKit
import CoreLocation

class LocationAccountabilityViewController: UIViewController, UISearchResultsUpdating, UISearchControllerDelegate, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate {
    var habitData = HabitData()
    var mapView = MKMapView()
    
    // search and table view
    var searchLocation = UISearchController(searchResultsController: nil)
    var searchTable = UITableView()
    var matchingItems: [MKMapItem] = [] // hold search results
    
    //initiate labels
    let viewTitle: UILabel = {
        let label = UILabel()
        label.text = "Create Habit"
        label.font = UIConfiguration.titleFont
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    let whatLabel: UILabel = {
        let label = UILabel()
        label.text = "Where do you want to track?"
        label.font = UIConfiguration.subtitleFont
        label.textColor = .white
        //label.textAlignment = .center
        return label
    }()
    
    //button to go to the next step
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.isEnabled = false //button is disabled until a habit is selected
        return button
    }()
    
    private var locationAuthorizationStatus: CLAuthorizationStatus {
        return LocationManager.shared.authorizationStatus
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIConfiguration.tintColor
        view.clipsToBounds = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLocationAuthorizationChange),
            name: .locationAuthorizationDidChange,
            object: nil
        )
        
        setupTitle()
        setupWhatSubtitle()
        setupNextButton()
        setupMap()
        setupSearch()
        setupSearchTable()
        
        checkLocationAuthorization()
        addTapGesture()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: UI Setup
    
    private func setupTitle() {
        view.addSubview(viewTitle)
        viewTitle.translatesAutoresizingMaskIntoConstraints = false
        
        //make sure it can go to multiple lines if squished
        viewTitle.numberOfLines = 0 //allows line breaks
        viewTitle.lineBreakMode = .byWordWrapping //breaks lines by words, not characters
        
        self.navigationItem.titleView = viewTitle
    }
    
    private func setupWhatSubtitle() {
        view.addSubview(whatLabel)
        whatLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            whatLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            whatLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            whatLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            whatLabel.heightAnchor.constraint(equalToConstant: 22) // value taken from the natural height
        ])
    }
    
    private func setupMap() {
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: whatLabel.bottomAnchor, constant: 20),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mapView.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -20)
        ])
        
        mapView.layer.cornerRadius = 15
        mapView.layer.borderColor = UIColor.white.cgColor
        mapView.layer.borderWidth = 2
        
        mapView.showsUserLocation = true
        mapView.delegate = self
    }
    
    private func setupSearch() {
        searchLocation.delegate = self
        searchLocation.searchResultsUpdater = self
        searchLocation.hidesNavigationBarDuringPresentation = false
        searchLocation.obscuresBackgroundDuringPresentation = false
        searchLocation.searchBar.placeholder = "Search for a Location"
        
        // i caved and put the search bar in the navigation item
        self.navigationItem.searchController = searchLocation
        self.navigationItem.hidesSearchBarWhenScrolling = false
        
        view.addSubview(searchLocation.searchBar)
        searchLocation.searchBar.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupSearchTable() {
        view.addSubview(searchTable)
        searchTable.translatesAutoresizingMaskIntoConstraints = false
        searchTable.delegate = self
        searchTable.dataSource = self
        
        NSLayoutConstraint.activate([
            searchTable.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchTable.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchTable.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            searchTable.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -20)
        ])
        
        searchTable.register(UITableViewCell.self, forCellReuseIdentifier: "searchResultCell")
        searchTable.isHidden = true // initially hide
    }
    
    private func setupNextButton() {
        //add to view
        view.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 100),
            nextButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30)
        ])
        
        //appearance
        nextButton.backgroundColor = .white
        nextButton.setTitleColor(UIConfiguration.tintColor, for: .normal)
        nextButton.setTitleColor(UIColor.gray, for: .disabled)
        nextButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
        nextButton.layer.cornerRadius = 20
        nextButton.clipsToBounds = true
        
        //add action
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    private func updateMapView() {
        if let currentLocation = LocationManager.shared.requestCurrentLocation() {
            centerMapOnUserLocation(coordinate: currentLocation)
        } else {
            print("Current Location not available")
        }
    }
    
    private func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: Detect Actions
    
    private func updateNextButtonState() {
        //check if habit & day have been selected
        var locationSelected: Bool
        if let location = habitData.location {
            locationSelected = true
        } else {
            locationSelected = false
        }
        
        nextButton.isEnabled = locationSelected
    }
    
    @objc private func handleMapTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let locationInView = gestureRecognizer.location(in: mapView) // tap location
        let coordinate = mapView.convert(locationInView, toCoordinateFrom: mapView)
        
        // add an annotation so the user knows where they tapped
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = habitData.name
        
        mapView.removeAnnotations(mapView.annotations) // only want one at a time
        mapView.addAnnotation(annotation)
        
        mapView.removeOverlays(mapView.overlays)
        let circle = MKCircle(center: coordinate, radius: 100)
        mapView.addOverlay(circle)
        
        // get latitude and longitude and store in habitData
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        
        habitData.location = Location(id: UUID(), name: habitData.name ?? "habit location", latitude: latitude, longitude: longitude)
        print("added location \(habitData.location?.name ?? "no location") at latitude \(latitude) and longitude \(longitude)")
        updateNextButtonState()
    }
    
    @objc private func nextButtonTapped() {
        //create and push the next view controller
        //let incentivesVC = IncentivesViewController()
        let murphyVC = MurphyjitsuViewController()
        
        // back button
        let backButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.backBarButtonItem = backButton
        self.navigationController?.navigationBar.tintColor = .white
        
        // send info forward
        //incentivesVC.habitData = habitData
       // navigationController?.pushViewController(incentivesVC, animated: true)
        murphyVC.habitData = habitData
        navigationController?.pushViewController(murphyVC, animated: true)
    }
    
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func centerMapOnUserLocation(coordinate: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        mapView.setRegion(region, animated: true)
    }
    
    // MARK: Map Functionalities
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circleOverlay = overlay as? MKCircle {
            let circleRenderer = MKCircleRenderer(circle: circleOverlay)
            circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.2)
            circleRenderer.strokeColor = UIColor.blue
            circleRenderer.lineWidth = 1
            return circleRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    // MARK: - Search Functionalities
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = searchText
            
            let search = MKLocalSearch(request: searchRequest)
            search.start { response, error in
                if let error = error as? MKError {
                    switch error.code {
                    case .placemarkNotFound:
                        print("No placemark Found")
                    case .serverFailure:
                        print("Server Failure")
                    case .loadingThrottled:
                        print("Search was throttled")
                    default:
                        print("Other search error: \(error.localizedDescription)")
                    }
                } else if let response = response {
                    print("Display table")
                    self.matchingItems = response.mapItems
                    self.searchTable.isHidden = false
                    self.searchTable.layoutIfNeeded()
                    self.searchTable.reloadData()
                }
            }
        } else {
            matchingItems.removeAll()
            searchTable.isHidden = true
            searchTable.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchResultCell", for: indexPath)
        let selectedItem = matchingItems[indexPath.row].placemark
        cell.textLabel?.text = selectedItem.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = matchingItems[indexPath.row].placemark
        let coordinate = selectedItem.coordinate
        
        centerMapOnUserLocation(coordinate: coordinate)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = habitData.name
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(annotation)
        
        mapView.removeOverlays(mapView.overlays)
        let circle = MKCircle(center: coordinate, radius: 100)
        mapView.addOverlay(circle)
        
        // store location into habitData
        habitData.location = Location(id: UUID(), name: selectedItem.name ?? "Selected Location", latitude: coordinate.latitude, longitude: coordinate.longitude)
        updateNextButtonState()
        
        // hide table after selection
        searchTable.isHidden = true
    }
    
    // MARK: - Locaiton Authorization
    private func checkLocationAuthorization() {
        switch locationAuthorizationStatus {
        case .notDetermined:
            LocationManager.shared.requestAuthorization()
        case .restricted, .denied:
            showLocationPermissionAlert()
        case .authorizedWhenInUse:
            guard !LocationManager.shared.hasShownWhenInUseAlert else {
                print("user has seen shown in use alert already. show map view")
                updateMapView()
                return
            }
            showWhenInUseAlert()
        case .authorizedAlways:
            updateMapView()
        @unknown default:
            print("unknown location authorization")
            break
        }
    }
    
    private func showLocationPermissionAlert() {
        print("user restricted or denied location authorization - locationaccountabilityvc")
         
        let alert = CustomAlertViewController(title: "Location-based Habits need Location Authorization!", 
                                              message: "Do you want to keep tracking your habits based on their locations?",
                                              okButtonTitle: "Yes, how do I change my settings?",
                                              cancelButtonTitle: "No, I don't want to track my habit with my location")
        
        alert.completionOk = { [weak self] in
            print("user indicated they want to change their settings - locationaccountabilityvc")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                let guideAlert = CustomAlertViewController.createLocationSettingsAlert { [weak self] in
                    print("user has indicated that they have changed their settins - locationaccountabilityvc")
                    self?.checkLocationAuthorization()
                }
                
                self?.present(guideAlert, animated: true)
            }
        }
        
        alert.completionCancel = { [weak self] in
            print("user indicated they don't want to track their habits with location - eject them from current view")
            self?.navigationController?.popViewController(animated: true)
        }
        
        self.present(alert, animated: true)
    }
    
    private func showWhenInUseAlert() {
        print("presenting when in use alert - lcoationaccountabilityvc")
        
        LocationManager.shared.hasShownWhenInUseAlert = true
        let alert = CustomAlertViewController(
            title: "Locations Currently Only Authorized During App Use!",
            message: "Your habits will only get tracked if you go on RightNow with each habit, so we can check your location. If you change your authorization to Always Allow, we can check your location without you going on RightNow.",
            okButtonTitle: "How do I switch my authorization status?",
            cancelButtonTitle: "OK, I'll log onto RightNow every time for my location habits to get tracked!")
        
        alert.completionOk = { [weak self] in
            print("user indicated that they want to go from when in use -> always - locationauthorizationvc")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                let guideAlert = CustomAlertViewController.createLocationSettingsAlert { [weak self] in
                    print("user indicated that they have changed their settings from when in use -> always - locationauthorizationvc")
                    self?.checkLocationAuthorization()
                }
                
                self?.present(guideAlert, animated: true)
            }
        }
        
        self.present(alert, animated: true)
    }
    
    @objc private func handleLocationAuthorizationChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.checkLocationAuthorization()
        }
    }
}
