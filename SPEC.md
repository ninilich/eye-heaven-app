# EyeHeaven — Спецификация проекта

## Общее

- **Название**: EyeHeaven
- **Платформа**: macOS 15+
- **Язык**: Swift + SwiftUI
- **Дистрибуция**: GitHub Releases (.dmg), нотаризация через Apple Developer аккаунт
- **App Store**: опционально, позже
- **Монетизация**: нет, бесплатно

---

## Функциональные требования

### 1. Таймер и паузы

Два независимых типа пауз:

| Параметр | Короткая пауза | Длинная пауза |
|---|---|---|
| Интервал | настраивается | настраивается |
| Длительность | настраивается | настраивается |
| Пре-брейк окно | за X сек до старта | за X сек до старта |
| Кнопки в пре-брейк окне | нет | Начать / Отложить / Пропустить |

---

### 2. Детекция активности (Idle Detection)

- Отслеживаем время неактивности клавиатуры и мыши
- Если неактивность ≥ длительность **длинной** паузы → засчитать как длинную паузу, сбросить таймер
- Если неактивность ≥ длительность **короткой** паузы → засчитать как короткую паузу

**Реализация**: `IOHIDGetParameter` или `CGEventSourceSecondsSinceLastEventType` — возвращает секунды с последнего события мыши/клавиатуры без необходимости Accessibility permissions.

```swift
let idleTime = CGEventSource.secondsSinceLastEventType(
    .combinedSessionState,
    eventType: .mouseMoved  // или .keyDown
)
```

---

### 3. Детекция аудио-встреч

Опциональная функция, включается в настройках. В UI помечена как **Beta**.

**Алгоритм детекции** (два условия без разрешений, работает в App Sandbox):

```
Встреча = процесс из whitelist запущен
          AND (микрофон системно активен  OR  приложение имеет видимые окна)
```

| Сценарий | Процесс | Окна | Mic | Результат |
|---|---|---|---|---|
| Zoom в трее, не в митинге | ✅ | 0 | выкл | ❌ не митинг ✅ |
| Zoom в митинге, mic вкл | ✅ | 1+ | вкл | ✅ митинг ✅ |
| Zoom в митинге, mic выкл (all-hands) | ✅ | 1+ | выкл | ✅ митинг ✅ |
| Zoom не запущен | ❌ | 0 | выкл | ❌ не митинг ✅ |

**Проверка видимых окон** (`CGWindowListCopyWindowInfo`, без Screen Recording permission):
- Zoom в трее = 0 видимых окон на нормальном слое
- Zoom в митинге = 1+ окна (галерея, шаринг)

**Проверка статуса микрофона** (`kAudioDevicePropertyDeviceIsRunningSomewhere`, без audio entitlement):
- Читаем флаг устройства — не захватываем звук сами
- Возвращает true если любое приложение сейчас использует микрофон

**Whitelist Bundle ID**:
- `us.zoom.xos` — Zoom
- `com.microsoft.teams2` — Teams
- `com.cisco.webexmeetings` — WebEx
- `com.slack.Slack` — Slack calls
- `com.loom.desktop` — Loom
- Google Meet — браузерный, не детектируется (приемлемый компромисс без Screen Recording)

**Поведение**:
- Встреча активна → не показываем окно паузы, таймер продолжает тикать
- Встреча завершилась → ждём задержку (настраивается, дефолт 1 мин) → возобновляем

---

### 4. Пре-брейк окно (Pre-Break Notification)

Кастомное окно, не нативный notification. Появляется за X секунд до паузы.

**Технические параметры окна**:
```swift
NSPanel(
    contentRect: ...,
    styleMask: .borderless,
    backing: .buffered,
    defer: false
)
panel.level = .floating
panel.isOpaque = false
panel.backgroundColor = .clear
panel.canBecomeKey = false   // не захватывает фокус
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
```

- Создаётся по одному на каждый монитор (`NSScreen.screens`)
- Позиционируется в верхней части экрана (как у BreakTimer — offset 50px сверху, по центру)
- Фреймлесс, с закруглёнными углами через SwiftUI

**Содержимое окна**:
- Текст: "Короткий перерыв через X сек" / "Длинный перерыв через X сек"
- **Прогресс-бар**: цветной, отсчитывает до старта паузы
- **Статус последних перерывов**: "Короткий: 9 мин назад · Длинный: 42 мин назад"
- Для длинной паузы: кнопки **Начать сейчас** / **Отложить на 3 мин** / **Пропустить**

**Прогресс-бар** (SwiftUI, обновление каждые 100ms):
```swift
Circle()
    .trim(from: 0, to: progress)
    .stroke(Color.accentColor, lineWidth: 4)
    .animation(.linear(duration: 0.1), value: progress)
```
или линейный:
```swift
ProgressView(value: progress)
    .progressViewStyle(.linear)
    .tint(Color.accentColor)
```

