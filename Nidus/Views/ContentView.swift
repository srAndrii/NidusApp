//
//  ContentView.swift
//  Nidus
//
//  Created by Andrii Liakhovych on 3/29/25.
//

// Views/ContentView.swift
import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var viewModel = DIContainer.shared.makeHomeViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234), // Київ
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Карта
                Map(coordinateRegion: $region, annotationItems: viewModel.coffeeShops.filter { $0.coordinate != nil }) { shop in
                    MapAnnotation(coordinate: shop.coordinate!) {
                        Image(systemName: "cup.and.saucer.fill")
                            .foregroundColor(.brown)
                            .background(Circle().fill(.white).frame(width: 30, height: 30))
                            .padding(5)
                    }
                }
                .frame(height: UIScreen.main.bounds.height * 0.33)
                
                // Список кав'ярень
                List {
                    if viewModel.isLoading {
                        ProgressView("Завантаження...")
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if let error = viewModel.error {
                        Text("Помилка: \(error.localizedDescription)")
                            .foregroundColor(.red)
                    } else if viewModel.coffeeShops.isEmpty {
                        Text("Кав'ярні не знайдено")
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(viewModel.coffeeShops) { shop in
                            NavigationLink(destination: Text("Деталі кав'ярні \(shop.name)")) {
                                CoffeeShopRow(coffeeShop: shop)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Nidus")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await viewModel.loadCoffeeShops()
                }
            }
        }
    }
}

struct CoffeeShopRow: View {
    let coffeeShop: CoffeeShop
    
    var body: some View {
        HStack {
            Image(systemName: "cup.and.saucer.fill")
                .font(.title)
                .foregroundColor(.brown)
                .frame(width: 50, height: 50)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(coffeeShop.name)
                    .font(.headline)
                
                if let address = coffeeShop.address {
                    Text(address)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                if let distance = coffeeShop.distance {
                    Text(formatDistance(distance))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))м"
        } else {
            let kilometers = distance / 1000
            return String(format: "%.1f км", kilometers)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
