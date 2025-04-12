//
//  UIScrollViewComponents.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 4/12/25.
//

import SwiftUI
import UIKit

// Координатор для UIScrollView
class ScrollViewCoordinator: NSObject, UIScrollViewDelegate {
    var parent: UIScrollViewWrapper
    
    init(_ parent: UIScrollViewWrapper) {
        self.parent = parent
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Можна відстежувати скролінг, якщо потрібно
        parent.currentOffset = scrollView.contentOffset.y
    }
}

// Обгортка UIScrollView для SwiftUI
struct UIScrollViewWrapper: UIViewRepresentable {
    // Змінено на SwiftUI View замість UIView
    var content: AnyView
    @Binding var scrollToSection: String?
    @Binding var sectionOffsets: [String: CGFloat]
    @Binding var currentOffset: CGFloat
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false
        
        // Створюємо UIHostingController для відображення SwiftUI вмісту
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        
        // Додаємо вміст до ScrollView
        scrollView.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            hostingController.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        return scrollView
    }
    
    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        // Визначаємо загальну висоту вмісту
        if let subview = scrollView.subviews.first {
            scrollView.contentSize = subview.frame.size
        }
        
        // Якщо потрібно прокрутити до секції
        if let section = scrollToSection, let offset = sectionOffsets[section] {
            print("Scrolling to section: \(section) at offset: \(offset)")
            // Прокручуємо до потрібної позиції з анімацією
            scrollView.setContentOffset(CGPoint(x: 0, y: max(0, offset)), animated: true)
            // Скидаємо значення, щоб уникнути повторного скролінгу
            DispatchQueue.main.async {
                self.scrollToSection = nil
            }
        }
    }
    
    func makeCoordinator() -> ScrollViewCoordinator {
        return ScrollViewCoordinator(self)
    }
}

// Обгортка для визначення позиції групи меню
struct SectionPositionReader: View {
    let id: String
    @Binding var positions: [String: CGFloat]
    let content: AnyView
    
    var body: some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        // Зберігаємо Y-позицію в глобальних координатах
                        let frame = geo.frame(in: .global)
                        positions[id] = frame.minY
                        print("Section \(id) position: \(frame.minY)")
                    }
                }
            )
    }
}

// Модифікатор для додавання відстеження позиції
extension View {
    func trackSectionPosition(id: String, in positions: Binding<[String: CGFloat]>) -> some View {
        SectionPositionReader(id: id, positions: positions, content: AnyView(self))
    }
}

// Контент для скролінгу
struct ScrollableCoffeeShopContent: View {
    @Binding var scrollToSection: String?
    @Binding var sectionOffsets: [String: CGFloat]
    @Binding var currentScrollOffset: CGFloat
    let coffeeShop: CoffeeShop
    let viewModel: CoffeeShopDetailViewModel
    let headerHeight: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            // Розтягувана шапка з зображенням і накладеною інформацією
            StretchableHeaderView(coffeeShop: coffeeShop)
                .frame(height: 320)
                .trackSectionPosition(id: "top", in: $sectionOffsets)
            
            // Контент на основі стану завантаження
            if viewModel.isLoading {
                loadingView
            } else if viewModel.menuGroups.isEmpty {
                emptyStateView
            } else {
                // Меню кав'ярні - групи меню з ідентифікаторами
                ForEach(viewModel.menuGroups) { group in
                    MenuGroupView(group: group)
                        .trackSectionPosition(id: group.id, in: $sectionOffsets)
                        .padding(.vertical, 8)
                }
                .padding(.bottom, 16)
            }
        }
    }
    
    /// Показує індикатор завантаження
    private var loadingView: some View {
        ProgressView("Завантаження меню...")
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 40)
            .foregroundColor(Color("primaryText"))
    }
    
    /// Показує стан, коли немає даних
    private var emptyStateView: some View {
        Text("Меню недоступне")
            .font(.headline)
            .foregroundColor(Color("secondaryText"))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 40)
    }
}
