<!-- L0: Deep-search the lifecycle of an ID across specs, code, and git history -->

# /sdd:history

Полный поиск упоминаний одного идентификатора по всем уровням спек, коду и git-истории.

## Использование

```
/sdd:history ART-003
/sdd:history ENT-001
/sdd:history INV-017
```

## Шаги

1. **Распарсить аргумент.** Валидный формат: `^(ART|ENT|INV|EVT|FEA|SCN)-[0-9]+$`. Иначе — отклонить и показать примеры.
2. **Найти определение:** `grep -rn "^### <ID>" specs/`. Если не найдено — пометить как *undefined*.
3. **Найти все упоминания в специфицированиях:** `grep -rn "<ID>" specs/`.
4. **Найти упоминания в коде:** `grep -rn "<ID>" --include='*.go' --include='*.ts' --include='*.py' --include='*.md' .` (исключая `specs/`).
5. **Git-история:**
   - Когда ID появился: `git log --diff-filter=A -S "<ID>" --format="%h %ai %s" -- specs/`
   - Последнее изменение строки с ID: `git log -1 -p -S "<ID>" -- specs/`
   - Все коммиты, трогавшие ID: `git log --oneline -S "<ID>" -- specs/`
6. **Построить отчёт:**

   ```markdown
   ## History of `<ID>`

   ### Definition
   - File: `<path:line>`
   - Current form: <цитата заголовка>

   ### References in specs (<count>)
   - `<path:line>` — <контекст в одной строке>
   - ...

   ### References in code (<count>)
   - `<path:line>` — <контекст>
   - ...

   ### Git lifecycle
   - Introduced: <commit> <date> "<message>"
   - Last modified: <commit> <date> "<message>"
   - Total commits touching: <N>

   ### Current status
   - <active | orphan | deprecated | undefined>
   ```

## Файлы

- **Читает:** `specs/**`, исходники проекта, git history
- **Пишет:** ничего (отчёт в чат)

## Правила

- Не скрывать undefined/dangling состояния — это полезная диагностика.
- Если ID — deprecated (помечен в спеке), явно указать это в отчёте.
- Не путать `ENT-003` с `ENT-0030` — grep должен быть с границами слова.
