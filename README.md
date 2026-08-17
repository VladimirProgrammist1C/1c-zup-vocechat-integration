# 🧩 Интеграция 1С:ЗУП 3.1 с VoceChat

Универсальное расширение для отправки уведомлений из 1С в локальный мессенджер VoceChat.

## 📦 Что внутри
- `src/` — исходники в формате EDT (XML) с полной историей разработки
- `docs/` — БТ, ТЗ, ADR, руководство пользователя
- `docker/` — тестовый стенд (ZUP + PostgreSQL + VoceChat)

## 🚀 Быстрый старт (тестовый стенд)

Для проверки работы расширения без установки полной инфраструктуры:

1. Перейдите в папку `docker`:
   ```bash
   cd docker
   ```
2. Запустите стенд:
   ```bash
   docker-compose up -d
   ```

После запуска:
- PostgreSQL доступен на порту `5433`
- VoceChat доступен на `http://localhost:3001`

## ⚙️ Настройка переменных окружения

Для изменения паролей или других параметров:

1. Скопируйте файл `docker/.env.example` в `docker/.env`.
2. Откройте `docker/.env` и измените значения переменных.
3. Запустите стенд командой `docker-compose up -d`.

Пример содержимого `.env`:
```ini
DB_PASSWORD=MySuperSecretPassword
VOCECHAT_ADMIN_PASSWORD=MyVoceChatPassword
```

## ❓ Часто задаваемые вопросы (FAQ)

### Как подключить стенд к моей существующей инфраструктуре?

По умолчанию сервисы работают в изолированной сети `zup-integration-net`.
Если у вас уже запущена основная инфраструктура (например, из репозитория `1c-home-infrastructure`) и вы хотите, чтобы контейнеры видели друг друга (например, для мониторинга):

1. Откройте файл `docker/docker-compose.yml`.
2. Найдите секцию `networks` в конце файла.
3. Замените имя `zup-integration-net` на имя вашей сети (например, `1c-infrastructure`).
4. Также замените имя сети в секциях `services -> postgres -> networks` и `services -> vocechat -> networks`.
5. Пересоберите и запустите стенд:
   ```bash
   docker-compose down
   docker-compose up -d --build
   ```

## 🔗 Связанные проекты

- **[1c-home-infrastructure](https://github.com/VladimirProgrammist1C/1c-home-infrastructure)** — домашняя инфраструктура, в которой работает VoceChat: именно этот мессенджер принимает HR-уведомления расширения.
- **[grafinya-monitoring-stack](https://github.com/VladimirProgrammist1C/grafinya-monitoring-stack)** — импортозамещённый контур мониторинга (Графиня + Victoria Metrics). Технически не связан с расширением, но использует тот же VoceChat: HR-уведомления идут в `#hr_notify`, технические алерты — в `#alerts` и `#vm-alerts`.

## 🛠️ Технологии
- 1C:Enterprise 8.3 (EDT)
- PostgreSQL 16
- VoceChat Server
- Docker Compose
