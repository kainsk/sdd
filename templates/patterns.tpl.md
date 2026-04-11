<!-- L0: Core SDD patterns template — copy to your project's memory/patterns.md -->

# SDD Core Patterns — <YOUR PROJECT>

Universal operational rules для работы с SDD-спеками этого проекта. Загружается каждой `/sdd:*` командой.

**HARD CAP: 70 строк / 5.5KB.** Превышение = ERROR в housekeeping.

<!--
  Ниже — канонические patterns, работающие на любом SDD-проекте. Заменять осторожно.
  Добавляйте проектные УНИВЕРСАЛЬНЫЕ правила под каждой секцией.
  Правила, специфичные для bounded context → memory/patterns/<context>.md (soft cap 30 строк).
-->

## Workflow

- Dry Run ОБЯЗАТЕЛЕН перед любым кодом, меняющим домен, поведение или архитектуру.
- `Verdict: BLOCK` запрещает код в том же ответе.
- Никогда не суммаризировать L0. Цитаты — дословные.

## Authority

- `L0 > L1 > L2`. Неоднозначность эскалируется, не угадывается.

## Content

- RFC 2119 обязателен в `statement` L0, `rule` L1, `priority` L2.
- Stable IDs: ровно 3 цифры, монотонные, никогда не переиспользуются.
- Один `when` на сценарий.

## Files

- L0-комментарий в каждом handbook-файле.
- Авто-генерируемые файлы не редактируются вручную.
- `depends_on.constitution` в L1/L2 совпадает с `L0.version`.

<!-- Добавляйте проектные universal rules ниже. Держитесь в рамках hard cap. -->
