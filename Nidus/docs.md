# Документація модулів Order та Payment

## Огляд системи

Система складається з двох основних модулів:
- **Order Module** - управління замовленнями
- **Payment Module** - обробка платежів через MonoPay

## Статуси замовлень

```typescript
enum OrderStatus {
    CREATED = 'created',      // Створено
    ACCEPTED = 'accepted',    // Прийнято кав'ярнею
    READY = 'ready',         // Готово до видачі
    COMPLETED = 'completed', // Завершено
    CANCELLED = 'cancelled'  // Скасовано
}
```

## Статуси платежів

```typescript
enum PaymentStatus {
    PENDING = 'pending',         // Очікує оплати
    PROCESSING = 'processing',   // В процесі
    COMPLETED = 'completed',     // Завершено
    FAILED = 'failed',          // Не вдалось
    CANCELLED = 'cancelled',    // Скасовано
    REFUNDED = 'refunded'       // Повернено
}
```

---

## Order Module API

### 1. Валідація замовлення
```http
POST /orders/validate
```

**Опис**: Перевіряє валідність замовлення без його створення

**Тіло запиту**:
```json
{
  "coffeeShopId": "uuid",
  "items": [
    {
      "menuItemId": "uuid",
      "quantity": 2,
      "customization": {
        "selectedSize": "large",
        "selectedIngredients": {
          "sugar": 2,
          "milk": 1
        },
        "selectedOptions": {
          "syrup": [
            {
              "choiceId": "vanilla",
              "quantity": 1
            }
          ]
        }
      }
    }
  ],
  "comment": "Без цукру",
  "scheduledFor": "2025-06-01T14:30:00Z"
}
```

**Відповідь**:
```json
{
  "isValid": true,
  "items": [
    {
      "menuItemId": "uuid",
      "name": "Капучино",
      "basePrice": 45.00,
      "calculatedPrice": 52.00,
      "isAvailable": true,
      "validationErrors": []
    }
  ],
  "totalAmount": 104.00,
  "errors": []
}
```

### 2. Створення замовлення з оплатою
```http
POST /orders/create-with-payment
Authorization: Bearer <token>
```

**Опис**: Створює замовлення та ініціює платіж через MonoPay

**Тіло запиту**: Таке ж як в `/validate`

**Відповідь**:
```json
{
  "orderId": "uuid",
  "orderNumber": "CAF-250601-001",
  "status": "created",
  "totalAmount": 104.00,
  "paymentUrl": "https://pay.mono.ua/invoice_id",
  "paymentId": "uuid",
  "expiresAt": "2025-06-01T15:00:00Z"
}
```

### 3. Мої активні замовлення
```http
GET /orders/my?status[]=created&status[]=accepted&page=1&limit=10
Authorization: Bearer <token>
```

**Query параметри**:
- `status[]` - фільтр за статусами
- `page` - номер сторінки (за замовчуванням 1)
- `limit` - кількість елементів (за замовчуванням 10)
- `startDate` - дата початку пошуку
- `endDate` - дата кінця пошуку

### 4. Історія замовлень
```http
GET /orders/my/history?page=1&limit=10
Authorization: Bearer <token>
```

### 5. Деталі замовлення
```http
GET /orders/:id
Authorization: Bearer <token>
```

**Відповідь**:
```json
{
  "id": "uuid",
  "orderNumber": "CAF-250601-001",
  "status": "created",
  "totalAmount": 104.00,
  "isPaid": true,
  "comment": "Без цукру",
  "createdAt": "2025-06-01T14:00:00Z",
  "updatedAt": "2025-06-01T14:05:00Z",
  "scheduledFor": "2025-06-01T14:30:00Z",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "firstName": "Іван",
    "lastName": "Петренко"
  },
  "items": [
    {
      "id": "uuid",
      "menuItemId": "uuid",
      "name": "Капучино",
      "basePrice": 45.00,
      "finalPrice": 52.00,
      "quantity": 2,
      "sizeName": "Великий",
      "customizationSummary": "Розмір: Великий | Опції: Ванільний сироп x1"
    }
  ]
}
```

### 6. Статус оплати замовлення
```http
GET /orders/:id/payment-status
Authorization: Bearer <token>
```

**Відповідь**:
```json
{
  "orderId": "uuid",
  "paymentId": "uuid",
  "status": "completed",
  "paidAmount": 104.00,
  "isPaid": true,
  "paymentUrl": "https://pay.mono.ua/invoice_id"
}
```

