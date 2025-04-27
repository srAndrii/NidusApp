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
            
            VStack(spacing: 0) {
                // Карта у вигляді картки з заокругленнями
                ZStack(alignment: .topTrailing) {
                    // Карта
                    if #available(iOS 18.0, *) {
                        Map(position: Binding(
                            get: { MapCameraPosition.region(region) },
                            set: { _ in }
                        )) {
                            ForEach(viewModel.coffeeShops.filter { $0.coordinate != nil }) { shop in
                                Marker(shop.name, coordinate: shop.coordinate!)
                                    .tint(Color("primary"))
                            }
                        }
                        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll, showsTraffic: false))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .frame(height: UIScreen.main.bounds.height * 0.33)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    } else {
                        Map(coordinateRegion: $region, annotationItems: viewModel.coffeeShops.filter { $0.coordinate != nil }) { shop in
                            MapMarker(coordinate: shop.coordinate!, tint: Color("primary"))
                        }
                        .preferredColorScheme(.dark)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .frame(height: UIScreen.main.bounds.height * 0.33)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.05))
                        )
                    }
                    
                    // Кнопка пошуку (зліва зверху)
                    Button(action: {
                        // Дія для переходу на екран пошуку
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundColor(Color("primary"))
                            .padding(5)
                            .background(Circle().fill(Color.white.opacity(0.25)))
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 24)
                    .padding(.top, 24)
                    .zIndex(1)
                    
                    // Кнопка для центрування на поточному місцезнаходженні
                    Button(action: {
                        // Центрувати мапу на поточному місцезнаходженні
                    }) {
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 25))
                            .foregroundColor(Color("primary"))
                            .background(Circle().fill(Color.white.opacity(0.8)))
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                    }
                    .padding(.trailing, 24)
                    .padding(.top, 24)
                }
                
                // Список кав'ярень
                if viewModel.isLoading {
                    ProgressView("Завантаження...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                    
                    Spacer()
                } else if viewModel.coffeeShops.isEmpty {
                    // Демо-дані для відображення
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(mockCoffeeShops) { shop in
                                CoffeeShopRow(coffeeShop: shop)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } else {
                    // Реальні дані
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.coffeeShops) { shop in
                                CoffeeShopRow(coffeeShop: shop)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadCoffeeShops()
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
