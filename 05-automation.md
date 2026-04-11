<!-- L0: Plugin toolkit overview — slash commands, bin scripts, install, tests -->

# Автоматизация SDD-процесса

Справочник — это теория. Этот раздел — практика: **исполняемый Claude Code plugin**, который механизирует правила из [`04-golden-rules.md`](04-golden-rules.md).

Toolkit построен на cog-подобной архитектуре: plain-text соглашения + простые bash-скрипты, никаких сервисов и БД, никаких внешних зависимостей.

---

## Установка

### Как Claude Code plugin (рекомендуется)

```text
/plugin marketplace add kainsk/sdd
/plugin install sdd@sdd-marketplace
```

После установки:
- **Slash-команды** доступны глобально: `/sdd:setup`, `/sdd:dry-run`, `/sdd:bug`, `/sdd:second-opinion`, `/sdd:housekeeping`, `/sdd:history`, `/sdd:evolve`, `/sdd:foresight`, `/sdd:reflect`, `/sdd:scenario`
- **`sdd` CLI-обёртка** и все `sdd-*.sh` добавляются в `PATH` в Bash tool (через `bin/` плагина)
- **Шаблоны** доступны для `/sdd:setup` через `$CLAUDE_PLUGIN_DIR/templates/`

### Локальная разработка

```bash
git clone https://github.com/kainsk/sdd.git
claude --plugin-dir ./sdd
```

Правки `commands/` и `bin/` подхватываются через `/reload-plugins` без перезапуска.

### Бутстрап нового SDD-проекта

После установки плагина, из корня целевого проекта:

```text
/sdd:setup my-project billing
```

Создаст:
```
my-project/
├── specs/
│   ├── constitution.md          # из templates/constitution.tpl.md
│   ├── domain/billing.md        # из templates/domain.tpl.md
│   └── scenarios/billing.md     # из templates/scenario.tpl.md
├── memory/
│   └── patterns.md              # из templates/patterns.tpl.md
└── steering/
    ├── product.md               # из templates/steering-product.tpl.md
    ├── tech.md                  # из templates/steering-tech.tpl.md
    └── structure.md             # из templates/steering-structure.tpl.md
```

Плюс прогонит `/sdd:housekeeping` для валидации.

---

## Что поставляется

### Slash-команды (`commands/`)

Skill-файлы, которые Claude читает при вводе `/sdd:<command>`. Каждая команда — Markdown-файл с чёткими шагами и правилами. После установки плагина доступны как `/sdd:<command>`.

| Команда | Назначение |
|---|---|
| [`/sdd:setup`](commands/setup.md) | Создать каркас `specs/`, `memory/`, `steering/` в новом проекте |
| [`/sdd:dry-run`](commands/dry-run.md) | Обязательная сверка задачи со спеками до генерации кода |
| [`/sdd:bug`](commands/bug.md) | Bug fix fast track: Report → Analyze → Fix → Verify, без новых ID |
| [`/sdd:second-opinion`](commands/second-opinion.md) | Независимая верификация Dry Run через sub-agent в чистом контексте |
| [`/sdd:housekeeping`](commands/housekeeping.md) | Валидация + пересборка link-index + scorecard |
| [`/sdd:history <ID>`](commands/history.md) | Полная история упоминаний идентификатора |
| [`/sdd:evolve`](commands/evolve.md) | Мета-аудит: diff спек, поиск напряжений, предложения по правкам правил |
| [`/sdd:foresight`](commands/foresight.md) | Сигналы конвергенции и слепые пятна: hot invariants, dormant entities |
| [`/sdd:reflect`](commands/reflect.md) | Обратная связь от практики: повторяющиеся блокеры Dry Run |
| [`/sdd:scenario`](commands/scenario.md) | Моделирование мажорных решений по спекам с ветками и canary |

### Bin-скрипты (`bin/`)

