import Foundation

// Простий кеш для інформації про кав'ярні
class CoffeeShopCache {
    static let shared = CoffeeShopCache()
    
    private var cache: [String: CoffeeShopCacheItem] = [:]
    
    private init() {}
    
    struct CoffeeShopCacheItem {
        let id: String
        let name: String
        let address: String?
    }
    
    func setCoffeeShop(_ id: String, name: String, address: String?) {
        cache[id] = CoffeeShopCacheItem(id: id, name: name, address: address)
        print("💾 CoffeeShopCache: Збережено кав'ярню \(id) -> \(name)")
    }
    
    func getCoffeeShopName(for id: String) -> String? {
        return cache[id]?.name
    }
    
    func getCoffeeShopAddress(for id: String) -> String? {
        return cache[id]?.address
    }
    
    func clearCache() {
        cache.removeAll()
    }
} 