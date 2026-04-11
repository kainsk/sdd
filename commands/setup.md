<!-- L0: Bootstrap a new specs/ tree in the target project from SDD templates -->

# /sdd:setup

Создать каркас `specs/` в текущем рабочем каталоге из шаблонов SDD toolkit.

## Когда применять

Первый шаг в новом проекте, который будет использовать SDD. Запускать ровно один раз. Повторный запуск должен быть отклонён без явного `--force`.

## Аргументы

- `[project-name]` — опционально, имя проекта. Если не указан — спросить.
- `[bounded-context]` — опционально, имя первого bounded context (напр. `billing`). Если не указан — спросить.

## Шаги

1. Проверить, существует ли `./specs/`. Если да — остановиться и сообщить пользователю; не перезаписывать.
2. Проверить, доступны ли шаблоны toolkit: ожидается `$SDD_TOOLKIT/templates/` или `./sdd-toolkit/templates/` или `./templates/`. Выбрать первый существующий путь.
3. Спросить у пользователя (если не передано аргументом):
   - Имя проекта для преамбулы Конституции
   - Имя первого bounded context
4. Создать структуру:
   ```
   specs/
   ├── constitution.md                    ← из constitution.tpl.md
   ├── domain/
   │   └── <bounded-context>.md           ← из domain.tpl.md
   └── scenarios/
       └── <bounded-context>.md           ← из scenario.tpl.md
   memory/
   ├── patterns.md                        ← из patterns.tpl.md (core)
   └── patterns/
       └── <bounded-context>.md           ← пустой satellite skeleton (опционально)
   steering/
   ├── product.md                         ← из steering-product.tpl.md (vision, users, jobs)
   ├── tech.md                            ← из steering-tech.tpl.md (стек, инфра, архитектура)
   └── structure.md                       ← из steering-structure.tpl.md (раскладка кода)
   ```

   **Steering documents** — persistent project context. В отличие от L0/L1/L2 (нормативные), они описывают "where we are": vision продукта, выбранный стек, физическая раскладка кода. Загружаются один раз при онбординге, цитируются спеками — не дублируются в них.
5. В каждом созданном файле подставить:
   - `<PROJECT NAME>` → имя проекта (в constitution.md)
   - `<BOUNDED CONTEXT>` / `<bounded-context>` → имя контекста (в domain.md и scenarios.md)
   - `YYYY-MM-DD` → сегодняшняя дата
   - `version: 0.1.0` — оставить
   - `status: draft` — оставить
6. Запустить `/sdd:housekeeping` для подтверждения, что начальная структура валидна.
7. Вывести пользователю дерево созданных файлов и первые 3 next-steps:
   - заполнить преамбулу Конституции
   - добавить первые 3–5 статей
   - убедиться, что плагин установлен в Claude Code (`/plugin install sdd@sdd-marketplace`) или активирован локально (`claude --plugin-dir <path>`)

## Файлы

- **Читает:** `$SDD_TOOLKIT/templates/*.tpl.md` (constitution, domain, scenario, patterns, steering-product, steering-tech, steering-structure)
- **Пишет:** `./specs/**`, `./memory/patterns.md`, `./memory/patterns/` (по желанию), `./steering/{product,tech,structure}.md`

## Правила

- Никогда не перезаписывать существующий `./specs/` без явного подтверждения пользователя.
- Версия всегда стартует с `0.1.0`. Первая «подписанная» версия — `1.0.0`, бампится вручную.
- `effective_date` = дата запуска команды.
- Не заполнять статьи/сущности за пользователя. Шаблон остаётся шаблоном; содержимое — за автором.