---

### 5. Окно паузы (Break Window)

Полноэкранное (или почти полноэкранное) окно поверх всего.

**Затенение фона**:
- Полупрозрачный чёрный `NSWindow` покрывает весь экран на высоком уровне
- Поверх него — окно паузы с контентом
- Степень затенения настраивается (0.0–1.0, дефолт ~0.6)
- Создаётся на каждом мониторе

```swift
let overlay = NSWindow(contentRect: screen.frame, ...)
overlay.level = .screenSaver
overlay.backgroundColor = NSColor.black.withAlphaComponent(0.6)
overlay.isOpaque = false
overlay.ignoresMouseEvents = true  // клики проходят к окну паузы
```

**Мягкий режим**:
- Окно паузы + затемнение фона
- Кнопка "Пропустить" — активна

**Жёсткий режим**:
- То же самое
- Кнопка "Пропустить" — задизейблена до конца таймера
- Нет стандартных кнопок закрытия/сворачивания (styleMask без .closable)

**Во время длинной паузы** (если включены стереограммы):
- Показываем стереограмму на весь экран
- Внизу: атрибуция ("Источник: ..., Автор: ...")
- Таймер обратного отсчёта

---

### 6. Стереограммы

**Включение**: OFF по умолчанию. При включении — скачивает каталог и изображения в фоне.

**Архитектура каталога**:
```
GitHub Releases (репо EyeHeaven)
  └── catalog.json     — манифест, stable URL: /releases/latest/download/catalog.json
  └── shark.jpg
  └── mountain.jpg
  └── ...
```

**Формат catalog.json**:
```json
{
  "version": 3,
  "images": [
    {
      "id": "shark",
      "filename": "shark.jpg",
      "url": "https://github.com/USER/eyeheaven/releases/latest/download/shark.jpg",
      "source": "vk.com/stereograms",
      "author": "Иван Петров"
    }
  ]
}
```

**Умный случайный порядок**:
- Хранилище: **SwiftData** модель `StereogramRecord(id, lastShownAt, timesShown)`
- При выборе: взвешенный рандом — приоритет тем, что показывали давно или мало раз

**Добавление новых изображений** (workflow разработчика):
1. Добавить файл изображения
2. Обновить `catalog.json` (новая запись)
3. Создать новый GitHub Release, приложить `catalog.json` и новые `.jpg`
4. Приложение подхватит при следующей проверке

**Проверка обновлений каталога**: при запуске приложения + раз в сутки.

---

### 7. Menu Bar

- Приложение живёт только в menu bar (без иконки в Dock)
- `LSUIElement = YES` в Info.plist

**Меню**:
```
● EyeHeaven
─────────────────
Следующий перерыв: 8 мин
─────────────────
⏸ Пауза / ▶ Возобновить
Пропустить следующий перерыв
─────────────────
Настройки...
─────────────────
Выйти
```

---

### 8. Настройки

```
Короткая пауза
  ├── Интервал (дефолт: 20 мин)
  ├── Длительность (дефолт: 20 сек)
  └── Предупреждение за X сек (дефолт: 10 сек)

Длинная пауза
  ├── Интервал (дефолт: 60 мин)
  ├── Длительность (дефолт: 5 мин)
  ├── Предупреждение за X сек (дефолт: 30 сек)
  ├── Максимум отложений (дефолт: 2)
  └── Разрешить пропуск: да/нет

Режим напоминания
  ├── Мягкий / Жёсткий
  └── Степень затенения фона (0–100%)

Встречи
  ├── Детекция встреч: вкл/выкл  [пометка "Beta" в UI]
  └── Задержка после встречи (дефолт: 1 мин)

Стереограммы
  ├── Включить/выключить
  └── [Обновить каталог]  /  Загружено X изображений

Система
  ├── Запуск при старте системы
  ├── Звук при начале и конце паузы: вкл/выкл
  └── Анонимная статистика использования: вкл/выкл
        [мелкий серый текст]: Один анонимный сигнал в сутки помогает нам
        понять, сколько людей пользуются приложением. Никаких личных данных.
```

---

## Технические решения

### Стек
- SwiftUI — весь UI
- AppKit — NSWindow/NSPanel для кастомных окон (SwiftUI не даёт нужного контроля над window level)
- **@Observable** (Swift 5.9+) — state management вместо устаревшего ObservableObject
- **Swift 6.2 strict concurrency** — `@MainActor` изоляция, структурированный async/await
- **SwiftData** — хранение истории показа стереограмм (вместо UserDefaults для структурированных данных)
- UserDefaults — простые настройки (интервалы, режимы)
- URLSession — скачивание каталога и изображений
- ServiceManagement — автозапуск при старте (macOS 13+)

