<!-- L0: Domain nouns — entities, value objects, aggregates, invariants, relations, events -->

# L1 — Доменная модель

> **Статус:** детальный справочник
> **Шаблон:** [`templates/domain.tpl.md`](../templates/domain.tpl.md)
> **Уровень выше:** [L0 — Конституция](L0-constitution.md)
> **Уровень ниже:** [L2 — BDD-сценарии](L2-bdd-scenarios.md)
> **Связь с L0:** каждая сущность и инвариант ОБЯЗАНЫ соответствовать Конституции.

---

## 1. Назначение

Доменная модель фиксирует **существительные** системы: сущности, значения, агрегаты, их отношения и инварианты. Если L0 отвечает на вопрос «что нельзя», то L1 отвечает на вопрос «что существует».

L1 отвечает на три вопроса:

1. *Какие сущности живут в домене и чем они идентифицируются?*
2. *Какие правила всегда истинны для этих сущностей (инварианты)?*
3. *Как сущности связаны между собой?*

L1 — это **структура**, не поведение. Поведение описывается на L2.

---

## 2. Что сюда входит

| Категория | Описание |
|---|---|
| **Entity / Сущность** | Объект с идентичностью, существующий во времени (`User`, `Order`) |
| **Value Object / Значение** | Объект без идентичности, определяемый атрибутами (`Money`, `Email`) |
| **Aggregate / Агрегат** | Кластер сущностей с единой границей консистентности и корнем |
| **Invariant / Инвариант** | Утверждение, истинное всегда для валидного состояния |
| **Relation / Отношение** | Связь между сущностями с кардинальностью и владением |
| **State / Состояние** | Допустимые состояния и переходы (state machine) |
| **Domain Event / Доменное событие** | Факт, произошедший в домене (`OrderPlaced`) |

### Что сюда НЕ входит

- Схемы БД, таблицы, индексы → код / миграции
- UI-формы, поля ввода → L2 или код
- Бизнес-процессы и шаги → L2
- Конкретные сообщения об ошибках → код
- HTTP/gRPC-эндпоинты → код / адаптеры
- Детали сериализации → код

---

## 3. Семантические поля

### 3.1 Метаданные документа

