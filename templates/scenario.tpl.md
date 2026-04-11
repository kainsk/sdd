<!--
  ШАБЛОН BDD-СЦЕНАРИЕВ (L2)
  Заполните каждый <PLACEHOLDER>.
  Справочник: ../01-hierarchy/L2-bdd-scenarios.md
-->

---
version: 0.1.0                     # SemVer набора сценариев
depends_on:
  constitution: 0.1.0              # Версия L0
  domain: 0.1.0                    # Версия L1
status: draft                      # draft | active | deprecated
feature_area: <capability>         # Какой capability посвящён документ
---

# BDD-сценарии — <FEATURE AREA>

## FEA-001 — <короткое имя Feature>

**Narrative:**
- **As a** <роль>
- **I want** <цель>
- **So that** <бизнес-польза>

**Background** *(опционально):*
- Given <общее предусловие для всех сценариев ниже>
- And <...>

---

### SCN-001 — <короткое описание поведения>

- **priority:** `MUST` | `SHOULD` | `MAY`
- **actors:** [<актор1>, <актор2>]
- **tags:** [@<tag1>, @<tag2>]
- **references:**
  - entities: [`ENT-NNN`]
  - invariants: [`INV-NNN`]
  - articles: [`ART-NNN`]

```gherkin
Given <предусловие>
And <ещё предусловие>
When <ровно одно действие>
Then <наблюдаемый исход>
And <ещё один наблюдаемый исход>
```

---

### SCN-002 — <...>

- **priority:** <...>
- **actors:** [<...>]
- **tags:** [<...>]
- **references:**
  - entities: [<...>]
  - invariants: [<...>]
  - articles: [<...>]

```gherkin
Given <...>
When <...>
Then <...>
```

<!-- Добавляйте SCN-NNN по необходимости. Не переиспользуйте ID. -->

---

## Scenario Outline *(опционально)*

<!--
  Используйте, когда поведение одинаково, а различаются только данные.
  Колонки таблицы — параметры, не разные поведения.
-->

```gherkin
Scenario Outline: <описание параметризованного поведения>
  Given <... with <param1>>
  When <...>
  Then <... with "<expected>">

  Examples:
    | param1 | expected |
    | <...>  | <...>    |
```

---

## Чеклист перед коммитом

- [ ] `version`, `depends_on.{constitution,domain}`, `status`, `feature_area` заполнены
- [ ] У каждой Feature есть `narrative` (As/I want/So that)
- [ ] У каждого сценария **ровно один** `when`
- [ ] Каждый `then` описывает наблюдаемый исход
- [ ] Проставлен `priority`
- [ ] `references` содержит минимум одну ссылку на `ENT-NNN` или `INV-NNN`
- [ ] Нет UI-деталей, SQL, имён таблиц
- [ ] Имена сущностей/полей совпадают с L1 дословно
- [ ] ID `FEA-NNN`, `SCN-NNN` уникальны и не переиспользованы
- [ ] Выполнен Dry Run против актуальных L0 и L1
