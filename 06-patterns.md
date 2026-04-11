<!-- L0: Pattern routing — universal core + domain-specific satellites for SDD operational rules -->

# Pattern Routing

Где живут **операционные правила** Claude, работающего с SDD-спеками: как их организовать, как загружать, как удерживать в рамках caps.

Механика заимствована у [cog](https://github.com/marciopuga/cog) — «core vs satellite» routing, адаптированный под SDD-контекст.

---

## 1. Зачем

Правила работы с SDD-спеками ортогональны содержимому спек:

- **Содержимое спек** (`ART/ENT/INV/SCN`) — «что делает проект»
- **Patterns** — «как Claude работает со спеками: что читать первым, когда останавливаться, как форматировать ответ»

Без явной организации patterns расползаются по system prompt, `CLAUDE.md`, отдельным заметкам, и теряют SSOT. Pattern routing — это структурное решение: разделить universal rules (**core**) и context-specific rules (**satellite**).

---

## 2. Структура

```
memory/
├── patterns.md              # CORE: universal SDD rules — hard cap 70 lines / 5.5KB
└── patterns/                # SATELLITE: domain-specific rules — soft cap 30 lines each
    ├── billing.md
    ├── user-access.md
    └── ...
```

| Слой | Файл | Когда загружается |
|---|---|---|
| **Core** | `memory/patterns.md` | В начале **каждой** `/sdd:*` команды, до спек |
| **Satellite** | `memory/patterns/<context>.md` | Только когда задача касается этого bounded context |

---

## 3. Routing

Как команда решает, какие satellites загрузить:

1. Прочитать core `memory/patterns.md`.
2. Определить bounded context(s), затронутые задачей:
   - По именам в тексте задачи (`billing`, `user-access`, …)
   - По путям спек-файлов, которые затрагивает задача
   - По префиксам упоминаемых ID (если соглашение принято)
3. Для каждого затронутого context — загрузить `memory/patterns/<context>.md`, если файл существует.
4. Если satellite отсутствует — **не ошибка**; работаем только с core.
5. Если satellite найден, но его `## ...` секции противоречат core — **ошибка**, эскалировать.

---

## 4. Caps

| Файл | Cap | Нарушение |
|---|---|---|
| `memory/patterns.md` | **HARD 70 строк / 5.5 KB** | ERROR в `sdd-validate.sh` |
| `memory/patterns/*.md` | **SOFT 30 строк** | WARNING |

Caps механизированы в `bin/sdd-validate.sh` и `bin/sdd-scorecard.sh`.

### Зачем caps

- **Атомарность.** Короткий файл заставляет формулировать каждое правило как императив, без воды.
- **Читабельность.** Файл, который можно прочитать за 30 секунд, реально прочитывают.
- **Signal-to-noise.** Цена превышения cap — ошибка валидации — заставляет конденсировать, а не накапливать.
- **Антипаттерн «doc rot».** Без cap patterns превращаются в parallel-repo документацию, которую никто не читает.

Если hard cap мешает — это сигнал разделить правила между core и satellite, а не поднять cap.

---

## 5. Что писать в patterns

| Core (universal) | Satellite (context-specific) |
|---|---|
| Dry Run перед кодом | `Money` только через `ENT-010` |
| RFC 2119 в statements | Мульти-валюта запрещена (`INV-003`) |
| Stable IDs формата 3 цифры | Offline-first для billing (`ART-003`) |
| `L0 > L1 > L2` authority | `Invoice.total` всегда пересчитывается из lines |

**Правило классификации:** если правило применимо к **любому** проекту, использующему SDD — оно core. Если касается **специфической доменной области** — satellite.

---

## 6. Что **не** писать в patterns

- **Факты спек** (атрибуты сущностей, формулировки инвариантов) → это L1/L2, не patterns
- **Детали реализации** (как именно проверять, в каком коде) → это код
- **Исторические заметки** (когда добавили, кто решил) → это `git log`
- **Пользовательские предпочтения** (стиль кавычек, табы vs пробелы) → `.editorconfig`
- **Многословные объяснения** → patterns императивны, не дидактичны

---

## 7. Жизненный цикл pattern

1. **Рождение.** Pattern появляется одним из трёх путей:
   - Копируется из `templates/patterns.tpl.md` при `/sdd:setup` (стартовый набор core)
   - Создаётся вручную при первой итерации проекта
   - Дистиллируется из повторяющихся блокеров через `/sdd:reflect` (3+ одинаковых сигнала → новый pattern)
2. **Эволюция.** Изменения идут через `/sdd:evolve`:
   - Scorecard показывает, что pattern не работает → удалить или переформулировать
   - Новый pattern не помещается в hard cap → конденсировать старые
   - Scope правила расширился — перенос из satellite в core
   - Scope сузился — перенос из core в satellite
3. **Смерть.** Pattern устарел или заменён:
   - Удалить целиком. В отличие от `ART/ENT-NNN` спек, patterns номеров не имеют — история в `git log`

---

## 8. Связь с Dry Run

`/sdd:dry-run` загружает patterns **первыми**, до спек. Полный порядок:

```
1. memory/patterns.md                  (core, always)
2. memory/patterns/<context>.md        (satellites matching task)
3. specs/constitution.md               (L0)
4. specs/glossary, если есть
5. specs/domain/*.md                   (L1 slice)
6. specs/scenarios/*.md                (L2 slice)
7. Task
```

**Почему patterns первыми.** Они задают, *как читать* спеки. Без них модель не знает, что L0 pinned, что Dry Run обязателен, что `when` один на сценарий. Core patterns — это boot sequence.

---

## 9. Связь с golden rules

Pattern routing — это **механизация** [Правила 2 (SSOT)](04-golden-rules.md#rule-2--single-source-of-truth--единственный-источник-правды) на уровне операционных правил:

- Golden Rules в `04-golden-rules.md` — что должно быть истинно в спеках
- Patterns в `memory/patterns.md` — как Claude обеспечивает эту истинность при работе со спеками

Golden Rules читаются раз при онбординге проекта и редко меняются. Patterns читаются каждой командой и могут эволюционировать.

---

## 10. Примеры в этом репо

| Файл | Назначение |
|---|---|
| Файл | Назначение |
|---|---|
| [`memory/patterns.md`](memory/patterns.md) | Core для самого справочника (dogfood) |
| [`templates/patterns.tpl.md`](templates/patterns.tpl.md) | Стартер core для новых проектов |

Satellite-файлов (`memory/patterns/<context>.md`) в репозитории нет: это справочник о toolkit, не конкретный проект. В целевом проекте сюда лягут файлы вроде `memory/patterns/billing.md`, `memory/patterns/user-access.md` и т. д.

Dogfood-проверка (core patterns справочника):

```bash
sdd test
# регрессионные тесты, включая hard cap на memory/patterns.md
```
