//
//  WorkingHoursPeriod.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/31/25.
//

import SwiftUI

struct WorkingHoursPeriod: Codable, Equatable {
    var open: String
    var close: String
    var isClosed: Bool
    
    // Конвертує рядок часу в Date для порівняння
    func openDate() -> Date? {
        return timeStringToDate(open)
    }
    
    func closeDate() -> Date? {
        return timeStringToDate(close)
    }
    
    // Допоміжна функція для перетворення рядка часу в Date
    private func timeStringToDate(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString)
    }
}

struct WorkingHoursEditorView: View {
    @Binding var workingHours: [String: WorkingHoursPeriod]
    @State private var showValidationError = false
    @State private var validationErrorMessage = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Години роботи")
                .font(.headline)
                .foregroundColor(Color("primaryText"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Швидкі шаблони робочих годин
            HStack {
                Text("Шаблони:")
                    .font(.subheadline)
                    .foregroundColor(Color("secondaryText"))
                
                Spacer()
                
                Button("Стандартний (9-21)") {
                    applyStandardTemplate()
                }
                .font(.caption)
                .foregroundColor(Color("primary"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color("primary").opacity(0.1))
                .cornerRadius(4)
            }
            
            HStack {
                Button("Розширений (8-22)") {
                    applyExtendedTemplate()
                }
                .font(.caption)
                .foregroundColor(Color("primary"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color("primary").opacity(0.1))
                .cornerRadius(4)
                
                Spacer()
                
                Button("Копіювати перший день") {
                    applyFirstDayTemplate()
                }
                .font(.caption)
                .foregroundColor(Color("primary"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color("primary").opacity(0.1))
                .cornerRadius(4)
            }
            .padding(.bottom, 8)
            
            // Перебираємо дні тижня та відображаємо редактор для кожного дня
            ForEach(WorkingHoursModel.weekDays.keys.sorted(), id: \.self) { dayKey in
                if let day = WorkingHoursModel.weekDays[dayKey] {
                    DayWorkingHoursEditor(
                        day: day,
                        workingHours: Binding(
                            get: {
                                // Якщо години роботи для цього дня не задані, створюємо дефолтні
                                return workingHours[dayKey] ?? WorkingHoursPeriod(
                                    open: "09:00",
                                    close: "21:00",
                                    isClosed: false
                                )
                            },
                            set: { newValue in
                                workingHours[dayKey] = newValue
                                validateWorkingHours()
                            }
                        )
                    )
                }
            }
            
            // Показуємо помилку валідації, якщо є
            if showValidationError {
                Text(validationErrorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
        }
    }
    
    // Застосування стандартного шаблону (9-21, неділя вихідний)
    private func applyStandardTemplate() {
        for day in 0...6 {
            workingHours["\(day)"] = WorkingHoursPeriod(
                open: "09:00",
                close: "21:00",
                isClosed: day == 0
            )
        }
        validateWorkingHours()
    }
    
    // Застосування розширеного шаблону (8-22, без вихідних)
    private func applyExtendedTemplate() {
        for day in 0...6 {
            workingHours["\(day)"] = WorkingHoursPeriod(
                open: "08:00",
                close: "22:00",
                isClosed: false
            )
        }
        validateWorkingHours()
    }
    
    // Копіювання годин з першого робочого дня на всі інші дні
    private func applyFirstDayTemplate() {
        // Знаходимо перший робочий день
        let sortedDays = WorkingHoursModel.weekDays.keys.sorted()
        guard let firstDayKey = sortedDays.first,
              let firstDayHours = workingHours[firstDayKey] else {
            return
        }
        
        // Копіюємо години на всі інші дні
        for day in sortedDays {
            if day != firstDayKey {
                workingHours[day] = firstDayHours
            }
        }
        validateWorkingHours()
    }
    
    // Валідація робочих годин
    private func validateWorkingHours() {
        let model = WorkingHoursModel(hours: workingHours)
        let (isValid, errorMessage) = model.validate()
        
        showValidationError = !isValid
        if let message = errorMessage {
            validationErrorMessage = message
        }
    }
}

struct DayWorkingHoursEditor: View {
    let day: String
    @Binding var workingHours: WorkingHoursPeriod
    
    @State private var openDate: Date = Date()
    @State private var closeDate: Date = Date()
    
    init(day: String, workingHours: Binding<WorkingHoursPeriod>) {
        self.day = day
        self._workingHours = workingHours
        
        // Ініціалізуємо дати з рядків часу
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let openTime = formatter.date(from: workingHours.wrappedValue.open) {
            _openDate = State(initialValue: openTime)
        }
        
        if let closeTime = formatter.date(from: workingHours.wrappedValue.close) {
            _closeDate = State(initialValue: closeTime)
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(day)
                    .font(.subheadline)
                    .foregroundColor(Color("primaryText"))
                    .frame(width: 100, alignment: .leading)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { !workingHours.isClosed },
                    set: { newValue in
                        workingHours.isClosed = !newValue
                    }
                ))
                .toggleStyle(SwitchToggleStyle(tint: Color("primary")))
                .labelsHidden()
            }
            
            if !workingHours.isClosed {
                HStack(spacing: 12) {
                    // Відступ для вирівнювання з текстом дня
                    Spacer()
                        .frame(width: 10)
                    
                    // Вибір часу відкриття
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Відкриття")
                            .font(.caption)
                            .foregroundColor(Color("secondaryText"))
                        
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { openDate },
                                set: { newDate in
                                    openDate = newDate
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "HH:mm"
                                    workingHours.open = formatter.string(from: newDate)
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .background(Color("inputField"))
                        .cornerRadius(8)
                    }
                    
                    // Вибір часу закриття
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Закриття")
                            .font(.caption)
                            .foregroundColor(Color("secondaryText"))
                        
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { closeDate },
                                set: { newDate in
                                    closeDate = newDate
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "HH:mm"
                                    workingHours.close = formatter.string(from: newDate)
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .background(Color("inputField"))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(10)
        .background(workingHours.isClosed ? Color("cardColor").opacity(0.6) : Color("cardColor"))
        .cornerRadius(8)
        .opacity(workingHours.isClosed ? 0.7 : 1.0)
    }
}