### 7. Оновлення статусу замовлення
```http
PATCH /orders/:id/status
Authorization: Bearer <token>
Roles: coffee_shop_owner, cashier, superadmin
```

**Тіло запиту**:
```json
{
  "status": "accepted",
  "comment": "Замовлення прийнято в роботу"
}
```

### 8. Повторна ініціація оплати
```http
POST /orders/:id/retry-payment
Authorization: Bearer <token>
```

**Відповідь**: Така ж як у `/create-with-payment`

### 9. Скасування замовлення
```http
PATCH /orders/:id/cancel
Authorization: Bearer <token>
```

**Логіка скасування**:
- **Клієнти** можуть скасовувати тільки замовлення у статусах `CREATED` і `ACCEPTED`
- **Власники кав'ярні, касири, адміни** можуть скасовувати в будь-якому статусі
- Якщо замовлення оплачене - автоматично ініціюється повернення коштів
- Якщо платіж в статусі `PENDING` - він просто скасовується

### 10. Замовлення кав'ярні
```http
GET /orders/coffee-shop/:coffeeShopId?status[]=created&page=1&limit=10
Authorization: Bearer <token>
Roles: coffee_shop_owner, cashier, superadmin
```

### 11. Активні замовлення кав'ярні
```http
GET /orders/coffee-shop/:coffeeShopId/active
Authorization: Bearer <token>
Roles: coffee_shop_owner, cashier, superadmin
```

### 12. Статистика замовлень
```http
GET /orders/coffee-shop/:coffeeShopId/stats?period=week&startDate=2025-06-01&endDate=2025-06-07
Authorization: Bearer <token>
Roles: coffee_shop_owner, superadmin
```

**Query параметри**:
- `period` - day/week/month
- `startDate` - початкова дата
- `endDate` - кінцева дата

**Відповідь**:
```json
{
  "period": "week",
  "dateRange": {
    "start": "2025-06-01T00:00:00Z",
    "end": "2025-06-07T23:59:59Z"
  },
  "totalOrders": 45,
  "completedOrders": 42,
  "cancelledOrders": 3,
  "totalRevenue": 2340.50,
  "averageOrderValue": 55.72,
  "statusDistribution": {
    "completed": 42,
    "cancelled": 3
  },
  "popularItems": [
    {
      "id": "uuid",
      "name": "Капучино",
      "count": 25,
      "revenue": 1250.00
    }
  ]
}
```

### 13. Синхронізація з платежем
```http
PATCH /orders/:id/sync-with-payment
Authorization: Bearer <token>
Roles: superadmin, coffee_shop_owner
```

### 14. Синхронізація статусу платежу
```http
POST /orders/:id/sync-with-payment-status
Authorization: Bearer <token>
```

### 15. Скасування після повернення коштів
```http
PATCH /orders/:id/cancel-after-refund
Authorization: Bearer <token>
```

### 16. Всі замовлення (адмін)
```http
GET /orders/admin/all?page=1&limit=10
Authorization: Bearer <token>
Roles: superadmin
```

### 17. Видалення замовлення (адмін)
```http
DELETE /orders/:id
Authorization: Bearer <token>
Roles: superadmin
```

### 18. Активні замовлення касира
```http
GET /orders/cashier/active
Authorization: Bearer <token>
Roles: cashier
```

---

## Payment Module API

### 1. Список платежів користувача
```http
GET /payments?limit=10&offset=0
Authorization: Bearer <token>
```

**Query параметри**:
- `limit` - максимальна кількість записів (за замовчуванням 10)
- `offset` - зміщення для пагінації (за замовчуванням 0)

**Відповідь**:
```json
[
  {
    "id": "uuid",
    "externalId": "invoice_12345",
    "userId": "uuid",
    "orderId": "uuid",
    "status": "completed",
    "amount": 10400,
    "currency": "UAH",
    "description": "Оплата замовлення #CAF-250601-001",
    "createdAt": "2025-06-01T14:00:00Z",
    "completedAt": "2025-06-01T14:05:00Z"
  }
]
```

### 2. Платежі за замовленням
```http
GET /payments/order/:orderId
Authorization: Bearer <token>
```

### 3. Платежі кав'ярні
```http
GET /payments/coffee-shop/:coffeeShopId?limit=10&offset=0
Authorization: Bearer <token>
```

### 4. Деталі платежу
```http
GET /payments/:id
Authorization: Bearer <token>
```

