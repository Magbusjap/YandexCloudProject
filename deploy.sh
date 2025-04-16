#!/bin/bash
# Скрипт для деплоя проекта n8n

# Перейти в директорию проекта
cd "/d/0. Job, Learn, Chill etc/Git-projects/YandexCloudProject" || { echo "Не удалось перейти в директорию"; exit 1; }

# Получить последние изменения из репозитория (если проект хранится в Git)
git pull origin main

# Обновить образы Docker
docker-compose pull

# Перезапустить контейнеры
docker-compose down
docker-compose up -d

echo "Деплой завершён успешно."
