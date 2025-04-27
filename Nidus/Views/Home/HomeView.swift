//
//  HomeView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

import SwiftUI
import MapKit
import Kingfisher

struct HomeView: View {
    @StateObject private var viewModel = DIContainer.shared.makeHomeViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234), // Київ
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Базовий фон
            Group {
                if colorScheme == .light {
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("nidusCoolGray").opacity(0.9),
                                Color("nidusLightBlueGray").opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("nidusCoolGray").opacity(0.15),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color("nidusCoolGray").opacity(0.2)
                            ]),
                            center: .bottomTrailing,
                            startRadius: UIScreen.main.bounds.width * 0.2,
                            endRadius: UIScreen.main.bounds.width
                        )
                    }
                } else {
                    Color("backgroundColor")
                }
            }
            .edgesIgnoringSafeArea(.all)
            
            // Логотип як фон
            Image("Logo")
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
                .frame(width: UIScreen.main.bounds.width * 0.7)
                .saturation(1.5)
                .opacity(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Основний контент
            VStack(spacing: 0) {
                // Карта у верхній частині екрану
                Map(coordinateRegion: $region)
                    .cornerRadius(20)
                    .frame(height: UIScreen.main.bounds.height * 0.3)
                    .padding(.horizontal, 0)
                    .padding(.top, 0)
                
                // Список кав'ярень
                ScrollView {
                    VStack(spacing: 12) { // Збільшуємо відступи між карточками
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 100)
                                .padding()
                        } else if !viewModel.coffeeShops.isEmpty {
                            ForEach(viewModel.coffeeShops, id: \.id) { coffeeShop in
                                CoffeeShopRow(coffeeShop: coffeeShop)
                                    .padding(.horizontal)
                            }
                        } else {
                            // Показуємо мокові дані тільки якщо немає реальних даних
                            ForEach(mockCoffeeShops, id: \.id) { coffeeShop in
                                CoffeeShopRow(coffeeShop: coffeeShop)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
            .padding(.top, 1) // Невеликий відступ від верхньої SafeArea
            .onAppear {
                // Завантажуємо дані з сервера при появі екрану
                Task {
                    await viewModel.loadCoffeeShops()
                }
            }
        }
    }
    
    // Демо-дані для відображення, коли сервер ще не доступний
    private var mockCoffeeShops: [CoffeeShop] = [
        CoffeeShop(
            id: "mock-1",
            name: "Bean Haven",
            address: "вул. Хрещатик 15, Київ",
            logoUrl: nil,
            ownerId: nil,
            allowScheduledOrders: true,
            minPreorderTimeMinutes: 15,
            maxPreorderTimeMinutes: 120,
            workingHours: ["1": WorkingHoursPeriod(open: "08:00", close: "22:00", isClosed: false)],
            createdAt: Date(),
            updatedAt: Date(),
            distance: 350
        ),
        CoffeeShop(
            id: "mock-2",
            name: "Coffee Bloom",
            address: "вул. Льва Толстого 9, Київ",
            logoUrl: nil,
            ownerId: nil,
            allowScheduledOrders: true,
            minPreorderTimeMinutes: 15,
            maxPreorderTimeMinutes: 120,
            workingHours: ["1": WorkingHoursPeriod(open: "09:00", close: "21:00", isClosed: false)],
            createdAt: Date(),
            updatedAt: Date(),
            distance: 750
        ),
        CoffeeShop(
            id: "mock-3",
            name: "Morning Brew",
            address: "вул. Саксаганського 22, Київ",
            logoUrl: nil,
            ownerId: nil,
            allowScheduledOrders: true,
            minPreorderTimeMinutes: 15,
            maxPreorderTimeMinutes: 120,
            workingHours: ["1": WorkingHoursPeriod(open: "07:30", close: "20:00", isClosed: false)],
            createdAt: Date(),
            updatedAt: Date(),
            distance: 1200
        ),
        CoffeeShop(
            id: "mock-4",
            name: "Espresso Lane",
            address: "вул. Велика Васильківська 45, Київ",
            logoUrl: nil,
            ownerId: nil,
            allowScheduledOrders: true,
            minPreorderTimeMinutes: 15,
            maxPreorderTimeMinutes: 120,
            workingHours: ["1": WorkingHoursPeriod(open: "08:30", close: "22:30", isClosed: false)],
            createdAt: Date(),
            updatedAt: Date(),
            distance: 2500
        ),
        CoffeeShop(
            id: "mock-5",
            name: "Caffeine Corner",
            address: "вул. Хрещатик 15, Київ",
            logoUrl: nil,
            ownerId: nil,
            allowScheduledOrders: true,
            minPreorderTimeMinutes: 15,
            maxPreorderTimeMinutes: 120,
            workingHours: ["1": WorkingHoursPeriod(open: "08:00", close: "22:00", isClosed: false)],
            createdAt: Date(),
            updatedAt: Date(),
            distance: 350
        ),
        CoffeeShop(
            id: "mock-6",
            name: "Aroma Cafe",
            address: "вул. Льва Толстого 9, Київ",
            logoUrl: nil,
            ownerId: nil,
            allowScheduledOrders: true,
            minPreorderTimeMinutes: 15,
            maxPreorderTimeMinutes: 120,
            workingHours: ["1": WorkingHoursPeriod(open: "09:00", close: "21:00", isClosed: false)],
            createdAt: Date(),
            updatedAt: Date(),
            distance: 750
        ),
        CoffeeShop(
            id: "mock-7",
            name: "Daily Grind",
            address: "вул. Хрещатик 15, Київ",
            logoUrl: nil,
            ownerId: nil,
            allowScheduledOrders: true,
            minPreorderTimeMinutes: 15,
            maxPreorderTimeMinutes: 120,
            workingHours: ["1": WorkingHoursPeriod(open: "08:00", close: "22:00", isClosed: false)],
            createdAt: Date(),
            updatedAt: Date(),
            distance: 350
        ),
        CoffeeShop(
            id: "mock-8",
            name: "Urban Beans",
            address: "вул. Льва Толстого 9, Київ",
            logoUrl: nil,
            ownerId: nil,
            allowScheduledOrders: true,
            minPreorderTimeMinutes: 15,
            maxPreorderTimeMinutes: 120,
            workingHours: ["1": WorkingHoursPeriod(open: "09:00", close: "21:00", isClosed: false)],
            createdAt: Date(),
            updatedAt: Date(),
            distance: 750
        ),
    ]
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        // Для превью додаємо NavigationView
        NavigationView {
            HomeView()
        }
    }
}
