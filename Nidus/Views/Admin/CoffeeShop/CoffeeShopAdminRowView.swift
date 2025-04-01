import SwiftUI
import Kingfisher

struct CoffeeShopAdminRow: View {
    let coffeeShop: CoffeeShop
    let canManage: Bool
    let isSuperAdmin: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onAssignOwner: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Інформація про кав'ярню
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    // Логотип (зображення або заглушка)
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("inputField"))
                            .frame(width: 60, height: 60)
                        
                        if let logoUrl = coffeeShop.logoUrl, let url = URL(string: logoUrl) {
                            KFImage(url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color("primary"))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(coffeeShop.name)
                            .font(.headline)
                            .foregroundColor(Color("primaryText"))
                        
                        if let address = coffeeShop.address {
                            Text(address)
                                .font(.subheadline)
                                .foregroundColor(Color("secondaryText"))
                                .lineLimit(2)
                        }
                        
                        // Статус роботи (відкрито/закрито)
                        HStack(spacing: 6) {
                            Circle()
                                .fill(coffeeShop.isOpenBasedOnHours ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text(coffeeShop.isOpenBasedOnHours ? "Відкрито" : "Закрито")
                                .font(.caption)
                                .foregroundColor(Color("secondaryText"))
                            
                            Text("•")
                                .font(.caption)
                                .foregroundColor(Color("secondaryText"))
                            
                            Text(coffeeShop.getWorkingHoursForToday())
                                .font(.caption)
                                .foregroundColor(Color("secondaryText"))
                        }
                        
                        // Додаткова інформація
                        Text("ID: \(coffeeShop.id)")
                            .font(.caption)
                            .foregroundColor(Color("secondaryText"))
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    // Кнопки управління (якщо користувач має право)
                    if canManage {
                        Menu {
                            Button(action: onEdit) {
                                Label("Редагувати", systemImage: "pencil")
                            }
                            
                            if isSuperAdmin {
                                Button(action: onAssignOwner) {
                                    Label("Призначити власника", systemImage: "person.badge.shield.checkmark")
                                }
                            }
                            
                            Button(role: .destructive, action: onDelete) {
                                Label("Видалити", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.title3)
                                .foregroundColor(Color("secondaryText"))
                                .padding(8)
                                .background(Color("inputField").opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                }
                
                // Інформація про заклад і робочі години
                if let owner = coffeeShop.owner {
                    HStack {
                        Label(
                            title: {
                                Text("Власник: \(owner.fullName)")
                                    .font(.caption)
                                    .foregroundColor(Color("secondaryText"))
                            },
                            icon: {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                    .foregroundColor(Color("primary"))
                            }
                        )
                        
                        Spacer()
                    }
                } else if let ownerId = coffeeShop.ownerId {
                    HStack {
                        Label(
                            title: {
                                Text("Власник: ID \(ownerId)")
                                    .font(.caption)
                                    .foregroundColor(Color("secondaryText"))
                            },
                            icon: {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                    .foregroundColor(Color("primary"))
                            }
                        )
                        
                        Spacer()
                    }
                }
                
                HStack {
                    if coffeeShop.allowScheduledOrders {
                        Label("Приймає попередні замовлення", systemImage: "calendar.badge.clock")
                            .font(.caption)
                            .foregroundColor(Color("secondaryText"))
                    } else {
                        Label("Не приймає попередні замовлення", systemImage: "calendar.badge.exclamationmark")
                            .font(.caption)
                            .foregroundColor(Color("secondaryText"))
                    }
                    
                    Spacer()
                }
            }
            .padding()
        }
    }
}
