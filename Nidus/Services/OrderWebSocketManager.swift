import Foundation
import SocketIO
import Combine

final class OrderWebSocketManager: ObservableObject {
    static let shared = OrderWebSocketManager()
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    
    @Published var isConnected = false
    @Published var connectionError: String?
    
    private let orderStatusUpdateSubject = PassthroughSubject<OrderStatusUpdateData, Never>()
    var orderStatusUpdatePublisher: AnyPublisher<OrderStatusUpdateData, Never> {
        orderStatusUpdateSubject.eraseToAnyPublisher()
    }
    
    private init() {}
    
    struct OrderStatusUpdateData {
        let orderId: String
        let newStatus: OrderStatus
        let previousStatus: OrderStatus?
        let orderNumber: String?
        let coffeeShopId: String?
        let comment: String?
        let updatedAt: Date?
    }
    
    func connect(userId: String) {
        disconnect()
        
        // Завжди підключаємося до production сервера
        let socketURL = URL(string: "wss://nidus-production.up.railway.app")!
        print("📡 WebSocket: Connecting to production server: \(socketURL.absoluteString)")
        print("👤 WebSocket: User ID: \(userId)")
        
        let config: SocketIOClientConfiguration = [
            .log(true),
            .compress,
            .forceWebsockets(false), // Дозволяємо polling як fallback
            .reconnects(true),
            .reconnectAttempts(5),
            .reconnectWait(3),
            .connectParams(["userId": userId]) // Передаємо userId замість JWT токена
        ]
        
        manager = SocketManager(socketURL: socketURL, config: config)
        socket = manager?.defaultSocket
        
        // Встановлюємо обробник успішного підключення
        socket?.on(clientEvent: .connect) { [weak self] data, ack in
            print("✅ WebSocket: Connected successfully")
            print("📡 Socket ID: \(self?.socket?.sid ?? "unknown")")
            print("📡 Connect data: \(data)")
            
            // Відправляємо join подію для клієнта
            print("🔗 WebSocket: Sending join event...")
            self?.socket?.emit("join", ["userId": userId])
            
            DispatchQueue.main.async {
                self?.isConnected = true
                self?.connectionError = nil
            }
        }
        
        setupEventHandlers()
        socket?.connect()
    }
    
    func disconnect() {
        print("📡 WebSocket: Disconnecting")
        socket?.disconnect()
        socket?.removeAllHandlers()
        socket = nil
        manager = nil
        isConnected = false
        connectionError = nil
    }
    
    private func setupEventHandlers() {
        
        socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("🔌 WebSocket: Disconnected")
            DispatchQueue.main.async {
                self?.isConnected = false
            }
        }
        
        socket?.on(clientEvent: .error) { [weak self] data, ack in
            print("❌ WebSocket Error: \(data)")
            DispatchQueue.main.async {
                self?.connectionError = "WebSocket connection error"
                self?.isConnected = false
            }
        }
        
        socket?.on(clientEvent: .reconnect) { data, ack in
            print("🔄 WebSocket: Reconnected")
        }
        
        socket?.on(clientEvent: .reconnectAttempt) { data, ack in
            print("🔄 WebSocket: Reconnection attempt \(data)")
        }
        
        socket?.on("connect_error") { [weak self] data, ack in
            print("❌ WebSocket Connection Error: \(data)")
            print("❌ Error details:")
            for (index, item) in data.enumerated() {
                print("   [\(index)]: \(item)")
                if let errorDict = item as? [String: Any] {
                    for (key, value) in errorDict {
                        print("      \(key): \(value)")
                    }
                }
            }
            
            let errorMessage: String
            if let error = data.first as? [String: Any],
               let message = error["message"] as? String {
                errorMessage = message
            } else if let stringError = data.first as? String {
                errorMessage = stringError
            } else {
                errorMessage = "Unknown connection error: \(data)"
            }
            
            DispatchQueue.main.async {
                self?.connectionError = errorMessage
                self?.isConnected = false
            }
        }
        
        // Слухаємо підтвердження приєднання
        socket?.on("joined") { data, ack in
            print("🔗 WebSocket: Successfully joined: \(data)")
        }
        
        // Основна подія для оновлення статусу замовлень (для клієнтів)
        socket?.on("orderStatusUpdated") { [weak self] data, ack in
            print("📬 WebSocket: Received orderStatusUpdated event")
            print("📦 Data: \(data)")
            
            guard let orderData = data.first as? [String: Any] else {
                print("❌ WebSocket: Invalid orderStatusUpdated data format")
                return
            }
            
            self?.handleOrderStatusUpdate(orderData)
        }
        
        // Додаткова подія для нових замовлень (якщо потрібно)
        socket?.on("newOrderReceived") { data, ack in
            print("📨 WebSocket: Received newOrderReceived event: \(data)")
        }
        
        // Логуємо всі невідомі події
        socket?.onAny { event in
            print("🔍 WebSocket: Event '\(event.event)' with data: \(event.items)")
        }
    }
    
    private func handleOrderStatusUpdate(_ data: [String: Any]) {
        print("🔍 WebSocket: Parsing order status update data: \(data)")
        
        guard let orderId = data["orderId"] as? String else {
            print("❌ WebSocket: Missing orderId in order status update")
            return
        }
        
        // Сервер відправляє "status" замість "newStatus"
        guard let newStatusString = data["status"] as? String,
              let newStatus = OrderStatus(rawValue: newStatusString) else {
            print("❌ WebSocket: Missing or invalid status field: \(data["status"] ?? "nil")")
            return
        }
        
        let previousStatus: OrderStatus?
        if let prevStatusString = data["previousStatus"] as? String {
            previousStatus = OrderStatus(rawValue: prevStatusString)
        } else {
            previousStatus = nil
        }
        
        let updatedAt: Date?
        if let updatedAtString = data["updatedAt"] as? String {
            let formatter = ISO8601DateFormatter()
            updatedAt = formatter.date(from: updatedAtString)
        } else {
            updatedAt = nil
        }
        
        let updateData = OrderStatusUpdateData(
            orderId: orderId,
            newStatus: newStatus,
            previousStatus: previousStatus,
            orderNumber: data["orderNumber"] as? String,
            coffeeShopId: data["coffeeShopId"] as? String,
            comment: data["comment"] as? String,
            updatedAt: updatedAt
        )
        
        print("✅ WebSocket: Processing order status update")
        print("   Order ID: \(orderId)")
        print("   New Status: \(newStatus.rawValue)")
        print("   Previous Status: \(previousStatus?.rawValue ?? "none")")
        print("   Order Number: \(updateData.orderNumber ?? "none")")
        print("   Comment: \(updateData.comment ?? "none")")
        print("   Coffee Shop ID: \(updateData.coffeeShopId ?? "none")")
        
        DispatchQueue.main.async {
            self.orderStatusUpdateSubject.send(updateData)
            
            NotificationCenter.default.post(
                name: .init("OrderStatusUpdated"),
                object: nil,
                userInfo: [
                    "orderId": orderId,
                    "newStatus": newStatus,
                    "previousStatus": previousStatus as Any,
                    "orderNumber": updateData.orderNumber as Any,
                    "comment": updateData.comment as Any
                ]
            )
        }
    }
}