**Відповідь**:
```json
{
  "id": "uuid",
  "externalId": "invoice_12345",
  "userId": "uuid",
  "orderId": "uuid",
  "coffeeShopId": "uuid",
  "status": "completed",
  "provider": "mono_pay",
  "amount": 10400,
  "currency": "UAH",
  "description": "Оплата замовлення #CAF-250601-001",
  "redirectUrl": "https://yourapp.com/payment-success",
  "paymentUrl": "https://pay.mono.ua/invoice_12345",
  "platformFee": 1040,
  "sellerAmount": 9360,
  "isSplitCompleted": true,
  "createdAt": "2025-06-01T14:00:00Z",
  "updatedAt": "2025-06-01T14:05:00Z",
  "completedAt": "2025-06-01T14:05:00Z",
  "metadata": {
    "isSplitPayment": true,
    "splitDetails": {
      "platformFee": 1040,
      "sellerAmount": 9360,
      "agentFeePercent": 10
    },
    "monoPayResponse": {
      "invoiceId": "invoice_12345",
      "pageUrl": "https://pay.mono.ua/invoice_12345"
    }
  }
}
```

### 5. Перевірка статусу платежу
```http
PATCH /payments/:id/check-status
Authorization: Bearer <token>
```

**Опис**: Синхронізує статус платежу з MonoPay API

**Відповідь**: Оновлена інформація про платіж

### 6. Скасування платежу
```http
PATCH /payments/:id/cancel?reason=Клієнт передумав
Authorization: Bearer <token>
```

**Query параметри**:
- `reason` - причина скасування (опціонально)

**Логіка скасування платежу**:
- Якщо статус `COMPLETED` - ініціюється повернення коштів (refund)
- Якщо статус `PENDING/PROCESSING` - платіж скасовується без списання
- MonoPay invoice скасовується через API

### 7. Webhook від MonoPay
```http
POST /payments/webhook/mono
X-Sign: <signature>
Content-Type: application/json
```

**Заголовки**:
- `X-Sign` - ECDSA підпис для верифікації

**Тіло запиту**:
```json
{
  "invoiceId": "invoice_12345",
  "status": "success",
  "amount": 10400,
  "ccy": 980,
  "finalAmount": 10400,
  "createdDate": "2025-06-01T14:00:00Z",
  "modifiedDate": "2025-06-01T14:05:00Z",
  "reference": "payment_uuid",
  "customer": {
    "name": "Іван Петренко",
    "email": "user@example.com",
    "phone": "+380123456789"
  }
}
```

**Відповідь**:
```json
{
  "success": true
}
```

### 8. Тест обробки rawBody
```http
GET /payments/webhook/test
```

**Опис**: Діагностичний endpoint для перевірки обробки rawBody

### 9. Синхронізація статусу замовлення
```http
POST /payments/:id/sync-order-status
Authorization: Bearer <token>
```

**Опис**: Синхронізує статус замовлення з поточним статусом платежу

### 10. Повернені платежі (адмін)
```http
GET /payments/admin/refunded
Authorization: Bearer <token>
Roles: superadmin
```

**Відповідь**: Список всіх платежів зі статусом `REFUNDED`

---

## Сценарії скасування

### Сценарій 1: Клієнт скасовує неприйняте замовлення

**Умови**: 
- Замовлення в статусі `CREATED` 
- Замовлення оплачене (платіж `COMPLETED`)
- Клієнт є власником замовлення

**Послідовність дій**:
1. **Запит**: `PATCH /orders/:id/cancel`
2. **Перевірка прав**: Система перевіряє, що клієнт може скасувати замовлення в статусі `CREATED`/`ACCEPTED`
3. **Пошук платежу**: Знаходить пов'язаний платіж
4. **Ініціація refund**: Якщо платіж `COMPLETED`, викликає `PaymentService.cancelPayment()` з типом "refund"
5. **MonoPay API**: `POST /merchant/invoice/cancel` з причиною повернення коштів
6. **Оновлення статусів**: 
   - Платіж → `REFUNDED`
   - Замовлення → `CANCELLED`
7. **Webhook**: MonoPay надішле webhook з статусом `REVERSED`
8. **Сповіщення**: WebSocket сповіщення клієнту та персоналу кав'ярні

**Результат**: Повна сума повертається на картку клієнта протягом 1-3 робочих днів

### Сценарій 2: Власник кав'ярні скасовує замовлення

