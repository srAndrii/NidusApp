//
//  ScrollCoordinator.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/12/25.
//

import SwiftUI
import UIKit

// Простий утилітарний клас для програмного скролінгу
class ScrollingManager {
    static let shared = ScrollingManager()
    
    // Змінні для збереження ID і UIScrollView
    var currentScrollView: UIScrollView?
    var groupOffsets: [String: CGFloat] = [:]
    var groupSizes: [String: CGSize] = [:] // Додаємо збереження розмірів груп
    var allGroupIds: [String] = [] // Додаємо масив для відстеження всіх доступних ID груп
    
    // Реєструє існуючий UIScrollView для скролінгу
    func registerScrollView(_ scrollView: UIScrollView) {
        self.currentScrollView = scrollView
    }
    
    // Реєструє позицію групи
    func registerGroupPosition(id: String, position: CGFloat) {
        groupOffsets[id] = position
        
        // Додаємо ID до масиву, якщо його ще немає
        if id != "top" && !allGroupIds.contains(id) {
            allGroupIds.append(id)
            // Сортуємо масив за значеннями позицій (зверху вниз)
            allGroupIds.sort { groupOffsets[$0] ?? 0 < groupOffsets[$1] ?? 0 }
        }
        
        print("Registered group position: \(id) = \(position)")
    }
    
    // Реєструє розмір групи (необхідно для кращого скролінгу)
    func registerGroupSize(id: String, size: CGSize) {
        groupSizes[id] = size
        print("Registered group size: \(id) = \(size)")
    }
    
    // Скролить до групи за ID
    func scrollToGroup(id: String, animated: Bool = true) {
        guard let scrollView = currentScrollView,
              let offset = groupOffsets[id] else {
            print("Cannot scroll to \(id): scrollView or offset not available")
            
            // Додаємо затримку і повторну спробу, якщо UIScrollView або позиція ще не доступні
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                if let self = self {
                    self.scrollToGroup(id: id, animated: animated)
                }
            }
            return
        }
        
        // Краще обчислення зміщення для різних груп
        var adjustedOffset: CGFloat = 0
        
        if id == "top" {
            // Для верху прокручуємо в абсолютний початок
            adjustedOffset = 0
        } else {
            // Перевіряємо, чи це остання група
            let isLastGroup = allGroupIds.last == id
            
            if isLastGroup {
                // Для останньої групи прокручуємо так, щоб вона була якраз над таб-баром
                
                // Отримуємо розміри контенту та видимої області
                let contentHeight = scrollView.contentSize.height
                let frameHeight = scrollView.frame.height
                let tabBarHeight: CGFloat = 90 // Приблизна висота таб-бару з відступами
                
                // Отримуємо фактичну висоту групи, якщо вона зареєстрована
                let groupHeight = groupSizes[id]?.height ?? 300
                
                // Розраховуємо ідеальну позицію:
                // Максимальне зміщення, яке дозволяє бачити всю групу над таб-баром
                let maxOffsetY = max(0, contentHeight - frameHeight)
                
                // Коригуємо позицію, щоб вона була дещо вища, ніж проста різниця між
                // розміром контенту і розміром екрану. Це дозволяє бачити всю групу
                // і не мати пустого місця знизу.
                let idealOffset = max(0, maxOffsetY - (groupHeight / 2))
                
                // Забезпечуємо, щоб група була повністю видима
                adjustedOffset = min(idealOffset, offset)
                
                print("Last group: using actual group height: \(groupHeight), ideal offset: \(idealOffset)")
            } else {
                // Для всіх інших груп використовуємо звичайну логіку
                // Константа 100 додана для врахування висоти фільтра категорій
                adjustedOffset = max(0, offset - 100)
            }
        }
        
        // Додамо перевірку, чи змінилась позиція значно, щоб уникнути непотрібних скролів
        let currentOffset = scrollView.contentOffset.y
        if abs(currentOffset - adjustedOffset) < 10 {
            print("Skip scrolling: already at position")
            return
        }
        
        // Використовуємо DispatchQueue.main.async для надійності
        DispatchQueue.main.async {
            print("Scrolling to offset: \(adjustedOffset) for group ID: \(id)")
            
            // Використання animateWithDuration для плавнішої анімації
            if animated {
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                    scrollView.contentOffset = CGPoint(x: 0, y: adjustedOffset)
                }, completion: nil)
            } else {
                scrollView.setContentOffset(CGPoint(x: 0, y: adjustedOffset), animated: false)
            }
        }
    }
}