Bash-скрипты без внешних зависимостей (POSIX + `grep`, `awk`, `find`). После установки плагина все скрипты добавляются в `PATH` в Bash tool Claude Code.

| Скрипт / команда | Назначение | Выход |
|---|---|---|
| [`sdd`](bin/sdd) | Диспетчер: `sdd <cmd>` запускает `sdd-<cmd>.sh` | delegating |
| [`sdd validate`](bin/sdd-validate.sh) / `sdd-validate.sh` | Целостность: handshake, duplicates, dangling refs, RFC 2119, orphan ENT, orphan INV, security gate trace, pattern caps | stderr + exit code |
| [`sdd link-index`](bin/sdd-link-index.sh) / `sdd-link-index.sh` | Автогенерируемый обратный индекс всех упоминаний ID | Markdown на stdout |
| [`sdd scorecard`](bin/sdd-scorecard.sh) / `sdd-scorecard.sh` | Метрики здоровья спек + pattern caps usage | Markdown на stdout |
| [`sdd foresight`](bin/sdd-foresight.sh) / `sdd-foresight.sh` | Конвергенция: hot invariants, hot articles, dormant entities, priority distribution | Markdown на stdout |
| [`sdd install-hooks`](bin/sdd-install-hooks.sh) / `sdd-install-hooks.sh` | Установка git pre-commit hook, запускающего `sdd validate` | инсталляция в `.git/hooks/` |
| [`sdd test`](bin/sdd-test.sh) / `sdd-test.sh` | 51 регрессионный тест с inline-fixture в mktemp | stdout + exit code |

### Шаблоны (`templates/`)

- **Спеки:** `constitution.tpl.md`, `domain.tpl.md`, `scenario.tpl.md`, `patterns.tpl.md`
- **Steering:** `steering-product.tpl.md`, `steering-tech.tpl.md`, `steering-structure.tpl.md`

Копируются в целевой проект командой `/sdd:setup`.

### Plugin manifest (`.claude-plugin/`)

- [`plugin.json`](.claude-plugin/plugin.json) — имя, версия, автор, описание, ключевые слова
- [`marketplace.json`](.claude-plugin/marketplace.json) — каталог маркетплейса с одним плагином (этим)

### Environment variables

| Переменная | Default | Назначение |
|---|---|---|
| `SDD_SPECS` | `specs` | Путь к каталогу спек (L0/L1/L2) |
| `SDD_MEMORY` | `memory` | Путь к каталогу pattern routing (`patterns.md` + `patterns/`) |

Задавать inline: `SDD_SPECS=specs SDD_MEMORY=memory sdd validate`.

---

## Механика

### Формат идентификаторов

Scripts ожидают идентификаторы ровно из 3 цифр: `ART-001`, `ENT-042`, `SCN-123`. Это позволяет отличать настоящие ID от похожих строк (например, номера счетов `INV-2026-000001`).

Если проекту нужно больше 999 элементов в одной категории — это сигнал, что bounded context слишком крупный и его пора разделить.

### Определения vs ссылки

- **Определение** — заголовок `## FEA-001 — ...` (H2, только для Feature) или `### ART-001 — ...` (H3, для всего остального).
- **Ссылка** — любое другое упоминание ID в тексте.

`sdd validate` строит оба множества и выдаёт:
- **Dangling references** (ERROR/WARN) — ID цитируется, но не определён
- **Orphan entities** (WARN) — `ENT-NNN` определён, но не цитируется сценариями
- **Orphan invariants** (WARN) — `INV-NNN` определён, но не цитируется сценариями
- **Duplicate IDs** (ERROR) — один ID определён в двух местах

### Версионный handshake

`sdd validate` извлекает `version` из `constitution.md` frontmatter и сверяет с `depends_on.constitution` во всех L1/L2 файлах. Расхождение — ERROR.

### Pattern caps

Валидируется размер файлов pattern routing (см. [`06-patterns.md`](06-patterns.md)):

