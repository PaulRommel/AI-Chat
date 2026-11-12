# Архитектура приложения

Статус: черновик этапа 02. Уточняется по мере реализации.

## Принципы

- SwiftUI + MVVM. Views не содержат сетевой и бизнес-логики.
- Swift Concurrency: `async/await`, `Task` с явной отменой, обновления UI через `@MainActor`.
- Сеть отделена от UI: протокол провайдера AI, реализация под OpenRouter.
- Минимальная версия iOS 18.0. API новее iOS 18 — только с `#available` и запасной реализацией.
- Зависимости только через SPM. Для текущего объёма сторонние пакеты не планируются.

## Слои

```
Views (SwiftUI)  ->  ViewModels (@MainActor)  ->  Services (протоколы)  ->  Networking / Persistence
```

- **App** — точка входа, `AppState`, корневая навигация.
- **Core/Models** — `Chat`, `Message` (SwiftData `@Model`), `MessageStatus`, `MessageRole`.
- **Core/Networking** — `APIConfiguration` (модель и провайдер из конфигурации), `AIProvider` (протокол), `OpenRouterProvider`, `APIClient` (URLSession), `StreamingParser` (SSE).
- **Core/Persistence** — `PersistenceController` (контейнер SwiftData).
- **Core/Theme** — `AppTheme`, `ThemeManager` (светлая/тёмная/системная, хранится в `UserDefaults`/`@AppStorage`).
- **Features/Chat, Features/History, Features/Settings** — Views и ViewModels по фичам.

## AI-слой

- Протокол `AIProvider`: отправка истории, получение потока фрагментов `AsyncThrowingStream<String, Error>`.
- `OpenRouterProvider`: POST `https://openrouter.ai/api/v1/chat/completions`, `stream: true`, `Authorization: Bearer <key>`.
- Модель задаётся в конфигурации, а не в коде. Для смены провайдера или модели достаточно другой конфигурации или реализации протокола.
- Ответ — SSE: строки `data: {...}`, терминатор `data: [DONE]`. Формат проверяется на реальном ответе API (этап 12); протокол каждого провайдера разбирается отдельно.
- Остановка: отмена `Task`, которая держит поток. Уже полученный текст сохраняется со статусом `partial`.
- Ошибки: нет сети, таймаут, 401/403 (ключ отсутствует или недействителен), 429 (лимит), 5xx, разрыв потока, ошибка декодирования. Каждая ошибка переводится в понятное состояние с кнопкой «Повторить».

## Хранение

- SwiftData: `Chat` (1-N) `Message`, сортировка по `updatedAt`.
- При отправке сообщение пользователя и пустое сообщение ассистента сохраняются до запроса. Повтор переиспользует сообщение и не создаёт дубликатов.

## Ключ API

- Ключ не хранится открытым текстом в исходниках.
- Способ размещения ключа — открытый вопрос (см. `docs/PLAN.md`), пока не решён.
- Если ключ отсутствует или недействителен, приложение показывает понятное состояние ошибки и не падает.

## Сборка

- `project.yml` — единственный источник правды для Xcode-проекта. `.xcodeproj` генерируется и не коммитится.
- `Build.command` — `xcodegen generate` и `xcodebuild` под доступный iOS Simulator с выводом пути к `.app`.