**Умови**: 
- Будь-який статус замовлення крім `CANCELLED`
- Користувач має роль `coffee_shop_owner` або `cashier`

**Послідовність дій**:
1. **Запит**: `PATCH /orders/:id/cancel`
2. **Перевірка прав**: Система перевіряє, що користувач є власником кав'ярні або касиром
3. **Аналогічна логіка**: Така ж як у Сценарії 1, але з розширеними правами
4. **Додаткове логування**: Причина скасування з боку кав'ярні записується в аудит-лог

**Особливості**: 
- Власники кав'ярні можуть скасувати навіть замовлення в статусі `READY` або `COMPLETED`
- При скасуванні `COMPLETED` замовлення також ініціюється refund

### Сценарій 3: Закриття WebView без оплати

**Умови**: 
- Замовлення створене через `POST /orders/create-with-payment`
- Платіж в статусі `PENDING` 
- Клієнт закрив WebView MonoPay без введення даних карти

**Послідовність дій**:
1. **Поточний стан**: 
   - Замовлення: `CREATED`, `isPaid: false`
   - Платіж: `PENDING`
   - MonoPay invoice: активний, але не оплачений
2. **Запит клієнта**: `PATCH /orders/:id/cancel`
3. **Перевірка платежу**: Система виявляє платіж у статусі `PENDING`
4. **Скасування invoice**: MonoPay API `POST /merchant/invoice/cancel` (НЕ refund!)
5. **Оновлення статусів**:
   - Платіж → `CANCELLED`
   - Замовлення → `CANCELLED`
6. **Без фінансових операцій**: Гроші НЕ списуються і НЕ повертаються

**Важливо**: 
- Це найпростіший сценарій - просто скасовується можливість оплати
- MonoPay не намагається обробити жодних фінансових операцій
- Клієнт може створити нове замовлення без обмежень

### Сценарій 4: Автоматичне скасування після expiry

**Умови**: 
- Платіж в статусі `PENDING`
- MonoPay invoice прострочений (зазвичай 30 хвилин)

**Послідовність дій**:
1. **MonoPay webhook**: Надходить з статусом `EXPIRED`
2. **Автоматичне оновлення**: 
   - Платіж → `FAILED`
   - Замовлення залишається `CREATED` але з `isPaid: false`
3. **Можливість повторної оплати**: Клієнт може використати `POST /orders/:id/retry-payment`

---

## Права доступу та ролі

### Клієнти (role: buyer)
**Замовлення**:
- ✅ Створення замовлень
- ✅ Перегляд власних замовлень
- ✅ Скасування замовлень у статусах `CREATED`, `ACCEPTED`
- ❌ Скасування замовлень у статусах `READY`, `COMPLETED`

**Платежі**:
- ✅ Перегляд власних платежів
- ✅ Скасування власних платежів (з обмеженнями)
- ✅ Повторна ініціація оплати

### Власники кав'ярні (role: coffee_shop_owner)
**Замовлення**:
- ✅ Перегляд замовлень своїх кав'ярень
- ✅ Зміна статусу замовлень
- ✅ Скасування будь-яких замовлень своїх кав'ярень
- ✅ Перегляд статистики

**Платежі**:
- ✅ Перегляд платежів своїх кав'ярень
- ✅ Синхронізація статусів платежів

### Касири (role: cashier)
**Замовлення**:
- ✅ Перегляд замовлень прикріплених кав'ярень
- ✅ Зміна статусу замовлень
- ✅ Скасування замовлень прикріплених кав'ярень

**Обмеження**: Доступ тільки до кав'ярень, до яких касир прикріплений через `CashierAssignment`

### Суперадміни (role: superadmin)
**Повний доступ**:
- ✅ Всі операції з замовленнями
- ✅ Всі операції з платежами
- ✅ Видалення замовлень
- ✅ Доступ до адміністративної аналітики

---

## WebSocket сповіщення

### Події що тригерять сповіщення:

1. **Успішна оплата замовлення**:
   ```json
   {
     "type": "order_status_update",
     "orderId": "uuid",
     "status": "created",
     "message": "Замовлення успішно оплачено"
   }
   ```

2. **Зміна статусу замовлення**:
   ```json
   {
     "type": "order_status_update",
     "orderId": "uuid",
     "previousStatus": "created",
     "newStatus": "accepted",
     "comment": "Замовлення прийнято в роботу"
   }
   ```