### Idle Detection
`CGEventSource.secondsSinceLastEventType` — не требует Accessibility permissions.

### Meeting Detection
Комбо без разрешений: процесс из whitelist запущен AND (видимые окна приложения через `CGWindowListCopyWindowInfo` OR статус mic через `kAudioDevicePropertyDeviceIsRunningSomewhere`). Подробно — см. раздел 3.

### Автозапуск
```swift
import ServiceManagement
SMAppService.mainApp.register()   // macOS 13+
```

### App Sandbox
Приложение работает в App Sandbox. Entitlements:
- `com.apple.security.app-sandbox` — обязательно
- `com.apple.security.network.client` — для скачивания каталога стереограмм

Никаких запросов разрешений у пользователя при первом запуске.

### Хранение данных
Все пути — только через `FileManager.default.urls(for:in:)`. Никогда не хардкодить `~/Library/...`. В sandbox данные автоматически попадают в `~/Library/Containers/com.*.EyeHeaven/Data/`.

### Скачивание изображений
- Фоновый `URLSession` с низким приоритетом
- Путь через `FileManager` → Application Support → `EyeHeaven/stereograms/`
- Проверка по имени файла — не перекачивать уже скачанные

---

### Инструменты разработки (Claude Code)

- **SwiftFormat** — установлен (`brew install swiftformat`). Hook в `.claude/settings.local.json` автоматически форматирует каждый сохранённый `.swift` файл.
- **SwiftLint** — установлен (`brew install swiftlint`). Hook проверяет каждый `.swift` файл после сохранения.
- **XcodeBuildMCP** — заблокирован enterprise-политикой, не используется.

### Рабочий процесс сборки

Xcode 26 использует `PBXFileSystemSynchronizedRootGroup` — все файлы в папке `EyeHeaven/` подхватываются автоматически. Ручное добавление файлов не нужно.

1. Claude создаёт/редактирует `.swift` файлы на диске
2. Сборка: `Cmd+B` в Xcode
3. Ошибки компиляции копируются в чат → Claude исправляет

---

## Open Source для изучения

