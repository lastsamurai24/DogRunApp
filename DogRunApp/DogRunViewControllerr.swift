//
//  ViewController.swift
//  DogRunApp
//
//  Created by 待寺翼 on 2023/09/13.
//

import MapKit
import CoreLocation

class DogRunViewController: UIViewController, CLLocationManagerDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    let locationManager = CLLocationManager()
    var selectedPlace: MKMapItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // デリゲートを設定
        locationManager.delegate = self
        
        // 位置情報の許可を求める
        locationManager.requestWhenInUseAuthorization()
        
        mapView.showsUserLocation = true
        searchBar.delegate = self
        
        mapView.delegate = self // MKMapViewのデリゲートを設定
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        tableView.keyboardDismissMode = .onDrag
    }
    @objc func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation as? MKPointAnnotation {
            // 選択された施設の情報を取得
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = annotation.title
            request.region = mapView.region
            
            let search = MKLocalSearch(request: request)
            search.start { (response, error) in
                guard let response = response, let item = response.mapItems.first else {
                    print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self.selectedPlace = item
                self.tableView.reloadData() // テーブルビューを更新
            }
        }
    }
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedPlace != nil ? 1 : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if let place = selectedPlace {
            cell.textLabel?.text = place.name
            cell.detailTextLabel?.text = place.phoneNumber
        }
        return cell
    }
    

    // 位置情報の許可ステータスが変更されたときの処理
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            break
        case .restricted, .denied:
            // 位置情報の許可が拒否された場合の処理
            break
        case .authorizedWhenInUse, .authorizedAlways:
            // 位置情報の許可が得られた場合、位置情報の取得を開始
            if CLLocationManager.locationServicesEnabled() {
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.startUpdatingLocation()
            }
        @unknown default:
            // 未知の許可ステータスの場合の処理
            break
        }
    }
    // UISearchBarの検索ボタンがクリックされたときの処理
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text, !searchText.isEmpty else { return }
        
        // 検索テキストを使用して施設を検索
        searchDogRun(with: searchText)
    }
    
    // 指定されたテキストでドッグラン施設を検索する関数
    func searchDogRun(with query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            guard let response = response else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            self.mapView.removeAnnotations(self.mapView.annotations)
            
            // 検索結果をマップ上にピンとして表示
            for item in response.mapItems {
                let annotation = MKPointAnnotation()
                annotation.coordinate = item.placemark.coordinate
                annotation.title = item.name
                annotation.subtitle = item.phoneNumber
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    // 現在地の更新
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let userLocation = locations.last {
            let viewRegion = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
            mapView.setRegion(viewRegion, animated: true)
            
            // 現在地の近くのドッグラン施設を検索
            searchDogRunNearby(location: userLocation)
        }
    }
    
    // 現在地の近くのドッグラン施設を検索する関数
    func searchDogRunNearby(location: CLLocation) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "ドッグラン"
        request.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            guard let response = response else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            for item in response.mapItems {
                let annotation = MKPointAnnotation()
                annotation.coordinate = item.placemark.coordinate
                annotation.title = item.name
                annotation.subtitle = item.phoneNumber
                self.mapView.addAnnotation(annotation)
            }
            
        }
        
            }
            
        }
        
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */

