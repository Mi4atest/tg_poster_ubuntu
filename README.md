# TG Poster - Система автоматизированного постинга в социальные сети

Система для автоматизированного постинга контента в социальные сети (VK, Telegram, Instagram) через Telegram бота.

## Требования

- Ubuntu 24.04
- Python 3.10+
- PostgreSQL
- Nginx
- Supervisor

## Инструкция по установке на Ubuntu 24.04

### 1. Обновление системы

```bash
sudo apt update
sudo apt upgrade -y
```

### 2. Установка необходимых пакетов

```bash
sudo apt install -y python3 python3-pip python3-venv postgresql postgresql-contrib nginx supervisor git
```

### 3. Клонирование репозитория

```bash
git clone https://github.com/yourusername/tg_poster_ubuntu.git
cd tg_poster_ubuntu
```

### 4. Настройка базы данных PostgreSQL

```bash
# Создание пользователя и базы данных
sudo -u postgres psql -c "CREATE USER tg_poster WITH PASSWORD 'your_password';"
sudo -u postgres psql -c "CREATE DATABASE tg_poster OWNER tg_poster;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE tg_poster TO tg_poster;"
```

### 5. Настройка виртуального окружения и установка зависимостей

```bash
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 6. Настройка переменных окружения

```bash
# Копирование примера .env файла
cp .env.example .env

# Редактирование .env файла
nano .env
```

Заполните следующие переменные в файле .env:

```
# Telegram Bot
TELEGRAM_BOT_TOKEN=your_bot_token
ALLOWED_USER_IDS=123456789,987654321

# VK API
VK_APP_ID=your_vk_app_id
VK_APP_SECRET=your_vk_app_secret
VK_ACCESS_TOKEN=your_vk_access_token
VK_GROUP_ID=your_vk_group_id

# Telegram Channel
TELEGRAM_CHANNEL_ID=your_telegram_channel_id

# Database
DATABASE_URL=postgresql://tg_poster:your_password@localhost/tg_poster

# Security
SECRET_KEY=your_secret_key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# API
API_HOST=localhost
API_PORT=8002
```

### 7. Инициализация базы данных

```bash
# Активация виртуального окружения, если оно не активировано
source venv/bin/activate

# Запуск скрипта инициализации базы данных
python -c "from app.db.database import Base, engine; from app.db.models import *; Base.metadata.create_all(bind=engine)"
```

### 8. Настройка Supervisor

```bash
# Копирование конфигурационного файла
sudo cp supervisor/tg_poster_ubuntu.conf /etc/supervisor/conf.d/

# Редактирование конфигурационного файла
sudo nano /etc/supervisor/conf.d/tg_poster_ubuntu.conf
```

Обновите пути в конфигурационном файле Supervisor:

```
[program:tg_poster]
command=/path/to/tg_poster_ubuntu/venv/bin/python /path/to/tg_poster_ubuntu/main.py
directory=/path/to/tg_poster_ubuntu
autostart=true
autorestart=true
stderr_logfile=/var/log/tg_poster.err.log
stdout_logfile=/var/log/tg_poster.out.log
user=your_username
environment=PYTHONPATH="/path/to/tg_poster_ubuntu"

[program:tg_poster_api]
command=/path/to/tg_poster_ubuntu/venv/bin/uvicorn app.api.main:app --host 0.0.0.0 --port 8002
directory=/path/to/tg_poster_ubuntu
autostart=true
autorestart=true
stderr_logfile=/var/log/tg_poster_api.err.log
stdout_logfile=/var/log/tg_poster_api.out.log
user=your_username
environment=PYTHONPATH="/path/to/tg_poster_ubuntu"
```

### 9. Настройка Nginx

```bash
# Копирование конфигурационного файла
sudo cp nginx/tg_poster_ubuntu.conf /etc/nginx/sites-available/

# Создание символической ссылки
sudo ln -s /etc/nginx/sites-available/tg_poster_ubuntu.conf /etc/nginx/sites-enabled/

# Проверка конфигурации Nginx
sudo nginx -t

# Перезапуск Nginx
sudo systemctl restart nginx
```

### 10. Запуск сервисов

```bash
# Перезагрузка конфигурации Supervisor
sudo supervisorctl reread
sudo supervisorctl update

# Запуск сервисов
sudo supervisorctl start tg_poster
sudo supervisorctl start tg_poster_api
```

### 11. Проверка статуса сервисов

```bash
sudo supervisorctl status
```

## Использование

После установки и настройки вы можете взаимодействовать с ботом через Telegram. Найдите своего бота по имени пользователя и начните диалог.

### Основные команды бота:

- `/start` - Начать работу с ботом
- `/help` - Получить справку
- `/posts` - Просмотреть список постов
- `/archive` - Просмотреть архив постов
- `/create` - Создать новый пост

## Обслуживание

### Просмотр логов

```bash
# Логи бота
sudo tail -f /var/log/tg_poster.out.log
sudo tail -f /var/log/tg_poster.err.log

# Логи API
sudo tail -f /var/log/tg_poster_api.out.log
sudo tail -f /var/log/tg_poster_api.err.log
```

### Перезапуск сервисов

```bash
sudo supervisorctl restart tg_poster
sudo supervisorctl restart tg_poster_api
```

### Обновление проекта

```bash
cd /path/to/tg_poster_ubuntu
git pull
source venv/bin/activate
pip install -r requirements.txt
sudo supervisorctl restart tg_poster
sudo supervisorctl restart tg_poster_api
```

## Устранение неполадок

### Проблема: Бот не отвечает

1. Проверьте статус сервисов:
   ```bash
   sudo supervisorctl status
   ```

2. Проверьте логи:
   ```bash
   sudo tail -f /var/log/tg_poster.err.log
   ```

3. Перезапустите сервис:
   ```bash
   sudo supervisorctl restart tg_poster
   ```

### Проблема: API не работает

1. Проверьте статус сервиса:
   ```bash
   sudo supervisorctl status tg_poster_api
   ```

2. Проверьте логи:
   ```bash
   sudo tail -f /var/log/tg_poster_api.err.log
   ```

3. Перезапустите сервис:
   ```bash
   sudo supervisorctl restart tg_poster_api
   ```
