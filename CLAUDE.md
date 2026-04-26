# EyeHeaven — CLAUDE.md

macOS menu bar приложение для отдыха глаз. Swift + SwiftUI, macOS 15+.
Полная спецификация: `SPEC.md`.

**Bundle ID**: `org.ninil.EyeHeaven`
**Xcode**: 26.4.1 — использует `PBXFileSystemSynchronizedRootGroup`, файлы на диске подхватываются автоматически, ручное "Add Files to..." не нужно.
**Локализация**: `.xcstrings` формат (`LOCALIZATION_PREFERS_STRING_CATALOGS = YES`), не `.strings`.
**App Sandbox**: включён через Build Settings (`ENABLE_APP_SANDBOX = YES`), отдельный `.entitlements` файл не нужен.
**Default actor isolation**: `@MainActor` (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`).

---

## Структура проекта

```
EyeHeaven/
├── App/
│   ├── EyeHeavenApp.swift          — точка входа, AppDelegate, menu bar setup
│   └── AppDelegate.swift           — NSStatusItem, LSUIElement
├── Core/
│   ├── TimerEngine.swift           — главный таймер, логика коротких/длинных пауз
│   ├── IdleDetector.swift          — CGEventSource idle time detection
│   ├── MeetingDetector.swift       — процессы (NSWorkspace) + окна (CGWindowList) + mic статус (CoreAudio)
│   └── BreakScheduler.swift        — оркестратор: когда показывать какое окно
├── Windows/
│   ├── PreBreakWindowController.swift   — пре-брейк окно (NSPanel, floating)
│   ├── BreakWindowController.swift      — окно паузы (NSWindow, screenSaver level)
│   └── OverlayWindowController.swift    — затемнение фона (per-screen)
├── Views/
│   ├── PreBreakView.swift          — SwiftUI контент пре-брейк окна
│   ├── BreakView.swift             — SwiftUI контент окна паузы
│   ├── StereogramView.swift        — отображение стереограммы + атрибуция
│   └── SettingsView.swift          — окно настроек
├── Stereograms/
│   ├── CatalogService.swift        — загрузка catalog.json, скачивание изображений
│   ├── StereogramPicker.swift      — взвешенный рандом выбор изображения
│   └── Models/StereogramRecord.swift — SwiftData модель истории показа
├── Settings/
│   └── AppSettings.swift           — @Observable, UserDefaults-backed настройки
└── Resources/
    └── Info.plist                  — LSUIElement = YES
```

---

## Архитектурные правила

### Обязательно
- **@Observable** для всех state-объектов. Никакого `ObservableObject` / `@Published`.
- **Swift 6.2 strict concurrency**: весь UI-код изолирован `@MainActor`. Фоновые задачи через `Task.detached` или `actor`.
- **SwiftData** для `StereogramRecord`. UserDefaults только для примитивных настроек.
- **NSWindow/NSPanel** для кастомных окон — не использовать SwiftUI `.sheet` или `.window` для break/overlay окон.
- Один `BreakScheduler` — единственный источник правды о текущем состоянии таймера.

### Запрещено
- `ObservableObject`, `@Published`, `@StateObject`, `@EnvironmentObject` — устаревшие паттерны.
- `DispatchQueue.main.async` — заменять на `await MainActor.run` или `@MainActor`.
- Хранить историю стереограмм в UserDefaults — только SwiftData.
- Модифицировать `.xcodeproj` файл программно — только вручную через Xcode.
- Использовать `Accessibility API` для idle detection — есть `CGEventSource` без разрешений.

---

## Ключевые технические решения

### Idle Detection (без Accessibility permissions)
```swift
let idle = CGEventSource.secondsSinceLastEventType(
    .combinedSessionState,
    eventType: .mouseMoved
)
```
Проверять каждые 10 секунд через `Timer.publish`.

### Meeting Detection
Опциональная функция (настройка вкл/выкл), в UI помечена как **Beta**.
Два условия без разрешений, оба работают в App Sandbox:

```swift
let meetingBundleIDs: Set<String> = [
    "us.zoom.xos", "com.microsoft.teams2",
    "com.cisco.webexmeetings", "com.slack.Slack", "com.loom.desktop"
]

// Условие 1: процесс из whitelist запущен
let processRunning = NSWorkspace.shared.runningApplications.contains {
    meetingBundleIDs.contains($0.bundleIdentifier ?? "")
}

// Условие 2а: приложение имеет видимые окна на нормальном слое
// (CGWindowListCopyWindowInfo не требует Screen Recording permission для метаданных)
let hasVisibleWindows: Bool = {
    guard let windows = CGWindowListCopyWindowInfo(
        [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
    ) as? [[String: Any]] else { return false }
    return windows.contains {
        meetingBundleIDs.contains(
            NSWorkspace.shared.runningApplications
                .first { $0.processIdentifier == $0[kCGWindowOwnerPID as String] as? Int32 }?
                .bundleIdentifier ?? ""
        ) && ($0[kCGWindowLayer as String] as? Int) == 0
    }
}()

// Условие 2б: микрофон активен (статус устройства, не захват — без audio entitlement)
func isMicActive() -> Bool {
    var deviceID = AudioDeviceID(kAudioObjectUnknown)
    var size = UInt32(MemoryLayout<AudioDeviceID>.size)
    var addr = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultInputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &deviceID)
    var isRunning: UInt32 = 0
    size = UInt32(MemoryLayout<UInt32>.size)
    addr.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere
    AudioObjectGetPropertyData(deviceID, &addr, 0, nil, &size, &isRunning)
    return isRunning != 0
}

// Итог: встреча = процесс запущен И (есть окна ИЛИ mic активен)
let inMeeting = processRunning && (hasVisibleWindows || isMicActive())
```

### Break Window (не захватывает фокус, поверх всего)
```swift
panel.level = .floating          // пре-брейк
overlay.level = .screenSaver     // затемнение
breakWindow.level = .screenSaver + 1  // окно паузы поверх overlay
panel.canBecomeKey = false       // не крадёт фокус
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
```

### Мультимонитор
```swift
NSScreen.screens.forEach { screen in
    // создать overlay + break window для каждого экрана
}
```

### Автозапуск (macOS 13+)
```swift
import ServiceManagement
try SMAppService.mainApp.register()
```

### SwiftData модель
```swift
@Model class StereogramRecord {
    var imageId: String
    var lastShownAt: Date
    var timesShown: Int
}
```

### Взвешенный рандом стереограмм
Вес = `daysSinceLastShown / (timesShown + 1)`. Чем давнее и реже — тем выше приоритет.

---

## Настройки (UserDefaults через @Observable)

```swift
@Observable class AppSettings {
    var shortBreakInterval: TimeInterval = 20 * 60
    var shortBreakDuration: TimeInterval = 20
    var shortBreakWarning: TimeInterval = 10
    var longBreakInterval: TimeInterval = 60 * 60
    var longBreakDuration: TimeInterval = 5 * 60
    var longBreakWarning: TimeInterval = 30
    var longBreakMaxPostpones: Int = 2
    var longBreakAllowSkip: Bool = true
    var hardMode: Bool = false
    var overlayOpacity: Double = 0.6
    var meetingDetectionEnabled: Bool = false  // Beta — выкл по умолчанию
    var meetingDelay: TimeInterval = 60
    var stereogramsEnabled: Bool = false
    var launchAtLogin: Bool = false
    var soundEnabled: Bool = true
    var respectFocusMode: Bool = true
    var heartbeatEnabled: Bool = true
    var appLanguage: String = "system"  // "system" или BCP-47 код: "en", "de", "fr", "es", "it", "ru", "pt-BR", "ja", "zh-Hans"
}
```

---

## Команды сборки

```bash
# Сборка (вручную — XcodeBuildMCP заблокирован enterprise-политикой)
xcodebuild -project EyeHeaven.xcodeproj -scheme EyeHeaven -configuration Release build

# Нотаризация
xcrun notarytool submit EyeHeaven.dmg --apple-id ... --team-id ... --password ...
xcrun stapler staple EyeHeaven.app
```

---

## App Sandbox и хранение данных

Приложение работает в **App Sandbox**. Все пути — только через `FileManager`, никогда хардкод.

```swift
// Правильно — автоматически резолвится в sandbox-контейнер:
// ~/Library/Containers/com.yourname.EyeHeaven/Data/Library/Application Support/
let appSupport = FileManager.default.urls(
    for: .applicationSupportDirectory,
    in: .userDomainMask
).first!
let stereogramsDir = appSupport.appendingPathComponent("EyeHeaven/stereograms/")
```

### Entitlements (минимальные, без запросов у пользователя)
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
```

---

## Каталог стереограмм

- URL манифеста: `https://github.com/USER/eyeheaven/releases/latest/download/catalog.json`
- Изображения кешируются через `FileManager` в Application Support (см. выше)
- Проверка обновлений: при запуске + раз в 24 часа
- Формат `catalog.json`: см. SPEC.md раздел "Стереограммы"

---

## Что не реализовываем

- iCloud sync
- Аналитика / телеметрия
- In-App Purchases
- Упражнения для глаз
- iOS версия
