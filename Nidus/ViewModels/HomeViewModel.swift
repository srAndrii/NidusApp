// ViewModels/HomeViewModel.swift
import Foundation
import Combine
import CoreLocation

class HomeViewModel: ObservableObject {
    @Published var coffeeShops: [CoffeeShop] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var currentLocation: CLLocationCoordinate2D?
    
    private let coffeeShopRepository: CoffeeShopRepositoryProtocol
    private let locationManager = CLLocationManager()
    
    init(coffeeShopRepository: CoffeeShopRepositoryProtocol) {
        self.coffeeShopRepository = coffeeShopRepository
    }
    
    @MainActor
    func loadCoffeeShops() async {
        isLoading = true
        error = nil
        
        do {
            coffeeShops = try await coffeeShopRepository.getAllCoffeeShops()
            
            // Обчислюємо відстань до кав'ярень, якщо відомо поточне місцезнаходження
            if let userLocation = currentLocation {
                for i in 0..<coffeeShops.count {
                    if let shopLocation = coffeeShops[i].coordinate {
                        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                        let shopCLLocation = CLLocation(latitude: shopLocation.latitude, longitude: shopLocation.longitude)
                        
                        // Відстань у метрах
                        let distance = userCLLocation.distance(from: shopCLLocation)
                        coffeeShops[i].distance = distance
                    }
                }
                
                // Сортуємо за відстанню
                coffeeShops.sort { ($0.distance ?? Double.infinity) < ($1.distance ?? Double.infinity) }
            }
            
        } catch {
            self.error = error
            print("Error loading coffee shops: \(error)")
        }
        
        isLoading = false
    }
    
    func startLocationUpdates() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func updateLocation(coordinate: CLLocationCoordinate2D) {
        self.currentLocation = coordinate
    }
    
    func searchCoffeeShops(query: String) async {
        if query.isEmpty {
            await loadCoffeeShops()
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            coffeeShops = try await coffeeShopRepository.searchCoffeeShops(address: query)
        } catch {
            self.error = error
            print("Error searching coffee shops: \(error)")
        }
        
        isLoading = false
    }
}
