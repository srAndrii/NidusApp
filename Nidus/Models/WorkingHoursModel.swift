//
//  WorkingHoursModel.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/31/25.
//

import Foundation

// Структура для представлення всіх робочих годин кав'ярні
struct WorkingHoursModel {
    var hours: [String: WorkingHoursPeriod]
    
    // Назви днів тижня для відображення
    static let weekDays = [
        "0": "Неділя",
        "1": "Понеділок",
        "2": "Вівторок",
        "3": "Середа",
        "4": "Четвер",
        "5": "П'ятниця",
        "6": "Субота"
    ]
    
    // Створення дефолтних робочих годин
    static func createDefault() -> [String: WorkingHoursPeriod] {
        var defaultHours: [String: WorkingHoursPeriod] = [:]
        
        for day in 0...6 {
            defaultHours["\(day)"] = WorkingHoursPeriod(
                open: "09:00",
                close: "21:00",
                isClosed: day == 0 // За замовчуванням неділя - вихідний
            )
        }
        
        return defaultHours
    }
    
    // Перевірка, чи відкрита кав'ярня зараз
    func isOpenNow() -> Bool {
        // Отримуємо поточний день тижня
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date()) - 1
        let weekdayString = String(weekday)
        
        guard let todayHours = hours[weekdayString] else {
            return false // Якщо немає інформації про години роботи, вважаємо закритим
        }
        
        if todayHours.isClosed {
            return false // Якщо сьогодні вихідний
        }
        
        // Перевіряємо, чи зараз між часом відкриття і закриття
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let openTime = formatter.date(from: todayHours.open),
              let closeTime = formatter.date(from: todayHours.close) else {
            return false // Якщо неможливо розпарсити час
        }
        
        // Отримуємо поточний час (години:хвилини)
        let now = Date()
        let nowString = formatter.string(from: now)
        guard let nowTime = formatter.date(from: nowString) else {
            return false
        }
        
        return nowTime >= openTime && nowTime <= closeTime
    }
    
    func validate() -> (Bool, String?) {
        // Перевірка на наявність хоча б одного робочого дня
        let hasWorkingDays = hours.values.contains { !$0.isClosed }
        if !hasWorkingDays {
            return (false, "Кав'ярня повинна мати хоча б один робочий день")
        }
        
        // Перевірка часу відкриття і закриття
        for (day, period) in hours {
            if !period.isClosed {
                if let openDate = period.openDate(),
                   let closeDate = period.closeDate(),
                   openDate >= closeDate {
                    let dayName = WorkingHoursModel.weekDays[day] ?? day
                    return (false, "Помилка: В \(dayName) час відкриття має бути раніше часу закриття.")
                }
                
                // Перевірка формату часу
                let timeRegex = try? NSRegularExpression(pattern: "^([01]?[0-9]|2[0-3]):[0-5][0-9]$")
                if timeRegex?.firstMatch(in: period.open, range: NSRange(location: 0, length: period.open.count)) == nil ||
                   timeRegex?.firstMatch(in: period.close, range: NSRange(location: 0, length: period.close.count)) == nil {
                    let dayName = WorkingHoursModel.weekDays[day] ?? day
                    return (false, "Помилка: В \(dayName) неправильний формат часу. Використовуйте формат ГГ:ХХ.")
                }
            }
        }
        
        return (true, nil)
    }
    
    // Конвертація для API
    func toApiModel() -> [String: [String: Any]] {
        var result: [String: [String: Any]] = [:]
        
        for (day, period) in hours {
            result[day] = [
                "open": period.open,
                "close": period.close,
                "isClosed": period.isClosed
            ]
        }
        
        return result
    }
}

// Розширення для моделі WorkingHoursPeriod з валідацією
extension WorkingHoursPeriod {
    // Валідація робочих годин
    func isValid() -> Bool {
        if isClosed {
            return true // Якщо заклад закритий, валідація не потрібна
        }
        
        guard let openTime = openDate(),
              let closeTime = closeDate() else {
            return false // Неможливо розпарсити час
        }
        
        return openTime < closeTime // Час відкриття має бути раніше часу закриття
    }
}

// Розширення для використання WorkingHoursModel в CoffeeShop
extension CoffeeShop {
    // Конвертує робочі години з API формату в WorkingHoursModel
    func getWorkingHoursModel() -> WorkingHoursModel {
        if let workingHours = self.workingHours {
            return WorkingHoursModel(hours: workingHours)
        } else {
            return WorkingHoursModel(hours: WorkingHoursModel.createDefault())
        }
    }
    
    // Перевіряє, чи відкрита кав'ярня зараз (базуючись на робочих годинах)
    var isOpenBasedOnHours: Bool {
        let model = getWorkingHoursModel()
        return model.isOpenNow()
    }
    
    // Отримує рядкове представлення робочих годин на сьогодні
    func getWorkingHoursForToday() -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date()) - 1
        let weekdayString = String(weekday)
        
        guard let workingHours = self.workingHours,
              let todayHours = workingHours[weekdayString] else {
            return "Немає інформації"
        }
        
        if todayHours.isClosed {
            return "Зачинено сьогодні"
        }
        
        return "\(todayHours.open) - \(todayHours.close)"
    }
    
    // Отримує назву дня для конкретного дня тижня
    func getDayName(for day: Int) -> String {
        return WorkingHoursModel.weekDays[String(day)] ?? "День \(day)"
    }
}