3. **Нове замовлення для персоналу**:
   ```json
   {
     "type": "new_order",
     "orderId": "uuid",
     "orderNumber": "CAF-250601-001",
     "totalAmount": 104.00,
     "items": [
       {
         "name": "Капучино",
         "quantity": 2,
         "customizationSummary": "Великий, Ванільний сироп"
       }
     ]
   }
   ```

4. **Скасування замовлення**:
   ```json
   {
     "type": "order_cancelled",
     "orderId": "uuid",
     "reason": "Клієнт передумав"
   }
   ```

### Підписка на сповіщення:
- **Клієнти**: отримують сповіщення про власні замовлення
- **Персонал кав'ярні**: отримують сповіщення про замовлення своїх кав'ярень
- **Адміни**: можуть підписатися на всі сповіщення

---

## Split-платежі та комісії

### Принцип роботи:
1. **Налаштування комісії**: Кожна кав'ярня має індивідуальну комісію в `coffeeShop.metadata.platformFeePercent`
2. **Автоматичний розрахунок**: При створенні платежу система автоматично обчислює:
   - `platformFee` - комісія платформи
   - `sellerAmount` - сума для кав'ярні
3. **MonoPay розподіл**: Використовується параметр `agentFeePercent` для автоматичного розподілу коштів

### Приклад розрахунку:
```
Сума замовлення: 100.00 грн
Комісія кав'ярні: 10%
───────────────────────
Платформа отримує: 10.00 грн
Кав'ярня отримує: 90.00 грн
```

### Метадані платежу:
```json
{
  "isSplitPayment": true,
  "splitDetails": {
    "platformFee": 1000,  // 10.00 грн в копійках
    "sellerAmount": 9000, // 90.00 грн в копійках
    "agentFeePercent": 10
  }
}
```

---

## Обробка помилок

### Типові помилки та їх обробка:

#### 400 Bad Request
```json
{
  "statusCode": 400,
  "message": "Невалідне замовлення",
  "errors": [
    "Товар з ID \"uuid\" не знайдено",
    "Товар \"Капучино\" наразі недоступний"
  ]
}
```

#### 403 Forbidden
```json
{
  "statusCode": 403,
  "message": "У вас немає прав для скасування цього замовлення"
}
```

#### 404 Not Found
```json
{
  "statusCode": 404,
  "message": "Замовлення з ID \"uuid\" не знайдено"
}
```

#### 500 Internal Server Error
```json
{
  "statusCode": 500,
  "message": "Не вдалося створити платіж через MonoPay: API error"
}
```

---

## Моніторинг та аудит

### Аудит-логування:
Система веде детальні логи всіх фінансових операцій:

```
[AUDIT] Успішно оброблено платіж: paymentId=uuid, invoiceId=invoice_123, 
status=success, amount=104.00 грн, orderId=uuid, webhookHash=sha256_hash
```

### Ключові метрики:
- Кількість успішних/неуспішних платежів
- Середній час обробки платежу
- Кількість refund операцій
- Відсоток скасованих замовлень по кав'ярнях

### Сповіщення про критичні помилки:
- Невалідні webhook від MonoPay
- Помилки при обробці refund
- Невідповідності між статусами замовлень та платежів

---

## Тестування

### Тестові сценарії:

1. **Повний цикл замовлення**:
   - Створення → Оплата → Прийняття → Готовність → Завершення

2. **Скасування на різних етапах**:
   - До оплати → після оплати → після прийняття

3. **Обробка webhook**:
   - Успішна оплата → невдала оплата → refund

4. **Тестування split-платежів**:
   - Перевірка правильності розподілу коштів

### MonoPay тестове середовище:
Для тестування використовуйте:
- `MONO_PAY_TEST_MODE=true`
- Тестові токени та URL з документації MonoPay
- Фіктивні номери карток для тестування різних сценаріїв

---

## Швидкий старт

### 1. Створення замовлення з оплатою:
```bash
curl -X POST http://localhost:3000/orders/create-with-payment \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "coffeeShopId": "uuid",
    "items": [
      {
        "menuItemId": "uuid",
        "quantity": 1
      }
    ]
  }'
```

### 2. Перевірка статусу:
```bash
curl -X GET http://localhost:3000/orders/:orderId/payment-status \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 3. Скасування замовлення:
```bash
curl -X PATCH http://localhost:3000/orders/:orderId/cancel \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Ця документація покриває всі основні аспекти роботи з модулями Order та Payment, включаючи детальний опис сценаріїв скасування та обробки платежів.