| Поле | Кратн. | Тип | Смысл |
|---|---|---|---|
| `version` | 1 | SemVer | Версия модели |
| `depends_on` | 1 | объект | `{ constitution: "SemVer" }` — версия L0, от которой зависит |
| `status` | 1 | enum | `draft` \| `active` \| `deprecated` — см. [Lifecycle в глоссарии](../glossary.md#lifecycle--жизненный-цикл-спецификации) |
| `scope` | 1 | string | Какой bounded context описывает |

### 3.2 Сущность (Entity / Value Object / Aggregate)

Схема для каждой сущности:

| Поле | Кратн. | Тип | Описание |
|---|---|---|---|
| `id` | 1 | `ENT-NNN` | Стабильный идентификатор. Не переиспользуется |
| `name` | 1 | string | Каноническое имя (PascalCase) |
| `kind` | 1 | enum | `entity` \| `value-object` \| `aggregate-root` |
| `description` | 1 | string | 1–2 предложения: что это и зачем |
| `identity` | 0..1 | string | Чем идентифицируется (только для `entity`/`aggregate-root`) |
| `fields` | 1..n | список | Типизированные атрибуты |
| `invariants` | 0..n | список `INV-NNN` | Правила, всегда истинные |
| `relations` | 0..n | список | Связи с другими сущностями |
| `state_machine` | 0..1 | объект | Состояния и переходы |
| `events_emitted` | 0..n | список `EVT-NNN` | Доменные события |
| `constraints_from_L0` | 0..n | список `ART-NNN` | Статьи Конституции, ограничивающие сущность |

**Правила именования:**

- Имена сущностей — `PascalCase` на английском (`Order`, `InvoiceLine`)
- Описание — на русском
- Один язык для имён во всём проекте

### 3.3 Поле сущности

| Поле | Кратн. | Тип | Описание |
|---|---|---|---|
| `name` | 1 | string | `camelCase` |
| `type` | 1 | string | Примитив или ссылка на `ENT-NNN` / тип-значение |
| `optional` | 1 | bool | Может ли отсутствовать |
| `description` | 1 | string | Зачем это поле |
| `constraints` | 0..n | список | Ограничения на значение (regex, диапазон, …) |

### 3.4 Инвариант

| Поле | Кратн. | Тип | Описание |
|---|---|---|---|
| `id` | 1 | `INV-NNN` | Стабильный ID |
| `entity` | 1 | `ENT-NNN` | К какой сущности относится |
| `rule` | 1 | string | Формулировка с RFC 2119 (`MUST`/`MUST NOT`) |
| `rationale` | 1 | string | Зачем нужен |
| `enforcement` | 1 | string | Где проверяется: конструктор, фабрика, репозиторий, сервис |
| `cross_refs` | 0..n | список | Ссылки на `ART-NNN` из L0, если инвариант их воплощает |

### 3.5 Отношение

| Поле | Кратн. | Тип | Описание |
|---|---|---|---|
| `target` | 1 | `ENT-NNN` | Связанная сущность |
| `kind` | 1 | enum | `one-to-one` \| `one-to-many` \| `many-to-many` |
| `ownership` | 1 | enum | `owns` \| `references` — определяет границу агрегата |
| `optional` | 1 | bool | Может ли отсутствовать |
| `description` | 1 | string | Смысл связи |

**Правило границ агрегата:** агрегат ОБЯЗАН владеть (`owns`) всем, что должно меняться атомарно. Внешние сущности только ссылаются (`references`) по ID.

### 3.6 Машина состояний

| Поле | Кратн. | Тип | Описание |
|---|---|---|---|
| `states` | 2..n | список | Допустимые состояния |
| `initial` | 1 | string | Стартовое состояние |
| `transitions` | 1..n | список | Переходы: `from → to` с триггером |
| `terminal` | 0..n | список | Финальные состояния |

Каждый переход описывается как тройка: `from`, `to`, `trigger` (имя доменного события или действия).

### 3.7 Доменное событие

| Поле | Кратн. | Тип | Описание |
|---|---|---|---|
| `id` | 1 | `EVT-NNN` | Стабильный ID |
| `name` | 1 | string | Прошедшее время: `OrderPlaced`, `PaymentReceived` |
| `emitted_by` | 1 | `ENT-NNN` | Кто излучает |
| `payload` | 1..n | список | Поля события (те же правила, что у полей сущности) |
| `description` | 1 | string | Что произошло в домене |

---

## 4. Правила написания

| Правило | Пояснение |
|---|---|
| **Атомарность** | Одна сущность — один блок. Один инвариант — один `INV-NNN`. |
| **WHAT, not HOW** | Описывается форма и инварианты, не способ хранения или реализации. |
| **Явная идентичность** | Для `entity` всегда указывается `identity`. |
| **Явные границы** | Агрегаты явно помечают `owns` vs `references`. |
| **Инварианты с RFC 2119** | Каждое правило содержит `MUST` / `MUST NOT`. |
| **Ссылки на L0** | Если инвариант следует из статьи Конституции — явная ссылка `ART-NNN`. |
| **Стабильные ID** | `ENT-NNN`, `INV-NNN`, `EVT-NNN` никогда не переиспользуются. |

---

## 5. Антипаттерны

- ❌ Поля вида `createdAt`, `updatedAt`, `deletedAt` на уровне домена — это инфраструктура
- ❌ `id: uuid` как единственная идентичность без бизнес-смысла (OK для surrogate, но тогда добавьте natural key)
- ❌ Инварианты в свободной форме без `MUST`
- ❌ Агрегат без явного корня
- ❌ Отношения без кардинальности и `ownership`
- ❌ Value Object с изменяемым состоянием (value objects immutable by definition)
- ❌ Сущность, имя которой — глагол (`CreateOrder`) — это операция, а не сущность
- ❌ Инвариант, который нельзя проверить в конкретной точке (`enforcement` не указан)

---

## 6. Минимальный пример

```yaml
version: 0.3.0
depends_on:
  constitution: 1.0.0
status: active
scope: billing

entities:
  - id: ENT-001
    name: Invoice
    kind: aggregate-root
    description: |
      Счёт, выставленный контрагенту. Корень агрегата биллинга.
    identity: "number (human-readable, per-year sequence)"
    fields:
      - name: number
        type: string
        optional: false
        description: Номер счёта в формате INV-YYYY-NNNNNN
        constraints: ["regex:^INV-\\d{4}-\\d{6}$"]
      - name: total
        type: Money
        optional: false
        description: Итоговая сумма к оплате
      - name: status
        type: InvoiceStatus
        optional: false
        description: Текущее состояние счёта
      - name: lines
        type: InvoiceLine[]
        optional: false
        description: Позиции счёта (не менее одной)
    invariants: [INV-001, INV-002, INV-003]
    relations:
      - target: ENT-002
        kind: one-to-many
        ownership: owns
        optional: false
        description: Позиции счёта принадлежат ему и удаляются вместе с ним
      - target: ENT-003
        kind: one-to-one
        ownership: references
        optional: false
        description: Контрагент, которому выставлен счёт
    state_machine:
      states: [draft, issued, paid, cancelled]
      initial: draft
      terminal: [paid, cancelled]
      transitions:
        - { from: draft, to: issued, trigger: issue }
        - { from: issued, to: paid, trigger: registerPayment }
        - { from: draft, to: cancelled, trigger: cancel }
        - { from: issued, to: cancelled, trigger: cancel }
    events_emitted: [EVT-001, EVT-002]
    constraints_from_L0: [ART-003]  # offline-first: issuance doesn't touch network

  - id: ENT-002
    name: InvoiceLine
    kind: entity
    description: Позиция счёта: товар/услуга с ценой и количеством
    identity: "lineNumber within Invoice"
    fields:
      - name: lineNumber
        type: int
        optional: false
        description: Порядковый номер, начиная с 1
        constraints: ["min:1"]
      - name: description
        type: string
        optional: false
        description: Человекочитаемое описание позиции
      - name: quantity
        type: Decimal
        optional: false
        description: Количество
        constraints: ["min:0", "exclusiveMin"]
      - name: unitPrice
        type: Money
        optional: false
        description: Цена за единицу
    invariants: [INV-004]

  - id: ENT-003
    name: Counterparty
    kind: entity
    description: Контрагент, которому выставляются счета

value_objects:
  - id: ENT-010
    name: Money
    kind: value-object
    description: Сумма в конкретной валюте
    fields:
      - name: amount
        type: Decimal
        optional: false
        description: Величина, 2 знака после запятой
      - name: currency
        type: CurrencyCode
        optional: false
        description: ISO 4217 alpha code

invariants:
  - id: INV-001
    entity: ENT-001
    rule: "Invoice MUST have at least one InvoiceLine when status is `issued`."
    rationale: "Пустой выставленный счёт — бессмыслица для контрагента."
    enforcement: "Фабрика Invoice.issue() / guard в доменном сервисе"

  - id: INV-002
    entity: ENT-001
    rule: "Invoice.total MUST equal sum of lines[*].quantity * lines[*].unitPrice."
    rationale: "total — производное значение; расхождение означает порчу данных."
    enforcement: "Конструктор Invoice; пересчёт при каждом изменении lines"

  - id: INV-003
    entity: ENT-001
    rule: "Invoice.currency of all lines MUST be identical."
    rationale: "Мульти-валютные счета явно не поддерживаются в этой версии."
    enforcement: "Guard при добавлении InvoiceLine"

  - id: INV-004
    entity: ENT-002
    rule: "InvoiceLine.quantity MUST be strictly positive."
    rationale: "Нулевая позиция не имеет смысла; отрицательная — это возврат, другая сущность."
    enforcement: "Конструктор InvoiceLine"

events:
  - id: EVT-001
    name: InvoiceIssued
    emitted_by: ENT-001
    description: Счёт переведён из draft в issued
    payload:
      - { name: invoiceNumber, type: string, optional: false, description: Номер счёта }
      - { name: issuedAt, type: Instant, optional: false, description: Момент выставления }
      - { name: total, type: Money, optional: false, description: Сумма на момент выставления }

  - id: EVT-002
    name: InvoicePaid
    emitted_by: ENT-001
    description: Счёт полностью оплачен
    payload:
      - { name: invoiceNumber, type: string, optional: false, description: Номер счёта }
      - { name: paidAt, type: Instant, optional: false, description: Момент оплаты }
```

---

## 7. Чеклист перед коммитом

- [ ] `version`, `depends_on.constitution`, `status` заполнены
- [ ] Каждая сущность имеет `kind`, `description`, не-пустые `fields`
- [ ] Для каждой `entity` указана `identity`
- [ ] Каждый инвариант содержит ключевое слово RFC 2119
- [ ] У каждого инварианта указан `enforcement`
- [ ] Все отношения имеют `kind` и `ownership`
- [ ] Границы агрегатов явны (`owns` vs `references`)
- [ ] Value Objects помечены как `value-object` и не содержат мутирующих операций
- [ ] ID `ENT-NNN`, `INV-NNN`, `EVT-NNN` уникальны и не переиспользованы
- [ ] Нет деталей хранения, UI или транспорта
- [ ] `constraints_from_L0` проставлены там, где инварианты следуют из Конституции
- [ ] Выполнен **Dry Run**: спецификация сверена с текущей версией L0

---

## 8. Как L1 используется в промптах

L1 внедряется после L0. Обычно целиком, если умещается в бюджет контекста; иначе — срезом: только сущности, упомянутые в задаче, плюс их прямые зависимости.

Модели даётся инструкция:

> «L1 — твой единственный источник истины о форме данных и инвариантах. Не изобретай поля. Если нужной сущности нет — ОСТАНОВИСЬ и сообщи. Все имена сущностей и полей бери из L1 дословно.»

Техника срезов и полный протокол — см. [`03-context-injection.md`](../03-context-injection.md).