- `memory/patterns.md` — **hard cap 70 строк / 5.5 KB**. Превышение → ERROR → блок коммита (при включённом pre-commit hook).
- `memory/patterns/*.md` — **soft cap 30 строк**. Превышение → WARNING.

`sdd scorecard` показывает текущее заполнение в процентах.

**Если hard cap мешает** — конденсируйте правила или перенесите специфичные в satellite. НЕ поднимайте cap.

### Security gate trace

Статьи `ART-NNN` с `**Категория:** \`security\`` обязаны цитировать `SCN-NNN` в поле enforcement — security decisions нуждаются в observable verification. Иначе WARN.

### Heuristics ↔ строгость

Несколько проверок — эвристические:
- **RFC 2119 в статьях** — ищется в блоке от `### ART-NNN` до следующего `### `. WARN, не ERROR.
- **Orphan / security** — анализируются только файлы в путях `*scenario*`. Если сценарии лежат в нестандартном месте — установите `SDD_SPECS` и проверьте что find-pattern подходит.

Эвристики выбраны сознательно: цена ложноположительных срабатываний ниже, чем цена сложного парсинга Markdown.

---

## Регрессионные тесты

Набор регрессионных тестов живёт в `bin/sdd-test.sh`. Запуск:

```bash
bash bin/sdd-test.sh
# или после установки плагина:
sdd test
```

Покрывает 51 кейс в 12 секциях:

- **Syntax** — все скрипты проходят `bash -n`
- **Baseline** — validate / link-index / scorecard / foresight на inline-fixture в mktemp
- **Cap enforcement** — инфлейт core → `exit 1`; restore → `exit 0` (через `SDD_MEMORY` изоляцию, реальный `memory/` не трогается)
- **Duplicate ID detection** — дубликат `ART-001` → `exit 1`
- **Dangling reference detection** — `ENT-777` → warning
- **Security gate trace** — warn когда нет SCN / clear когда SCN добавлен
- **Orphan invariant detection** — удаление `INV-001` из references → warning
- **Version handshake mismatch** → `exit 1`
- **SDD_MEMORY env var** — кастомный путь обрабатывается корректно
- **L0 comments** — каждый handbook-файл и команда имеет `<!-- L0: ... -->` (22 проверки)
- **Plugin manifest** — `plugin.json` и `marketplace.json` существуют и валидны как JSON
- **Command refs valid** — упомянутые в командах скрипты существуют и исполняемы
- **Wrapper dispatch** — `sdd help`, `sdd validate`, `sdd test`, unknown → exit 2

Inline-fixture в `mktemp` — **реальные файлы не мутируются**. Trap cleanup на EXIT/INT/TERM.

---

## Что toolkit **не** делает

- Не парсит Markdown структурно — только grep-эвристики
- Не запускает Gherkin-сценарии — это забота cucumber/behave/godog
- Не генерирует код из спек — цель уровня spec-as-source, отдельный проект
- Не следит за файлами в реальном времени — запускается явно через команды или hooks
- Не правит найденные проблемы — отчёт → решение человека

---

## Расширение toolkit

**Добавить новую проверку** в `bin/sdd-validate.sh`:
1. Написать блок проверки в скрипте, используя `say_err` / `say_warn` для отчёта
2. Классифицировать по [gates taxonomy](04-golden-rules.md#гейты--таксономия-проверок): pre-flight (ERROR) или revision (WARN)
3. Добавить регрессионный тест в `bin/sdd-test.sh` (модификация inline-fixture + ассерт exit code)
4. Прогнать `sdd test` — должно остаться all green

**Добавить новую slash-команду:**
1. Создать `commands/<name>.md` в cog-стиле: L0-комментарий, назначение, шаги, файлы, правила
2. Если команда запускает новый скрипт — добавить его в `bin/` и обновить `bin/sdd` wrapper
3. Обновить таблицу в этом README и `plugin.json` keywords при необходимости
4. Прогнать `sdd test` — автоматический L0-check подхватит новую команду
