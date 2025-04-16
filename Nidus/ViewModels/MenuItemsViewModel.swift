import Foundation

class MenuItemsViewModel: ObservableObject {
    // MARK: - Опубліковані властивості
    
    @Published var menuItems: [MenuItem] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showSuccess = false
    @Published var successMessage = ""
    
    // MARK: - Залежності та властивості
    
    private let repository = DIContainer.shared.menuItemRepository
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService.shared) {
        self.networkService = networkService
    }
    
    // MARK: - Користувацькі методи для роботи з пунктами меню
    
    /// Завантаження всіх пунктів меню для групи
    @MainActor
    func loadMenuItems(groupId: String) async {
        isLoading = true
        error = nil
        
        do {
            print("Запит пунктів меню для групи: \(groupId)")
            menuItems = try await repository.getMenuItems(groupId: groupId)
            print("Отримано \(menuItems.count) пунктів меню")
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Адміністративні методи для роботи з пунктами меню
    
    /// Створення нового пункту меню
   
    private let DEFAULT_MENU_ITEM_URL = "https://res.cloudinary.com/dlbbjiuco/image/upload/v1741643259/nidus/defaults/menu-item.png"

    // Оновити метод createMenuItem в MenuItemsViewModel.swift для використання дефолтного зображення
    @MainActor
    func createMenuItem(groupId: String, name: String, price: Decimal, description: String?, 
                       isAvailable: Bool, hasMultipleSizes: Bool = false,
                       ingredients: [Ingredient]? = nil, 
                       customizationOptions: [CustomizationOption]? = nil,
                       sizes: [Size]? = nil) async throws -> MenuItem {
        isLoading = true
        error = nil
        
        do {
            // Створення структури запиту з необхідними даними
            let createRequest = CreateMenuItemRequest(
                name: name,
                price: price,
                description: description,
                isAvailable: isAvailable,
                ingredients: ingredients,
                customizationOptions: nil, // Наразі backend не підтримує передачу customizationOptions при створенні
                hasMultipleSizes: hasMultipleSizes,
                sizes: sizes,
                menuGroupId: groupId  // Встановлюємо groupId
            )
            
            // Створюємо пункт меню через репозиторій
            let newItem = try await repository.createMenuItem(groupId: groupId, item: createRequest)
            
            // Встановлюємо дефолтне зображення, якщо воно не було встановлено при створенні
            if newItem.imageUrl == nil {
                // Оновлюємо інформацію про пункт меню, додавши дефолтне зображення
                let updates: [String: Any] = ["imageUrl": DEFAULT_MENU_ITEM_URL]
                
                // Оновлюємо пункт меню з дефолтним зображенням
                let updatedItem = try await repository.updateMenuItem(groupId: groupId, itemId: newItem.id, updates: updates)
                
                // Додаємо оновлений пункт до списку
                menuItems.append(updatedItem)
                
                // Показуємо повідомлення про успіх
                showSuccessMessage("Пункт меню \"\(name)\" успішно створено!")
                
                isLoading = false
                return updatedItem
            } else {
                // Додаємо новий пункт до списку
                menuItems.append(newItem)
                
                // Показуємо повідомлення про успіх
                showSuccessMessage("Пункт меню \"\(name)\" успішно створено!")
                
                isLoading = false
                return newItem
            }
        } catch let apiError as APIError {
            handleError(apiError)
            isLoading = false
            throw apiError
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            throw error
        }
    }
    
    /// Оновлення пункту меню
    @MainActor
    func updateMenuItem(groupId: String, itemId: String, updates: [String: Any]) async throws -> MenuItem {
        print("🔄 MenuItemsViewModel.updateMenuItem - початок")
            print("🔄 groupId: \(groupId), itemId: \(itemId)")
            print("🔄 updates: \(updates)")
            
            // Перевіряємо наявність customizationOptions в оновленнях
            if let customOptions = updates["customizationOptions"] {
                print("🔄 customizationOptions присутні в updates:")
                print("🔄 тип: \(type(of: customOptions))")
                print("🔄 значення: \(customOptions)")
            } else {
                print("🔄 customizationOptions ВІДСУТНІ в updates!")
            }
        // Створюємо безпечну копію оновлень для серіалізації
        var safeUpdates = [String: Any]()
        
        // Копіюємо прості значення як є
        for (key, value) in updates {
            if key != "ingredients" && key != "customizationOptions" {
                safeUpdates[key] = value
            }
        }
        
        // Обробляємо інгредієнти якщо вони є
        if let ingredients = updates["ingredients"] as? [Ingredient] {
            let safeIngredients = ingredients.map { ingredient -> [String: Any] in
                var dict: [String: Any] = [
                    "name": ingredient.name,
                    "amount": ingredient.amount,
                    "unit": ingredient.unit,
                    "isCustomizable": ingredient.isCustomizable
                ]
                
                // Додаємо опціональні поля, тільки якщо вони не nil
                if let minAmount = ingredient.minAmount {
                    dict["minAmount"] = minAmount
                }
                
                if let maxAmount = ingredient.maxAmount {
                    dict["maxAmount"] = maxAmount
                }
                
                // Додані нові поля freeAmount і pricePerUnit
                if let freeAmount = ingredient.freeAmount {
                    dict["freeAmount"] = freeAmount
                }
                
                if let pricePerUnit = ingredient.pricePerUnit {
                    dict["pricePerUnit"] = pricePerUnit
                }
                
                return dict
            }
            
            safeUpdates["ingredients"] = safeIngredients
        }
        
        // Обробляємо опції кастомізації якщо вони є
        if let customOptions = updates["customizationOptions"] as? [CustomizationOption] {
            print("🔄 Перетворення customizationOptions з [CustomizationOption]")
            print("🔄 Кількість опцій: \(customOptions.count)")
            
            let safeOptions = customOptions.map { option -> [String: Any] in
                print("🔄   Обробка опції: \(option.id) - \(option.name)")
                
                var optionDict: [String: Any] = [
                    "id": option.id,
                    "name": option.name,
                    "required": option.required
                ]
                
                // Конвертуємо вибори
                let safeChoices = option.choices.map { choice -> [String: Any] in
                    print("🔄     Обробка вибору: \(choice.id) - \(choice.name)")
                    
                    var choiceDict: [String: Any] = [
                        "id": choice.id,
                        "name": choice.name
                    ]
                    
                    // Додаємо ціну, тільки якщо вона не nil
                    if let price = choice.price {
                        choiceDict["price"] = price
                        print("🔄       Ціна: \(price)")
                    } else {
                        print("🔄       Без ціни")
                    }
                    
                    return choiceDict
                }
                
                print("🔄   Варіанти вибору: \(safeChoices.count)")
                optionDict["choices"] = safeChoices
                return optionDict
            }
            
            print("🔄 Перетворені customizationOptions: \(safeOptions)")
            safeUpdates["customizationOptions"] = safeOptions
        }
        
        // Обробляємо розміри, якщо вони є
        if let sizes = updates["sizes"] as? [Size] {
            print("🔄 Перетворення sizes з [Size]")
            print("🔄 Кількість розмірів: \(sizes.count)")
            
            let safeSizes = sizes.map { size -> [String: Any] in
                print("🔄   Обробка розміру: \(size.id) - \(size.name)")
                
                var sizeDict: [String: Any] = [
                    "id": size.id,
                    "name": size.name,
                    "abbreviation": size.abbreviation,
                    "additionalPrice": size.additionalPrice,
                    "isDefault": size.isDefault
                ]
                
                return sizeDict
            }
            
            print("🔄 Перетворені sizes: \(safeSizes)")
            safeUpdates["sizes"] = safeSizes
        }
        
        do {
            // Перевіряємо, чи можна серіалізувати наші дані
            let jsonData = try JSONSerialization.data(withJSONObject: safeUpdates)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Дані для оновлення: \(jsonString)")
            }
            
            // Створюємо та виконуємо запит напряму
            let baseURL = networkService.getBaseURL()
            guard let url = URL(string: baseURL + "/menu-groups/\(groupId)/items/\(itemId)") else {
                throw APIError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let token = UserDefaults.standard.string(forKey: "accessToken") {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            // Встановлюємо тіло запиту напряму
            request.httpBody = jsonData
            
            // Виконуємо запит
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
            
            // Виводимо відповідь для діагностики
            if let responseString = String(data: data, encoding: .utf8) {
                print("Відповідь сервера: \(responseString)")
            }
            
            // Використовуємо спеціальний декодер з надійною обробкою дат
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateStr = try container.decode(String.self)
                
                // Спробуємо різні формати дат
                let formatters = [
                    "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                    "yyyy-MM-dd'T'HH:mm:ssZ",
                    "yyyy-MM-dd'T'HH:mm:ss"
                ].map { format -> DateFormatter in
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    return formatter
                }
                
                for formatter in formatters {
                    if let date = formatter.date(from: dateStr) {
                        return date
                    }
                }
                
                // Якщо не вдалося розпарсити, просто повертаємо поточну дату замість помилки
                print("❌ Не вдалося розпарсити дату: \(dateStr)")
                return Date()
            }
            
            do {
                return try decoder.decode(MenuItem.self, from: data)
            } catch {
                print("❌ Помилка декодування: \(error)")
                
                // Якщо декодування не вдалося, повертаємо запит для отримання пункту меню
                return try await getMenuItem(groupId: groupId, itemId: itemId)
            }
        } catch {
            print("Помилка при оновленні пункту меню: \(error)")
            throw error
        }
    }
    
    @MainActor
    func getMenuItem(groupId: String, itemId: String) async throws -> MenuItem {
        // Спочатку перевіряємо, чи є пункт меню вже завантажений
        if let menuItem = menuItems.first(where: { $0.id == itemId }) {
            return menuItem
        }
        
        // Якщо немає, завантажуємо всі пункти меню для групи
        await loadMenuItems(groupId: groupId)
        
        // Після завантаження перевіряємо ще раз
        if let menuItem = menuItems.first(where: { $0.id == itemId }) {
            return menuItem
        }
        
        // Якщо все ще немає, кидаємо помилку
        throw NSError(domain: "MenuItemsViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "Пункт меню не знайдено"])
    }
    
    /// Завантаження зображення для пункту меню
    @MainActor
    func uploadMenuItemImage(groupId: String, itemId: String, imageRequest: ImageUploadRequest) async throws {
        do {
            // Виправлений endpoint
            let endpoint = "/upload/menu-item/\(itemId)/image"
            let uploadResponse: UploadResponse = try await networkService.uploadFile(
                endpoint: endpoint,
                data: imageRequest.imageData,
                fieldName: "file",
                fileName: imageRequest.fileName,
                mimeType: imageRequest.mimeType
            )
            
            // Оновлюємо локальний список пунктів меню
            if let index = menuItems.firstIndex(where: { $0.id == itemId }) {
                menuItems[index].imageUrl = uploadResponse.url
            }
            
            // Показуємо повідомлення про успіх
            showSuccessMessage("Зображення успішно додано!")
        } catch {
            // Обробка помилки завантаження
            print("Помилка завантаження зображення: \(error)")
            self.error = "Не вдалося завантажити зображення: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// Видалення пункту меню
    @MainActor
    func deleteMenuItem(groupId: String, itemId: String) async {
        isLoading = true
        error = nil
        
        do {
            // Викликаємо репозиторій для видалення пункту меню
            try await repository.deleteMenuItem(groupId: groupId, itemId: itemId)
            
            // Видаляємо пункт меню з локального списку
            menuItems.removeAll { $0.id == itemId }
            
            showSuccessMessage("Пункт меню успішно видалено!")
        } catch let apiError as APIError {
            handleError(apiError)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Оновлення доступності пункту меню
    @MainActor
    func updateMenuItemAvailability(groupId: String, itemId: String, available: Bool) async {
        do {
            print("Оновлюємо доступність для \(itemId) на \(available)")
            
            // Оновлюємо локальний стан для миттєвої реакції інтерфейсу
            if let index = menuItems.firstIndex(where: { $0.id == itemId }) {
                menuItems[index].isAvailable = available
            }
            
            // Очищаємо попередню помилку
            self.error = nil
            
            // Виконуємо запит
            let updatedItem = try await repository.updateMenuItem(
                groupId: groupId,
                itemId: itemId,
                updates: ["isAvailable": available]
            )
            
            // Оновлюємо локальний стан з даними з сервера
            if let index = menuItems.firstIndex(where: { $0.id == itemId }) {
                menuItems[index] = updatedItem
            }
            
            showSuccessMessage("Доступність пункту меню оновлено!")
        } catch {
            print("Помилка при оновленні доступності: \(error)")
            self.error = "Помилка оновлення: \(error.localizedDescription)"
            
            // Перезавантаження даних, щоб відновити правильний стан
            await loadMenuItems(groupId: groupId)
        }
    }
    
    // MARK: - Допоміжні методи
    
    /// Показ повідомлення про успіх
    func showSuccessMessage(_ message: String) {
        successMessage = message
        showSuccess = true
    }
    
    /// Обробка помилок API
    private func handleError(_ apiError: APIError) {
        switch apiError {
        case .serverError(_, let message):
            self.error = message ?? "Невідома помилка сервера"
        case .unauthorized:
            self.error = "Необхідна авторизація для виконання цієї дії"
        default:
            self.error = apiError.localizedDescription
        }
    }
}
