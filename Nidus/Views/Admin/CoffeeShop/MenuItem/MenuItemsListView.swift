import SwiftUI

struct MenuItemsListView: View {
    let menuGroup: MenuGroup
    @StateObject private var viewModel = MenuItemsViewModel()
    @State private var showingCreateSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var menuItemToDelete: (groupId: String, itemId: String, name: String)? = nil
    @State private var menuItemToEdit: MenuItem? = nil
    @State private var showCustomEditor = false
    @State private var useFullScreenEditor = true // Додаємо контроль для вибору типу редактора
    
    var body: some View {
        ZStack {
            Color("backgroundColor")
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                if viewModel.isLoading {
                    ProgressView("Завантаження...")
                        .padding()
                } else if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                } else if viewModel.menuItems.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "cup.and.saucer")
                            .font(.system(size: 60))
                            .foregroundColor(Color("secondaryText"))
                        
                        Text("Пункти меню відсутні")
                            .font(.headline)
                            .foregroundColor(Color("primaryText"))
                        
                        Text("Додайте перший пункт меню, натиснувши кнопку нижче")
                            .font(.subheadline)
                            .foregroundColor(Color("secondaryText"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(viewModel.menuItems) { item in
                                MenuItemRowWithNavigation(
                                    menuItem: item,
                                    menuGroup: menuGroup,
                                    viewModel: viewModel,
                                    useFullScreenEditor: useFullScreenEditor,
                                    onDelete: { groupId, itemId in
                                        menuItemToDelete = (groupId, itemId, item.name)
                                        showingDeleteConfirmation = true
                                    },
                                    onEditPressed: { menuItem in
                                        if useFullScreenEditor {
                                            // Для повноекранного редактора використовуємо NavigationLink
                                            menuItemToEdit = menuItem
                                        } else {
                                            // Для модального вікна
                                            menuItemToEdit = menuItem
                                            showCustomEditor = true
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            
            // Кнопка додавання пункту меню
            VStack {
                Spacer()
                
                Button(action: {
                    showingCreateSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.headline)
                        
                        Text("Додати пункт меню")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(Color("primary"))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .padding(.bottom, 20)
            }
            
            // Модальне вікно редагування (для непоноекранного режиму)
            if showCustomEditor, let menuItem = menuItemToEdit {
                CustomModalMenuItemEditor(
                    isPresented: $showCustomEditor,
                    menuGroup: menuGroup,
                    menuItem: menuItem,
                    viewModel: viewModel,
                    onUpdate: { updatedItem in
                        // Оновлюємо локальний список пунктів меню
                        if let index = viewModel.menuItems.firstIndex(where: { $0.id == updatedItem.id }) {
                            viewModel.menuItems[index] = updatedItem
                        }
                    }
                )
                .zIndex(100)
            }
            
            // Тост із повідомленням
            if viewModel.showSuccess {
                Toast(message: viewModel.successMessage, isShowing: $viewModel.showSuccess)
            }
        }
        .navigationTitle("\(menuGroup.name)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.loadMenuItems(groupId: menuGroup.id)
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            NavigationView {
                CreateMenuItemView(
                    menuGroup: menuGroup,
                    viewModel: viewModel
                )
            }
        }
        .alert("Видалення пункту меню", isPresented: $showingDeleteConfirmation) {
            Button("Скасувати", role: .cancel) {}
            Button("Видалити", role: .destructive) {
                if let itemToDelete = menuItemToDelete {
                    Task {
                        await viewModel.deleteMenuItem(
                            groupId: itemToDelete.groupId,
                            itemId: itemToDelete.itemId
                        )
                    }
                }
            }
        } message: {
            if let itemToDelete = menuItemToDelete {
                Text("Ви впевнені, що хочете видалити пункт меню '\(itemToDelete.name)'? Ця дія незворотна.")
            } else {
                Text("Ви впевнені, що хочете видалити цей пункт меню? Ця дія незворотна.")
            }
        }
    }
}

// Допоміжний компонент для рядка меню-айтема з навігацією
struct MenuItemRowWithNavigation: View {
    let menuItem: MenuItem
    let menuGroup: MenuGroup
    let viewModel: MenuItemsViewModel
    let useFullScreenEditor: Bool
    let onDelete: (String, String) -> Void
    let onEditPressed: (MenuItem) -> Void
    
    @State private var isAvailable: Bool
    @State private var isEditing: Bool = false
    
    init(menuItem: MenuItem, menuGroup: MenuGroup, viewModel: MenuItemsViewModel, useFullScreenEditor: Bool, onDelete: @escaping (String, String) -> Void, onEditPressed: @escaping (MenuItem) -> Void) {
        self.menuItem = menuItem
        self.menuGroup = menuGroup
        self.viewModel = viewModel
        self.useFullScreenEditor = useFullScreenEditor
        self.onDelete = onDelete
        self.onEditPressed = onEditPressed
        self._isAvailable = State(initialValue: menuItem.isAvailable)
    }
    
    var body: some View {
        ZStack {
            // Контент рядка меню-айтема
            MenuItemRowView(
                menuItem: menuItem,
                menuGroupId: menuGroup.id,
                viewModel: viewModel,
                onDelete: onDelete,
                onToggleAvailability: { groupId, itemId, available in
                    Task {
                        await viewModel.updateMenuItemAvailability(
                            groupId: groupId,
                            itemId: itemId,
                            available: available
                        )
                    }
                },
                onEdit: {item in
                    if useFullScreenEditor {
                        isEditing = true
                    } else {
                        onEditPressed(menuItem)
                    }
                }
            )
            .background(Color("cardColor"))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            .padding(.horizontal)
            
            // NavigationLink для повноекранного редактора
            if useFullScreenEditor {
                NavigationLink(
                    destination: FullScreenMenuItemEditor(
                        viewModel: viewModel,
                        menuGroup: menuGroup,
                        menuItem: menuItem
                    ),
                    isActive: $isEditing
                ) {
                    EmptyView()
                }
                .hidden()
            }
        }
    }
}

// Ваш існуючий компонент MenuItemRowView залишається без змін
struct MenuItemRowView: View {
    let menuItem: MenuItem
    let menuGroupId: String
    let onDelete: (String, String) -> Void
    let onToggleAvailability: (String, String, Bool) -> Void
    let onEdit: (MenuItem) -> Void
    @State private var isAvailable: Bool
    
    // Джерело даних
    @ObservedObject var viewModel: MenuItemsViewModel
    
    init(menuItem: MenuItem, menuGroupId: String, viewModel: MenuItemsViewModel, onDelete: @escaping (String, String) -> Void, onToggleAvailability: @escaping (String, String, Bool) -> Void, onEdit: @escaping (MenuItem) -> Void) {
        self.menuItem = menuItem
        self.menuGroupId = menuGroupId
        self.viewModel = viewModel
        self.onDelete = onDelete
        self.onToggleAvailability = onToggleAvailability
        self.onEdit = onEdit
        self._isAvailable = State(initialValue: menuItem.isAvailable)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Зображення пункту меню або заглушка
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("inputField"))
                    .frame(width: 60, height: 60)
                
                if let imageUrl = menuItem.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure(_), .empty:
                            Image(systemName: "fork.knife")
                                .font(.system(size: 20))
                                .foregroundColor(Color("primary"))
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 20))
                        .foregroundColor(Color("primary"))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(menuItem.name)
                    .font(.headline)
                    .foregroundColor(Color("primaryText"))
                
                if let description = menuItem.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(Color("secondaryText"))
                        .lineLimit(2)
                }
                
                // Показуємо, чи є кастомізація
                if (menuItem.ingredients != nil && !menuItem.ingredients!.isEmpty) ||
                   (menuItem.customizationOptions != nil && !menuItem.customizationOptions!.isEmpty) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption)
                            .foregroundColor(Color("primary"))
                        
                        Text("Можна кастомізувати")
                            .font(.caption)
                            .foregroundColor(Color("primary"))
                    }
                }
                
                // Ціна та перемикач доступності
                HStack(spacing: 8) {
                    Text(formatPrice(menuItem.price))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("primary"))
                    
                    Spacer()
                    
                    // Доступність - текстовий індикатор поруч з перемикачем
                    Text(isAvailable ? "Доступно" : "Недоступно")
                        .font(.caption)
                        .foregroundColor(isAvailable ? Color.green : Color.red)
                    
                    // Перемикач доступності
                    Toggle(isOn: $isAvailable) {
                        EmptyView()
                    }
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: Color("primary")))
                    .onChange(of: isAvailable) { oldValue, newValue in
                        if oldValue != newValue {
                            Task {
                                await onToggleAvailability(menuGroupId, menuItem.id, newValue)
                            }
                        }
                    }
                    .frame(width: 50)
                }
            }
            
            // Меню управління
            Menu {
                Button(action: {
                    onEdit(menuItem)
                }) {
                    Label("Редагувати", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: {
                    onDelete(menuGroupId, menuItem.id)
                }) {
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
        .padding(16)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit(menuItem)
        }
    }
    
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "UAH"
        formatter.currencySymbol = "₴"
        return formatter.string(from: price as NSDecimalNumber) ?? "\(price) ₴"
    }
}
