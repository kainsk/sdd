<!--
  ШАБЛОН ДОМЕННОЙ МОДЕЛИ (L1)
  Заполните каждый <PLACEHOLDER>. Удалять секции можно только там, где явно разрешено.
  Справочник: ../01-hierarchy/L1-domain-model.md
-->

---
version: 0.1.0                     # SemVer доменной модели
depends_on:
  constitution: 0.1.0              # Версия L0, от которой зависит эта модель
status: draft                      # draft | active | deprecated
scope: <bounded-context>           # Какой bounded context описывает
---

# Доменная модель — <BOUNDED CONTEXT>

## Обзор

<!-- 2–4 предложения: что за bounded context, его назначение, ключевые сущности. -->

<ОПИСАНИЕ>

---

## Сущности

<!--
  Копируйте блок ENT-NNN для каждой сущности.
  Никогда не переиспользуйте ID — даже после удаления сущности номер «выжигается».
-->

### ENT-001 — <PascalCaseName>

- **Kind:** `entity` | `value-object` | `aggregate-root`
- **Описание:** <1–2 предложения>
- **Identity:** <чем идентифицируется; только для entity/aggregate-root>
- **Поля:**
  | Имя | Тип | Optional | Описание | Ограничения |
  |---|---|---|---|---|
  | <camelCase> | <primitive \| ENT-NNN> | false | <назначение> | <regex, min, max, …> |
- **Инварианты:** `INV-001`, `INV-002`
- **Отношения:**
  | Target | Kind | Ownership | Optional | Описание |
  |---|---|---|---|---|
  | `ENT-NNN` | one-to-one \| one-to-many \| many-to-many | owns \| references | false | <смысл связи> |
- **State machine** *(опционально):*
  - `states`: [<s1>, <s2>, ...]
  - `initial`: <s1>
  - `terminal`: [<s_final>]
  - `transitions`:
    - `{ from: <s1>, to: <s2>, trigger: <event-or-action> }`
- **Events emitted** *(опционально):* `EVT-001`
- **Constraints from L0** *(опционально):* `ART-NNN`

### ENT-002 — <...>

<!-- повторить блок -->

---

## Value Objects

<!-- То же, что и сущности, но kind: value-object. Без identity. Без state machine. -->

### ENT-010 — <PascalCaseName>

- **Kind:** `value-object`
- **Описание:** <...>
- **Поля:** <...>

---

## Инварианты

<!-- Копируйте блок INV-NNN для каждого инварианта. -->

### INV-001

- **Entity:** `ENT-NNN`
- **Rule:** `<EntityName>` **MUST** / **MUST NOT** <правило>.
- **Rationale:** <зачем>
- **Enforcement:** <конструктор | фабрика | доменный сервис | репозиторий>
- **Cross-refs** *(опционально):* `ART-NNN`

### INV-002

<!-- повторить блок -->

---

## Доменные события

<!-- Копируйте блок EVT-NNN для каждого события. -->

### EVT-001 — <EventNameInPastTense>

- **Emitted by:** `ENT-NNN`
- **Описание:** <что произошло в домене>
- **Payload:**
  | Имя | Тип | Optional | Описание |
  |---|---|---|---|
  | <camelCase> | <type> | false | <...> |

---

## Чеклист перед коммитом

- [ ] `version`, `depends_on.constitution`, `status`, `scope` заполнены
- [ ] Каждая `entity` имеет `identity`
- [ ] Каждый инвариант содержит `MUST` / `MUST NOT`
- [ ] У каждого инварианта указан `enforcement`
- [ ] Все отношения имеют `kind` и `ownership`
- [ ] Value Objects помечены и не содержат мутирующих операций
- [ ] Нет деталей хранения, UI или транспорта
- [ ] Выполнен Dry Run против актуальной версии L0
