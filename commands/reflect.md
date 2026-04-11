<!-- L0: Reflect on recent Dry Run outcomes — find recurring conflicts and feedback into specs -->

# /sdd:reflect

Обратная связь от практики в спеки. Анализ недавних Dry Run-отчётов: какие конфликты повторяются, какие спеки часто блокируют, какие термины модель регулярно трактует неоднозначно.

**Не путать с `/sdd:housekeeping`** (проверка целостности) **или `/sdd:foresight`** (конвергенция внутри спек). Reflect смотрит наружу — на поведение модели.

## Когда применять

- Еженедельно на проектах, где SDD активно используется
- После значимых релизов, чтобы понять, где спеки подводили
- Когда Dry Run блокирует одну и ту же задачу многократно

## Источники данных

Reflect читает два типа артефактов:

1. **`specs/dry-run-log.md`** — основной источник. Append-only лог, который пишет [`/sdd:dry-run`](sdd-dry-run.md) после каждого прогона. Формат — YAML-документы через `---`:

   ```yaml
   ---
   run: 2026-04-11T12:34:56Z
   task_summary: "implement invoice issue command"
   touched: [ART-002, ART-003, ENT-001, INV-001, SCN-001]
   contradictions: 0
   missing: 0
   ambiguous: 0
   verdict: PROCEED
   ```

2. **Session transcripts Claude Code** — `~/.claude/projects/<project-path>/*.jsonl`. Дополнительный источник для контекста, кто и когда запускал — но основные данные берутся из dry-run-log.

Если `dry-run-log.md` отсутствует — reflect предупреждает и завершается без записи. Это сигнал, что `/sdd:dry-run` не вызывался ни разу или его реализация не пишет лог.

## Шаги

1. **Собрать материал.** Найти все Dry Run-отчёты за окно (по умолчанию 14 дней):
   - `grep -l '## Dry Run' ~/.claude/projects/<this-project>/*.jsonl`
   - Или: `specs/dry-run-log.md`
2. **Извлечь метаданные из каждого отчёта:**
   - `Touched` IDs
   - `Contradictions` (если были)
   - `Missing specs` (если были)
   - `Ambiguous terms` (если были)
   - `Verdict` (PROCEED | BLOCK)
3. **Найти повторяющиеся сигналы:**
   - ID, который блокировал задачу 2+ раз → это либо плохо сформулированная статья/инвариант, либо задачи систематически пытаются её обойти
   - Термин, regularly помеченный как ambiguous → добавить в глоссарий
   - `Missing specs`, упоминающие одну и ту же сущность → создать её в L1
   - `Verdict: BLOCK` с последующим `--no-verify`-подобным обходом → flag как культурный риск
   - **3+ повторяющихся операционных блокера одинаковой природы → кандидат на новый pattern** (см. [`06-patterns.md`](../06-patterns.md)). Решить: core или satellite. Не нарушать hard cap — если core полон, сначала конденсировать существующие.
4. **Сопоставить с реальностью:** для топ-3 повторяющихся сигналов проверить, изменились ли соответствующие спеки после блокировки. Если нет — лечения не было, только симптоматика.
5. **Сформулировать отчёт:**

   ```markdown
   ## Reflect — <YYYY-MM-DD>

   **Window:** <start>..<end>
   **Dry Runs analyzed:** <N>
   **Blocked:** <K> (<K/N>%)

   ### Recurring blockers
   - `<ID>` blocked <M> times — <short pattern description>

   ### Ambiguous terms
   - `<term>` flagged <M> times — нужен в глоссарий? нужна новая статья?

   ### Missing spec patterns
   - <entity/scenario> requested <M> times — рассмотреть добавление

   ### Action items (предложения, не императивы)
   - <proposal 1>
   - <proposal 2>
   ```

6. **Записать в `specs/reflect-log.md`** (append-only) и вывести summary пользователю.

## Файлы

- **Читает:** `~/.claude/projects/**` (session transcripts, read-only), `specs/dry-run-log.md` (если есть), `memory/patterns.md`, `memory/patterns/**`
- **Пишет:** `specs/reflect-log.md` (append-only). Предложения по новым/удалённым patterns — только в отчёт; применение — вручную или через `/sdd:evolve`.

## Правила

- **Не редактировать спеки автоматически.** Reflect предлагает — решение принимает человек.
- **Не исправлять прошлые reflect-отчёты.** Append-only — история ценнее, чем эстетика.
- **Анонимизировать при необходимости.** Если session transcripts содержат чувствительные данные — не цитировать их дословно; только паттерны.
- **Доступ к transcripts зависит от инфраструктуры.** Если Claude Code хранит их в другом месте — скорректировать путь; если не хранит — команда бесполезна без альтернативного источника.
