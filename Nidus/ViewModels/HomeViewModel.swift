// ViewModels/HomeViewModel.swift
import Foundation
import Combine
import CoreLocation

class HomeViewModel: ObservableObject {
    // MARK: - Опубліковані властивості
    
    @Published var coffeeShops: [CoffeeShop] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var currentLocation: CLLocationCoordinate2D?
    
    // MARK: - Залежності та властивості
    
    private let coffeeShopRepository: CoffeeShopRepositoryProtocol
    private let locationManager = CLLocationManager()
    
    // MARK: - Ініціалізація
    
    init(coffeeShopRepository: CoffeeShopRepositoryProtocol) {
        self.coffeeShopRepository = coffeeShopRepository
    }
    
    // MARK: - Користувацькі методи для роботи з кав'ярнями
    
    /// Завантаження всіх кав'ярень з сортуванням за відстанню, якщо доступно
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
    
    /// Пошук кав'ярень за запитом (адресою)
    @MainActor
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
    
    // MARK: - Методи для роботи з геолокацією
    
    /// Запуск відстеження місцезнаходження
    func startLocationUpdates() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    /// Оновлення поточного місцезнаходження
    func updateLocation(coordinate: CLLocationCoordinate2D) {
        self.currentLocation = coordinate
    }
}
