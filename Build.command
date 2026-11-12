#!/bin/bash
# Build.command — сборка AI Chat под iOS Simulator двойным кликом в Finder.
# Шаги: проверка инструментов → генерация секретов → xcodegen → xcodebuild.
# Ключ OpenRouter не выводится в терминал.

set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR" || exit 1

SCHEME="AI Chat"
# Вне папки проекта: в Documents (iCloud) к .app добавляются метаданные Finder, и codesign их отвергает.
DERIVED_DATA="$HOME/Library/Developer/AIChatBuild"
APP_NAME="AI Chat.app"

finish() {
    local code=$1
    echo
    if [ -t 0 ]; then
        read -r -n 1 -s -p "Нажмите любую клавишу, чтобы закрыть окно..."
        echo
    fi
    exit "$code"
}

fail() {
    echo
    echo "ОШИБКА: $1"
    finish 1
}

step() {
    echo
    echo "==> $1"
}

echo "AI Chat: сборка в каталоге $PROJECT_DIR"

# 1. Инструменты
step "Проверка инструментов"
if ! xcode-select -p >/dev/null 2>&1; then
    fail "Xcode не найден. Установите Xcode из App Store и запустите его один раз."
fi
if ! command -v xcodebuild >/dev/null 2>&1; then
    fail "xcodebuild не найден. Выполните: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
fi
if ! command -v xcodegen >/dev/null 2>&1; then
    fail "xcodegen не найден. Установите его командой: brew install xcodegen (нужен Homebrew: https://brew.sh)"
fi
if ! command -v python3 >/dev/null 2>&1; then
    fail "python3 не найден. Установите Command Line Tools: xcode-select --install"
fi
echo "Инструменты на месте."

# 2. Секреты
step "Генерация секретов из .env"
if [ ! -f "$PROJECT_DIR/.env" ]; then
    echo "Файл .env не найден. Создайте его по образцу .env.example и вставьте свой ключ OpenRouter."
    echo "Сборка продолжится, но запросы к модели работать не будут."
fi
if ! python3 "$PROJECT_DIR/scripts/generate_secrets.py" "$PROJECT_DIR"; then
    fail "Не удалось сгенерировать секреты (scripts/generate_secrets.py)."
fi

# 3. Проект
step "Генерация Xcode-проекта (xcodegen generate)"
if ! xcodegen generate; then
    fail "xcodegen generate завершился с ошибкой."
fi

# 4. Сборка
step "Сборка под iOS Simulator"
if ! xcodebuild \
    -project "AI Chat.xcodeproj" \
    -scheme "$SCHEME" \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$DERIVED_DATA" \
    build; then
    fail "Сборка завершилась с ошибкой. Подробности выше в выводе xcodebuild."
fi

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/$APP_NAME"
if [ ! -d "$APP_PATH" ]; then
    fail "Сборка прошла, но .app не найден по ожидаемому пути: $APP_PATH"
fi

step "Готово"
echo "Приложение собрано: $APP_PATH"
finish 0
