<!-- L0: Steering doc — technology stack and architectural choices. The "HOW" that L0 only constrains. -->

---
version: 0.1.0
status: draft
---

# Tech — <PROJECT NAME>

> **Steering document.** Зафиксированный технологический стек проекта. В отличие от L0 (которая ограничивает «что нельзя»), здесь описано «что выбрано».

## Language & runtime

- **Primary language:** <Go 1.22 / TypeScript / Python 3.11 / ...>
- **Runtime / build:** <как собирается, как запускается>
- **Toolchain version pin:** <конкретная версия в `go.mod` / `package.json` / `pyproject.toml`>

## Frameworks & key libraries

| Категория | Выбор | Зачем |
|---|---|---|
| Web framework | <...> | <обоснование> |
| ORM / DB driver | <...> | <обоснование> |
| Test framework | <...> | <обоснование> |
| BDD runner | godog / cucumber-js / behave | для L2 спецификаций |
| Linter | <...> | <правила> |

## Storage

- **Primary database:** <PostgreSQL 16 / SQLite / ...>
- **Cache:** <Redis / in-memory / нет>
- **Object storage:** <S3 / local FS / нет>
- **Migrations:** <инструмент и политика>

## Infrastructure

- **Deployment target:** <Kubernetes / single binary / serverless / ...>
- **CI/CD:** <GitHub Actions / GitLab CI / Drone / ...>
- **Observability:** <логи: куда / метрики: куда / traces: куда>
- **Secrets management:** <как хранятся, как ротируются>

## Architectural style

- **Pattern:** <hexagonal / layered / event-driven / ...>
- **Dependency direction:** <ports внутри домена; адаптеры наружу — или другая модель>
- **Module boundaries:** <как разделены bounded contexts>

## Constraints from L0

Этот документ **должен соответствовать** статьям Конституции категории `tech-stack` и `architecture`. Перечислите релевантные `ART-NNN`:

- `ART-XXX` — <как этот документ соблюдает>
- ...

При конфликте между этим документом и L0 — **побеждает L0**, этот документ обновляется.

## What's NOT decided here

- Конкретные домены и сущности — L1
- Конкретные сценарии — L2
- Бизнес-инварианты — L1 invariants
- Безопасностные требования — L0 articles категории `security`

---

**Эта спецификация:**
- Описывает выбор стека и инфраструктуры (HOW)
- Соответствует `L0/constitution.md` (WHAT NOT)
- Не противоречит `steering-product.md` (WHO/WHY)
- Должна синхронизироваться с реальностью при смене стека (bump version)
