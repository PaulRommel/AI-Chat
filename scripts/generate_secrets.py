#!/usr/bin/env python3
"""Читает .env и генерирует AIChat/Core/Networking/Generated/GeneratedSecrets.swift.

Ключ сохраняется в обфусцированном виде (XOR со случайной маской), открытым текстом в файлах проекта не хранится.
Сгенерированный файл исключён из git.
"""
import pathlib
import secrets
import sys


def read_env(path: pathlib.Path) -> dict:
    values = {}
    if not path.exists():
        return values
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def swift_array(data: bytes) -> str:
    return ", ".join(str(b) for b in data)


def main() -> int:
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    env = read_env(root / ".env")
    api_key = env.get("OPENROUTER_API_KEY", "")
    model = (env.get("OPENROUTER_MODEL") or "openrouter/free").replace('"', "")
    output = root / "AIChat" / "Core" / "Networking" / "Generated" / "GeneratedSecrets.swift"
    if not api_key and output.exists():
        print("warning: OPENROUTER_API_KEY пуст или .env не найден. Прежний GeneratedSecrets.swift сохранён.", file=sys.stderr)
        return 0

    mask = secrets.token_bytes(32)
    obfuscated = bytes(b ^ mask[i % len(mask)] for i, b in enumerate(api_key.encode("utf-8")))

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        "// Сгенерировано scripts/generate_secrets.py из .env. Не редактировать. Не попадает в git.\n"
        "enum GeneratedSecrets {\n"
        f'    static let model = "{model}"\n'
        f"    static let mask: [UInt8] = [{swift_array(mask)}]\n"
        f"    static let obfuscatedKey: [UInt8] = [{swift_array(obfuscated)}]\n"
        "}\n",
        encoding="utf-8",
    )

    if not api_key:
        print("warning: OPENROUTER_API_KEY пуст в .env. Приложение покажет «API-ключ не настроен».", file=sys.stderr)
    print(f"generated: {output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
