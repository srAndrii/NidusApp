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
                            ProgressView("Завантаження кав'ярень...")
                                .frame(maxWidth: .infinity, minHeight: 100)
                                .padding()
                        } else if !viewModel.coffeeShops.isEmpty {
                            ForEach(viewModel.coffeeShops, id: \.id) { coffeeShop in
                                CoffeeShopRow(coffeeShop: coffeeShop)
                                    .padding(.horizontal)
                            }
                        } else if let error = viewModel.error {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.orange)
                                
                                Text("Помилка завантаження")
                                    .font(.headline)
                                    .foregroundColor(Color("primaryText"))
                                
                                Text(error.localizedDescription)
                                    .font(.subheadline)
                                    .foregroundColor(Color("secondaryText"))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Button("Спробувати знову") {
                                    Task {
                                        await viewModel.loadCoffeeShops()
                                    }
                                }
                                .padding()
                                .background(Color("primary"))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .padding()
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "cup.and.saucer")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color("secondaryText"))
                                
                                Text("Кав'ярні не знайдено")
                                    .font(.headline)
                                    .foregroundColor(Color("primaryText"))
                                
                                Text("Спробуйте пізніше")
                                    .font(.subheadline)
                                    .foregroundColor(Color("secondaryText"))
                                
                                Button("Оновити") {
                                    Task {
                                        await viewModel.loadCoffeeShops()
                                    }
                                }
                                .padding()
                                .background(Color("primary"))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .padding()
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
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        // Для превью додаємо NavigationView
        NavigationView {
            HomeView()
        }
    }
}
