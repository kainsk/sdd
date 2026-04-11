<!-- L0: Overview, install instructions, and navigation for the SDD plugin + handbook -->

# SDD — Spec-Driven Development for Claude Code

Каскадная иерархия спецификаций для промптинга LLM, при котором порождаемый код соблюдает инварианты проекта. Оформлено как **Claude Code plugin**: 10 slash-команд, 6 bash-скриптов в `PATH`, 7 шаблонов, 51 регрессионный тест.

Заимствует механики из четырёх SDD-источников: [cog](https://github.com/marciopuga/cog) (memory + routing), [GSD](https://github.com/gsd-build/get-shit-done) (gates taxonomy + context rot), [Pimzino spec-workflow](https://github.com/Pimzino/claude-code-spec-workflow) (steering + bug fast track), [tylerburleigh/claude-sdd-toolkit](https://github.com/tylerburleigh/claude-sdd-toolkit) (lifecycle + multi-model second opinion).

---

## Установка

### Через Claude Code marketplace (рекомендуется)

```text
/plugin marketplace add kainsk/sdd
/plugin install sdd@sdd-marketplace
```

После этого:
- 10 slash-команд доступны как `/sdd:setup`, `/sdd:dry-run`, `/sdd:bug`, `/sdd:second-opinion`, `/sdd:housekeeping`, `/sdd:history`, `/sdd:evolve`, `/sdd:foresight`, `/sdd:reflect`, `/sdd:scenario`
- CLI-обёртка `sdd` и скрипты `sdd-validate.sh`, `sdd-link-index.sh`, `sdd-scorecard.sh`, `sdd-foresight.sh`, `sdd-install-hooks.sh`, `sdd-test.sh` появляются в PATH
- Шаблоны (constitution / domain / scenario / patterns / steering-product / steering-tech / steering-structure) доступны через `sdd setup` в целевом проекте

### Локальная разработка / тест без установки

```bash
git clone https://github.com/kainsk/sdd.git
claude --plugin-dir ./sdd
```

В этом режиме всё работает без копирования в кэш плагинов; правки `commands/` и `bin/` подхватываются через `/reload-plugins`.

### Бутстрап нового SDD-проекта

```text
/sdd:setup <project-name> <bounded-context>
```

Создаст в текущем рабочем каталоге `specs/`, `memory/`, `steering/` со скелетами из шаблонов и запустит `/sdd:housekeeping` для проверки.

---

## Быстрый старт после установки

1. Прочитать [Золотые правила](04-golden-rules.md) — четыре закона + Gates taxonomy.
2. `/sdd:setup my-project billing` — каркас.
3. Заполнить `specs/constitution.md`: 5–10 первых статей с RFC 2119 ключевыми словами.
4. Добавить сущности и инварианты в `specs/domain/billing.md`.
5. Описать 3–5 сценариев в `specs/scenarios/billing.md`.
6. Перед каждой задачей — `/sdd:dry-run` первым, код вторым. `Verdict: BLOCK` запрещает код.
7. Перед коммитом — `sdd test` (если разрабатываете плагин) или `sdd validate specs` (если конечный проект).

---

## Навигация по справочнику

### Иерархия спецификаций

| Уровень | Документ | Назначение |
|---|---|---|
| **L0** | [Конституция](01-hierarchy/L0-constitution.md) | Неизменные законы проекта |
| **L1** | [Доменная модель](01-hierarchy/L1-domain-model.md) | Сущности и инварианты |
| **L2** | [BDD-сценарии](01-hierarchy/L2-bdd-scenarios.md) | Наблюдаемое поведение |

### Диалект (L2)

[Gherkin-MD](02-gherkin-md.md) — единственный диалект L2: исполняемый через Cucumber/behave/godog, читаемый бизнесом, инвариантный к языку реализации. L0 и L1 — Markdown + YAML frontmatter.

### Процесс

- [Context Injection](03-context-injection.md) — порядок инъекции, бюджет, слайсинг, **context rot и phase restart**, параллельная генерация
- [Золотые правила](04-golden-rules.md) — Atomic / SSOT / Dry Run / Stable IDs + **Gates taxonomy** + maturity ladder
- [Pattern Routing](06-patterns.md) — core + satellite операционные правила (cog-inspired)

### Toolkit (содержимое плагина)

- [Обзор toolkit](05-automation.md) — slash-команды, скрипты, environment variables, тесты
- [`commands/`](commands/) — 10 slash-команд (markdown skill files)
- [`bin/`](bin/) — 6 bash-скриптов в PATH
- [`templates/`](templates/) — 7 шаблонов для `/sdd:setup`
- [`memory/patterns.md`](memory/patterns.md) — core operational patterns (hard cap 70 строк / 5.5 KB)

### Справочные материалы

- [Глоссарий](glossary.md) — канонические определения терминов

---

## Ключевая идея

Спецификации образуют строгую иерархию **L0 → L1 → L2**. Нижние уровни НЕ ДОЛЖНЫ противоречить верхним. Конституция (L0) — высшая инстанция; при конфликте **побеждает L0**.

Каждый уровень — *исполняемая документация*: механически проверяемая (`sdd validate`), хранящаяся в VCS и внедряемая в контекст модели как источник истины.

```
L0 Конституция          ← высший приоритет
   │
   ├── ограничивает ↓
   │
L1 Доменная модель      ← сущности, инварианты
   │
   ├── ограничивает ↓
   │
L2 BDD-сценарии         ← наблюдаемое поведение
```

Перед генерацией кода модель ОБЯЗАНА выполнить **Dry Run** через `/sdd:dry-run`. Канонический протокол — [`04-golden-rules.md` → Rule 3](04-golden-rules.md#rule-3--dry-run--сверка-перед-кодингом).

---

## Зрелостная шкала

| Уровень | Признаки | Где применять |
|---|---|---|
| **Spec-first** | Спеки пишутся под задачу и выкидываются | Прототипы |
| **Spec-anchored** | Спеки версионируются и обновляются при изменениях | **Большинство команд должны быть здесь — этот плагин описывает именно такой процесс** |
| **Spec-as-source** | Редактируются только спеки, код генерируется с пометкой `DO NOT EDIT` | Отдельный инженерный проект |

Подробнее — [`04-golden-rules.md` → Maturity Ladder](04-golden-rules.md#бонус-maturity-ladder--зрелостная-шкала).

---

## Когда SDD **не** применять

Полный каскад L0/L1/L2 избыточен для тривиальных задач. Граница:

- Если изменение **может породить новый инвариант или сценарий** → полный `/sdd:dry-run`
- Если только восстанавливает соответствие коду уже существующих спек → `/sdd:bug` (структурированный fast track)
- Если правка текста / i18n / переименование без семантики → обычное редактирование

Подробнее — [`03-context-injection.md` → §10](03-context-injection.md#10-когда-sdd-не-применять).

---

## Тесты

После клонирования:

```bash
bash bin/sdd-test.sh
# или, если плагин уже установлен:
sdd test
```

51 регрессионный тест: syntax, baseline (validate/link-index/scorecard/foresight на inline-fixture), cap regression (через `SDD_MEMORY` изоляцию), duplicate ID, dangling reference, security gate trace, INV orphan, version handshake, `SDD_MEMORY` env var, L0-комментарии (22 файла), plugin manifest validity, command refs valid, wrapper dispatch.

Inline-fixture в `mktemp` — реальные файлы не мутируются. Trap cleanup на EXIT/INT/TERM.

---

## Лицензия

MIT.

## Источники

Этот плагин — синтез четырёх SDD-инициатив. См. соответствующие repo для оригинальных идей:

- **cog** — `marciopuga/cog`: filesystem-based memory, pattern routing, reflect/evolve loop
- **GSD** — `gsd-build/get-shit-done`: gates taxonomy, context rot mitigation, scope reduction
- **Pimzino spec-workflow** — `Pimzino/claude-code-spec-workflow`: 4-фазный пайплайн, steering documents, bug fast track
- **claude-sdd-toolkit** — `tylerburleigh/claude-sdd-toolkit`: lifecycle states, multi-model second opinion (адаптировано под one-model setup)

Дополнительный концептуальный материал — [Martin Fowler on Spec-Driven Development](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html).
