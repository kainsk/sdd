<!-- L0: Steering doc — physical code structure and conventions. The map of where things live. -->

---
version: 0.1.0
status: draft
---

# Structure — <PROJECT NAME>

> **Steering document.** Карта физической структуры проекта: где что лежит, как названо, почему так. Это **снимок реальности**, не план.

## Top-level layout

```
<project>/
├── cmd/                  # CLI / entry points
├── internal/             # Внутренние пакеты, не экспортируемые
│   ├── domain/           # L1 доменные сущности (чистый код, без I/O)
│   ├── ports/            # Интерфейсы для I/O (порты)
│   └── adapters/         # Реализации портов: db, http, cli
├── specs/                # SDD спецификации
│   ├── constitution.md   # L0
│   ├── domain/           # L1 — доменные модели по bounded contexts
│   ├── scenarios/        # L2 — Gherkin-MD сценарии
│   ├── glossary.md       # Опциональный канонический глоссарий
│   ├── dry-run-log.md    # Append-only лог Dry Run прогонов
│   └── link-index.md     # Auto-generated
├── memory/               # Pattern routing
│   ├── patterns.md       # Core (hard cap 70 строк / 5.5KB)
│   └── patterns/         # Satellites по bounded contexts
├── steering/             # Steering docs (этот файл и его соседи)
│   ├── product.md
│   ├── tech.md
│   └── structure.md
├── scripts/              # Bash инструменты SDD toolkit
├── .claude/
│   ├── settings.json
│   └── commands/         # SDD slash-команды
├── tests/                # Интеграционные и e2e тесты
├── README.md
├── CLAUDE.md             # Инструкции для Claude
└── go.mod / package.json # Manifest стека
```

## Naming conventions

| Категория | Convention | Пример |
|---|---|---|
| Файлы Go | `snake_case.go` | `invoice_service.go` |
| Пакеты Go | `lowercase` без подчёркиваний | `package billing` |
| Файлы TS/JS | `kebab-case.ts` | `invoice-service.ts` |
| Spec файлы | `<bounded-context>.md` | `specs/domain/billing.md` |
| Test файлы | `<unit>_test.go` или `<unit>.test.ts` | `invoice_test.go` |

## Module / package boundaries

- **Domain packages MUST NOT import adapter packages** (см. `ART-002` в L0).
- **Adapters import domain ports**, не наоборот.
- **Cross-context calls** идут через явные интерфейсы, не через прямой импорт.

## Where things go

| Что | Где | Почему |
|---|---|---|
| Бизнес-логика, инварианты | `internal/domain/<context>/` | Чистый код, без зависимостей от I/O |
| HTTP handlers | `internal/adapters/http/` | Адаптеры наружу |
| DB queries | `internal/adapters/db/` | Адаптеры наружу |
| Tests of pure logic | рядом с кодом, `_test.go` | Co-located с unit |
| Integration tests | `tests/integration/` | Отдельная директория, разный runner |
| BDD runners | `tests/bdd/` или `features/` | Cucumber/godog ожидает свою структуру |
| Configuration | `internal/config/` или ENV | См. `steering-tech.md` |
| Migrations | `migrations/` или `db/migrations/` | Инструмент см. в `steering-tech.md` |

## What's NOT in this document

- Какие сущности — L1 (`specs/domain/*.md`)
- Какие сценарии — L2 (`specs/scenarios/*.md`)
- Почему выбраны технологии — `steering-tech.md`
- Зачем продукт нужен — `steering-product.md`

---

**Эта спецификация:**
- Описывает физическую раскладку проекта
- Должна синхронизироваться с реальностью при рефакторинге (bump version)
- Не описывает поведение или правила — только «куда смотреть»
- Должна соответствовать архитектурным `ART-NNN` из L0
