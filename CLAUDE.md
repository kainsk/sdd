<!-- L0: Instructions for Claude working inside this SDD handbook repo -->

# CLAUDE.md — SDD Handbook Repo

Инструкции для Claude, работающего внутри этого репозитория.

## Что это

Spec-Driven Development handbook + toolkit, оформленный как **Claude Code plugin**. Содержит: референсную документацию, шаблоны, slash-команды (`commands/`), исполняемые скрипты в PATH (`bin/`) и манифест плагина (`.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json`).

## Где что живёт

| Путь | Назначение |
|---|---|
| `README.md` | Навигация, быстрый старт, зрелостная шкала |
| `glossary.md` | Канонические определения терминов — **SSOT по терминологии** |
| `01-hierarchy/L{0,1,2}-*.md` | Детальные справочники уровней |
| `02-gherkin-md.md` | Единственный диалект L2 — Gherkin-MD (L0/L1 используют Markdown+YAML) |
| `03-context-injection.md` | Протокол инъекции спек в контекст модели |
| `04-golden-rules.md` | **SSOT по правилам** — Atomic / SSOT / Dry Run / Stable IDs |
| `05-automation.md` | Документация toolkit |
| `06-patterns.md` | Pattern routing — core vs satellite операционные правила |
| `memory/patterns.md` | **Core patterns** — загружаются каждой командой. Hard cap 70 строк / 5.5KB |
| `memory/patterns/<ctx>.md` | **Satellite patterns** — загружаются при работе с bounded context. Soft cap 30 строк (в этом репо отсутствуют — справочник, не проект) |
| `templates/*.tpl.md` | Заполняемые скелеты — placeholder'ы `<...>` намеренные. Включает спек-шаблоны (constitution/domain/scenario/patterns) и steering-шаблоны (product/tech/structure) |
| `.claude-plugin/plugin.json` | Манифест плагина (имя, версия, описание, ключевые слова) |
| `.claude-plugin/marketplace.json` | Манифест маркетплейса с одним плагином (этим) |
| `commands/*.md` | Slash-команды плагина — после установки доступны как `/sdd:<name>` |
| `bin/sdd` | CLI wrapper, добавляется в PATH когда плагин активен |
| `bin/sdd-*.sh` | Bash-скрипты toolkit — также в PATH |
| `bin/sdd-test.sh` | Регрессионные тесты — создают inline fixture через mktemp (`sdd test`) |

## Правила редактирования

1. **Язык справочника — русский.** Технические термины, RFC 2119 ключевые слова (`MUST`/`SHOULD`/`MAY`), YAML-поля, имена сущностей — английские. Проза — русская.
2. **RFC 2119 обязателен в содержимом спек** (поле `statement` в L0, `rule` в инвариантах, `priority` в L2). В прозе справочника *о том, как писать спеки*, — не обязателен.
4. **Каждый handbook-файл начинается с `<!-- L0: ... -->` комментарием в одну строку** для прогрессивной загрузки.
5. **SSOT:** у каждого факта — одно место определения. Другие файлы ссылаются, не дублируют.
6. **Стабильные ID:** `ART-NNN`, `ENT-NNN`, `INV-NNN`, `EVT-NNN`, `FEA-NNN`, `SCN-NNN` никогда не переиспользуются, даже после удаления.
7. **ID формат — ровно 3 цифры.** Скрипты валидации фильтруют по `length == 7` (3 буквы + дефис + 3 цифры). Если проекту нужно больше 999 — это сигнал разделить bounded context.
8. **Pattern caps — обязательны.** `memory/patterns.md` hard cap 70 строк / 5.5 KB; `memory/patterns/*.md` soft cap 30 строк. Превышение hard cap — ERROR, блокирует housekeeping. Если не помещается — конденсировать или разнести между core и satellite, НЕ поднимать cap.
9. **Pattern routing:** universal rules → `memory/patterns.md` (core); domain-specific → `memory/patterns/<context>.md` (satellite). Если rule применим к любому проекту на SDD — он core. Если только к конкретному bounded context — satellite.

## Dogfooding перед коммитом

После любого изменения в `memory/patterns*`, `bin/sdd-*.sh` или любом handbook-файле — прогнать:

```bash
bash bin/sdd-test.sh   # полный регрессионный набор — all green требуется
# или, если плагин установлен и sdd в PATH:
sdd test
```

`sdd-test.sh` генерирует минимальный inline-fixture в `mktemp` и проверяет validate/link-index/scorecard/foresight, cap-регрессии, duplicate ID, dangling references, security gate, INV orphan, version handshake, SDD_MEMORY, L0-комментарии, plugin manifest валидность, wrapper-dispatch.

Регрессия — блокер.

## Environment variables

| Переменная | Default | Назначение |
|---|---|---|
| `SDD_SPECS` | `specs` | Путь к каталогу спек (L0/L1/L2). Принимается как arg или env. |
| `SDD_MEMORY` | `memory` | Путь к каталогу pattern routing (`patterns.md` + `patterns/*.md`). |

Задавать inline: `SDD_SPECS=specs SDD_MEMORY=memory sdd validate`. Пустой/несуществующий `SDD_MEMORY` не ошибка — pattern checks тихо пропускаются.

## Как работать с задачами

- Перед генерацией кода/контента, затрагивающего SDD-концепты, прочитать:
  - `04-golden-rules.md` (правила)
  - `glossary.md` (термины)
  - Релевантный L0/L1/L2 справочник
- Для изменений в slash-командах — сначала прочитать `commands/<name>.md`.
- Для изменений в скриптах — обязательно прогнать `bash bin/sdd-test.sh` до и после.

## Чего не делать

- Не создавать документы-сиротки: любой новый файл в справочнике должен быть залинкован из `README.md` и/или другого раздела.
- Не переписывать `link-index.md`, `scorecard.md`, `evolve-log.md` вручную — они генерируемые.
- Не пропускать L0-комментарий в новых handbook-файлах.
- Не смешивать уровни: статьи L0 не описывают сущности; сущности L1 не описывают поведение; сценарии L2 не описывают инварианты.
