import Foundation

// Простий кеш для інформації про кав'ярні
class CoffeeShopCache {
    static let shared = CoffeeShopCache()
    
    private var cache: [String: CoffeeShopCacheItem] = [:]
    private let queue = DispatchQueue(label: "com.nidus.coffeeshop.cache", attributes: .concurrent)
    
    private init() {}
    
    struct CoffeeShopCacheItem {
        let id: String
        let name: String
        let address: String?
    }
    
    func setCoffeeShop(_ id: String, name: String, address: String?) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.cache[id] = CoffeeShopCacheItem(id: id, name: name, address: address)
            // Логування видалено для production
        }
    }
    
    func getCoffeeShopName(for id: String) -> String? {
        return queue.sync {
            return cache[id]?.name
        }
    }
    
    func getCoffeeShopAddress(for id: String) -> String? {
        return queue.sync {
            return cache[id]?.address
        }
    }
    
    func clearCache() {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeAll()
        }
    }
} 