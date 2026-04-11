<!-- L0: Core universal SDD operational rules — loaded by every /sdd:* command. HARD CAP 70 lines / 5.5KB -->

# SDD Core Patterns

Universal operational rules для работы с SDD-спеками. Загружается в начале каждой `/sdd:*` команды перед L0/L1/L2.

**HARD CAP: 70 строк / 5.5KB.** Превышение = ERROR в `/sdd:housekeeping`.

## Workflow

- Dry Run ОБЯЗАТЕЛЕН перед любым кодом, затрагивающим домен, поведение или архитектуру.
- Первый блок ответа: `## Dry Run` с Touched / Contradictions / Missing specs / Ambiguous terms / Verdict.
- `Verdict: BLOCK` запрещает код в том же ответе.
- Никогда не суммаризировать L0. Цитаты — дословные.

## Authority

- `L0 > L1 > L2 > собственное суждение`. Без исключений.
- Внутри L0: `precedence: critical > normal`.
- Неоднозначность эскалируется, не угадывается.

## Content

- RFC 2119 (`MUST / MUST NOT / SHOULD / SHOULD NOT / MAY`) обязателен в: `statement` статей L0, `rule` инвариантов L1, `priority` сценариев L2.
- Stable IDs (`ART/ENT/INV/EVT/FEA/SCN-NNN`): ровно 3 цифры, монотонные, никогда не переиспользуются.
- Один `when` на L2 сценарий. Два действия = два сценария.
- `Then` описывает наблюдаемое поведение, не внутренности.

## Files

- Каждый handbook-файл начинается с `<!-- L0: ... -->` в одну строку (≤80 chars).
- Авто-генерируемые файлы (`link-index.md`, `scorecard.md`, `evolve-log.md`, `reflect-log.md`, `foresight.md`) не редактируются вручную.
- SemVer на спеках; major bump требует ре-ревью всех L1/L2.
- `depends_on.constitution` в L1/L2 ДОЛЖЕН совпадать с `L0.version`.

## Dialects

- L2 — только Gherkin-MD (см. `02-gherkin-md.md`). Смена — через `/sdd:scenario`.
- L0 и L1 — Markdown + YAML frontmatter.

## Discipline

- SSOT: один факт — одно место определения. Остальные — ссылки.
- Append-only: `observations`, `evolve-log`, `reflect-log`, `dry-run-log` не переписываются.
- Atomic: одно правило на statement, одна сущность на блок, одно поведение на сценарий.
- Pattern routing: universal → `memory/patterns.md` (core); domain-specific → `memory/patterns/<context>.md` (satellite).
