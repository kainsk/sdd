<!-- L0: Run full integrity sweep: validate, rebuild link-index, compute scorecard -->

# /sdd:housekeeping

Полный sweep целостности `specs/`. Запускать регулярно (перед каждым релизом; еженедельно на активных проектах).

Housekeeping **применяет** существующие правила. Для изменения самих правил — `/sdd:evolve`.

## Шаги

1. **Validate.** Запустить `sdd validate specs`, захватить stdout и exit code.
2. **Link index.** Запустить `sdd link-index specs > specs/link-index.md`.
3. **Scorecard.** Запустить `sdd scorecard specs > specs/scorecard.md`.
4. **Отчёт пользователю:**

   ```markdown
   ## Housekeeping report

   - **Validate:** PASS | FAIL — <N errors, M warnings>
   - **Link index:** обновлён, <K определений, R ссылок, D dangling>
   - **Scorecard:** <заголовочные метрики: статей, сущностей, инвариантов, сценариев>
   - **Errors:** <bulleted list если есть>
   - **Warnings:** <bulleted list если есть>
   - **Action items:**
     - <что требует решения человека>
   ```

5. **Если validate вернул exit ≠ 0** — репозиторий спек в невалидном состоянии. Флагом в отчёте; не смягчать формулировку.

## Файлы

- **Читает:** `specs/**`
- **Пишет:** `specs/link-index.md`, `specs/scorecard.md` (оба auto-generated, не редактировать вручную)
- **Запускает:** `sdd validate`, `sdd link-index`, `sdd scorecard` (через wrapper в `bin/sdd`)

## Что именно валидируется

- Существует `specs/constitution.md` с полем `version`
- Все L1/L2 файлы имеют `depends_on.constitution`, совпадающий с `constitution.version`
- Нет дублированных ID (`ART-NNN`, `ENT-NNN`, `INV-NNN`, `EVT-NNN`, `FEA-NNN`, `SCN-NNN`)
- Все цитируемые ID разрешаются в определения (нет dangling references)
- Каждая статья `ART-NNN` содержит ключевое слово RFC 2119 в описании (warning)
- Определённые сущности `ENT-NNN` цитируются хотя бы одним сценарием (warning; orphan = кандидат на удаление)
- **Pattern caps (cog-routing):**
  - `memory/patterns.md` ≤ 70 строк / 5.5 KB (**hard cap** — ERROR при превышении)
  - `memory/patterns/*.md` ≤ 30 строк каждый (**soft cap** — WARNING)
  - Полный протокол: [`06-patterns.md`](../06-patterns.md)

## Правила

- Команда **не** исправляет найденные проблемы автоматически. Отчёт → решение человека.
- `link-index.md` и `scorecard.md` — машинно-генерируемые. Комитить можно, редактировать — нет.