| Проект | Что взять | Лицензия |
|---|---|---|
| [BreakTimer](https://github.com/tom-james-watson/breaktimer-app) | Логика пре-брейк окна, UX кнопок | GPL-3 (только идеи, не код) |
| [Stretchly](https://github.com/hovancik/stretchly) | Idle detection логика, meeting detection | BSD-2 (только идеи) |
| [EyeBreak](https://github.com/an09mous/EyeBreak) | Swift, full-screen blocker, sleep/wake | MIT (можно смотреть код) |
| [SaveMyEyes](https://github.com/masich/SaveMyEyes) | Swift, SwiftUI, idle detection | Apache-2.0 (можно смотреть код) |

---

## Дистрибуция

1. Собрать `.app` в Xcode (Release конфигурация)
2. Упаковать в `.dmg`
3. Нотаризировать через `xcrun notarytool` (нужен Apple Developer аккаунт $99/год)
4. Создать GitHub Release, приложить `.dmg`
5. Обновить `catalog.json` с новыми стереограммами при необходимости

---

## Локализация

Приложение полностью локализовано. Все UI-строки через `String(localized:)` / `LocalizedStringKey`.

**Языки v1**: English (базовый), Deutsch, Français, Español, Italiano, Русский, Português (BR), 日本語, 中文(简体)

- Язык интерфейса — отдельная настройка в разделе "Система", по умолчанию язык системы
- Переводы генерируются при разработке, хранятся в `.strings` / `.stringsdict` файлах
- При добавлении новых строк — переводить сразу во все 9 языков

---

## Аналитика (Heartbeat)

Анонимная статистика активных пользователей через [heartbeat-tracker](https://github.com/maierru/heartbeat-tracker).

- Один анонимный пинг в сутки с SHA256 хешем device ID (не обратимо)
- Никаких IP-адресов, геолокации, персональных данных
- Статистика видна на `https://heartbeat.work/com.ninilich.EyeHeaven`
- Пользователь может отказаться в настройках (opt-out, по умолчанию вкл)

**Задачи перед релизом**:
- [ ] Убедиться что сетевые ошибки молча игнорируются (не крашат приложение)
- [ ] Добавить раздел Device ID в App Store privacy nutrition label
- [ ] Написать минимальную Privacy Policy страницу (GitHub Pages или отдельный URL)
- [ ] Упомянуть анонимную статистику в onboarding

---

## Прогресс реализации

### ✅ Реализовано

| Commit | Что сделано |
|---|---|
| `0df0309` | **Foundation**: menu bar (NSStatusItem), TimerEngine, IdleDetector, BreakScheduler, AppSettings |
| `ce873c2` | **Pre-break fix**: закрытие баннера не пропускает перерыв (`preBreakAcknowledged` флаг) |
| `4d9c089` | **Break window**: navy gradient карточка поверх затемнённого overlay |
| `6242ac9` | **Sound**: мягкий Glass-звук при начале и конце любого перерыва |
| `eb9d7fd` | **Settings**: NSTabViewController (.tabStyle = .toolbar), 4 вкладки (Breaks / System / Stereograms / About), IntField вместо Stepper, локализация 9 языков |
| `54f26e7` | **Menu actions**: ручной запуск короткого/длинного перерыва, Pause timer/Resume timer, удалён пункт Skip next break |
| `2565c1d` | **Break UI**: обновлён экран длинного перерыва со стереограммой (крупнее изображение, таймер mm:ss, переработанная нижняя панель управления) |
| `c87c083` | **UI refactor**: единый стиль action-кнопок на всех break-экранах (Break/PreBreak/StereogramBreak) |

**Что работает сейчас:**
- Menu bar с меню (ручной старт короткого/длинного перерыва, Pause timer/Resume timer, настройки, выйти)
- Короткие и длинные перерывы по таймеру
- Idle detection без разрешений (`CGEventSource`)
- Пре-брейк уведомление (floating NSPanel)
- Окно паузы поверх всего (screenSaver level) + затемнение на каждом мониторе
- Звуки начала/конца
- Длинный перерыв со стереограммой: увеличенное изображение, таймер в формате mm:ss, кнопки Skip/Next в нижней панели
- Единый визуальный стиль action-кнопок на экранах Break / PreBreak / StereogramBreak
- Нативное окно настроек со всеми параметрами

---

### 🔲 Не реализовано

**Phase 5 (продолжение)**
- [x] Respect Focus Mode (`respectFocusMode` настройка)

**Phase 6 — Стереограммы**
- [x] SwiftData модель `StereogramRecord`
- [x] `CatalogService`: скачивание и кеширование `catalog.json` + изображений, фоновые обновления, pruning
- [x] `StereogramPicker`: взвешенный рандом
- [x] `StereogramBreakView`: полноэкранное отображение, атрибуция, кнопки Next/End Break
- [x] Расширенный `StereogramsSettingsView`: прогресс-бар, авто-обновление, хранение
- [x] `ADDING_IMAGES.md`: инструкция для добавления картинок в каталог
- [x] Локальное тестирование выполнено на 4 тестовых стереограммах (через sandbox cache)
- [x] Локальный тестовый режим: автообновление каталога временно отключено (`defaults write org.ninil.EyeHeaven stereogramsAutoUpdate -bool false`)
- [ ] Перед релизом вернуть автообновление (`defaults write org.ninil.EyeHeaven stereogramsAutoUpdate -bool true`)

**Phase 7 — Полировка и релиз**
- [ ] Heartbeat: анонимный пинг раз в сутки
- [ ] Onboarding при первом запуске
- [ ] Проверка обновлений приложения
- [ ] Локализация: полировка автоперевода
- [ ] Нотаризация и .dmg для GitHub Releases

**Phase 8 — Meeting Detection (последняя)**
- [ ] `MeetingDetector.swift`: процессы (NSWorkspace) + окна (CGWindowList) + mic статус (CoreAudio)
- [ ] Интеграция в `BreakScheduler` (откладывает паузу на `meetingDelay` секунд)

---

## Что дальше

1. **Bugfix sprint (сейчас, приоритет)**: стабилизировать текущую функциональность
  - Сбор и приоритизация багов (critical/high/medium)
  - Исправление регрессий после UI/меню изменений
  - Smoke-проверка основных сценариев (таймер, окна, стереограммы, настройки)
  - Подтверждение стабильности перед переходом к новым фичам

2. **Phase 7 (после bugfix sprint)**: довести релизную готовность
  - Heartbeat (анонимный пинг раз в сутки)
  - Onboarding при первом запуске
  - Проверка обновлений приложения
  - Финальная полировка локализации
  - Нотаризация и `.dmg` для GitHub Releases

3. **Phase 8**: реализовать Meeting Detection
  - `MeetingDetector.swift` (process + windows + mic status)
  - Интеграция в `BreakScheduler` через `meetingDelay`

4. **Перед релизом**: вернуть автообновление каталога после локального тестового режима
  - `defaults write org.ninil.EyeHeaven stereogramsAutoUpdate -bool true`

---

## Что не делаем (намеренно)

- Нет iCloud sync
- Нет In-App Purchases
- Нет упражнений для глаз (только паузы + стереограммы)
- Нет iOS версии
