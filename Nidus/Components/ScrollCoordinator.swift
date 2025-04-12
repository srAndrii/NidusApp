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
    
    // Реєструє існуючий UIScrollView для скролінгу
    func registerScrollView(_ scrollView: UIScrollView) {
        self.currentScrollView = scrollView
    }
    
    // Реєструє позицію групи
    func registerGroupPosition(id: String, position: CGFloat) {
        groupOffsets[id] = position
        print("Registered group position: \(id) = \(position)")
    }
    
    // Скролить до групи за ID
    func scrollToGroup(id: String, animated: Bool = true) {
        guard let scrollView = currentScrollView,
              let offset = groupOffsets[id] else {
            print("Cannot scroll to \(id): scrollView or offset not available")
            return
        }
        
        // Враховуємо висоту шапки та фільтрів
        let adjustedOffset = max(0, offset - 380)
        
        // Використовуємо DispatchQueue.main.async для надійності
        DispatchQueue.main.async {
            print("Scrolling to offset: \(adjustedOffset) for group ID: \(id)")
            scrollView.setContentOffset(CGPoint(x: 0, y: adjustedOffset), animated: animated)
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
                        .onAppear {
                            // Зберігаємо Y-позицію в глобальних координатах
                            let frame = geo.frame(in: .global)
                            ScrollingManager.shared.registerGroupPosition(id: id, position: frame.minY)
                            print("Group \(id) position registered: \(frame.minY)")
                        }
                }
            )
    }
}

// Модифікатор для знаходження найближчого UIScrollView в ієрархії
struct ScrollViewFinderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ScrollViewFinder()
            )
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
                ScrollingManager.shared.registerScrollView(scrollView)
                print("Found and registered UIScrollView")
                break
            }
            current = current?.superview
        }
        
        // Якщо не знайшли в ієрархії, шукаємо в дочірніх елементах superview
        if ScrollingManager.shared.currentScrollView == nil,
           let superview = view.superview {
            findScrollViewInSubviews(of: superview)
        }
    }
    
    private func findScrollViewInSubviews(of view: UIView) {
        for subview in view.subviews {
            if let scrollView = subview as? UIScrollView {
                ScrollingManager.shared.registerScrollView(scrollView)
                print("Found and registered UIScrollView in subviews")
                break
            }
            findScrollViewInSubviews(of: subview)
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