// Модифікатор для відстеження позиції групи меню
struct RegisterGroupOffsetModifier: ViewModifier {
    let id: String
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: OffsetPreferenceKey.self, value: [id: geo.frame(in: .global).minY])
                        .preference(key: SizePreferenceKey.self, value: [id: geo.size])
                        .onPreferenceChange(OffsetPreferenceKey.self) { preferences in
                            if let position = preferences[id] {
                                ScrollingManager.shared.registerGroupPosition(id: id, position: position)
                                print("Group \(id) position registered: \(position)")
                            }
                        }
                        .onPreferenceChange(SizePreferenceKey.self) { preferences in
                            if let size = preferences[id] {
                                ScrollingManager.shared.registerGroupSize(id: id, size: size)
                            }
                        }
                        .onAppear {
                            // Реєструємо також при появі для надійності
                            let frame = geo.frame(in: .global)
                            ScrollingManager.shared.registerGroupPosition(id: id, position: frame.minY)
                            ScrollingManager.shared.registerGroupSize(id: id, size: geo.size)
                            print("Group \(id) position registered on appear: \(frame.minY)")
                        }
                }
            )
    }
}

// Preference Key для відстеження позицій
struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]
    
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue()) { (current, new) in new }
    }
}

// Preference Key для відстеження розмірів
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGSize] = [:]
    
    static func reduce(value: inout [String: CGSize], nextValue: () -> [String: CGSize]) {
        value.merge(nextValue()) { (current, new) in new }
    }
}

// Модифікатор для знаходження найближчого UIScrollView в ієрархії
struct ScrollViewFinderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ScrollViewFinder()
            )
            .onAppear {
                // Затримка для пошуку UIScrollView після рендерингу всього вмісту
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if ScrollingManager.shared.currentScrollView == nil {
                        print("Retrying to find UIScrollView...")
                        // Можна додати додаткову логіку пошуку, якщо необхідно
                    }
                }
            }
    }
}

// Допоміжний UIViewRepresentable для пошуку UIScrollView
struct ScrollViewFinder: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            // Шукаємо найближчий UIScrollView
            findScrollView(from: uiView)
        }
    }
    
    private func findScrollView(from view: UIView) {
        // Піднімаємось по ієрархії, шукаючи UIScrollView
        var current: UIView? = view
        while current != nil {
            if let scrollView = current as? UIScrollView {
                // Перевіряємо, чи це не невеликий допоміжний ScrollView, як наприклад з фільтрів
                if scrollView.frame.height > 200 { // Ми шукаємо основний ScrollView, який зазвичай більший
                    ScrollingManager.shared.registerScrollView(scrollView)
                    print("Found and registered UIScrollView with height: \(scrollView.frame.height)")
                    return
                }
            }
            current = current?.superview
        }
        
        // Якщо не знайшли в ієрархії, шукаємо в дочірніх елементах через root вікно
        if ScrollingManager.shared.currentScrollView == nil,
           let rootWindow = UIApplication.shared.windows.first {
            findScrollViewInWindow(rootWindow)
        }
    }
    
    private func findScrollViewInWindow(_ window: UIWindow) {
        print("Searching for UIScrollView in window hierarchy")
        // Шукаємо всі ScrollView у вікні
        for subview in window.subviews {
            findScrollViewInSubviewsWithPriority(of: subview)
        }
    }
    
    private func findScrollViewInSubviews(of view: UIView) {
        for subview in view.subviews {
            if let scrollView = subview as? UIScrollView {
                if scrollView.frame.height > 200 { // Перевіряємо розмір
                    ScrollingManager.shared.registerScrollView(scrollView)
                    print("Found and registered UIScrollView in subviews with height: \(scrollView.frame.height)")
                    return
                }
            }
            findScrollViewInSubviews(of: subview)
        }
    }
    
    private func findScrollViewInSubviewsWithPriority(of view: UIView) {
        // Перевіряємо сам view
        if let scrollView = view as? UIScrollView {
            if scrollView.frame.height > 200 { // Основний ScrollView зазвичай високий
                ScrollingManager.shared.registerScrollView(scrollView)
                print("Found main UIScrollView with height: \(scrollView.frame.height)")
                return
            }
        }
        
        // Визначаємо пріоритетні типи, які зазвичай містять основний ScrollView
        let isPriority = view is UINavigationController || view is UIViewController || view is UIHostingController<AnyView>
        
        if isPriority {
            print("Checking priority container: \(type(of: view))")
            // Перевіряємо дочірні елементи пріоритетно
            findScrollViewInSubviews(of: view)
        }
        
        // Перевіряємо решту дочірніх елементів
        for subview in view.subviews {
            findScrollViewInSubviewsWithPriority(of: subview)
        }
    }
}

// Розширення для View для зручного застосування модифікаторів
extension View {
    func registerGroupOffset(id: String) -> some View {
        self.modifier(RegisterGroupOffsetModifier(id: id))
    }
    
    func findScrollView() -> some View {
        self.modifier(ScrollViewFinderModifier())
    }
}
