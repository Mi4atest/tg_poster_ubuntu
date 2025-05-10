# Руководство по миграции TG Poster с macOS на Ubuntu 24.04

Это руководство описывает процесс миграции проекта TG Poster с macOS на Ubuntu 24.04, сохраняя при этом все данные и функциональность.

## Предварительные требования

- Сервер с Ubuntu 24.04
- Доступ по SSH к серверу
- Git, установленный на локальной машине
- Доступ к GitHub

## 1. Подготовка репозитория на GitHub

### 1.1. Создание нового репозитория

1. Зайдите на GitHub и создайте новый репозиторий с именем `tg_poster_ubuntu`
2. Не инициализируйте репозиторий с README, .gitignore или лицензией

### 1.2. Подготовка локального проекта для GitHub

1. Создайте копию проекта для загрузки на GitHub:

```bash
# На локальной машине
mkdir -p ~/tg_poster_ubuntu
cp -r /Users/aleksandr/Documents/augment-projects/tg_poster/* ~/tg_poster_ubuntu/
cd ~/tg_poster_ubuntu
```

2. Удалите ненужные файлы и директории:

```bash
# Удаление виртуального окружения
rm -rf venv

# Удаление медиа-файлов (если они есть)
rm -rf media/*

# Удаление базы данных SQLite (если используется)
rm -f *.db

# Удаление файлов конфигурации, специфичных для macOS
rm -rf .DS_Store
```

3. Адаптируйте конфигурационные файлы для Ubuntu:

```bash
# Создание директорий для конфигурационных файлов
mkdir -p nginx
mkdir -p supervisor
mkdir -p systemd
```

4. Создайте файл конфигурации Nginx для Ubuntu:

```bash
cat > nginx/tg_poster_ubuntu.conf << EOF
server {
    listen 8080;
    server_name _;

    location / {
        proxy_pass http://localhost:8002;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /static/ {
        alias /path/to/tg_poster_ubuntu/static/;
    }

    location /media/ {
        alias /path/to/tg_poster_ubuntu/media/;
    }
}
EOF
```

5. Создайте файл конфигурации Supervisor для Ubuntu:

```bash
cat > supervisor/tg_poster_ubuntu.conf << EOF
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
EOF
```

6. Создайте файлы systemd сервисов для Ubuntu:

```bash
cat > systemd/tg_poster.service << EOF
[Unit]
Description=TG Poster Bot Service
After=network.target

[Service]
User=your_username
Group=your_group
WorkingDirectory=/path/to/tg_poster_ubuntu
Environment="PATH=/path/to/tg_poster_ubuntu/venv/bin"
ExecStart=/path/to/tg_poster_ubuntu/venv/bin/python /path/to/tg_poster_ubuntu/main.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat > systemd/tg_poster_api.service << EOF
[Unit]
Description=TG Poster API Service
After=network.target

[Service]
User=your_username
Group=your_group
WorkingDirectory=/path/to/tg_poster_ubuntu
Environment="PATH=/path/to/tg_poster_ubuntu/venv/bin"
ExecStart=/path/to/tg_poster_ubuntu/venv/bin/uvicorn app.api.main:app --host 0.0.0.0 --port 8002
Restart=always

[Install]
WantedBy=multi-user.target
EOF
```

7. Создайте скрипт установки для Ubuntu:

```bash
cat > setup.sh << EOF
#!/bin/bash

# Скрипт для инициализации проекта TG Poster на Ubuntu 24.04
# ... содержимое скрипта ...
EOF

chmod +x setup.sh
```

8. Обновите файл .env.example для Ubuntu:

```bash
cat > .env.example << EOF
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
EOF
```

9. Создайте README.md с инструкциями по установке:

```bash
cat > README.md << EOF
# TG Poster - Система автоматизированного постинга в социальные сети

Система для автоматизированного постинга контента в социальные сети (VK, Telegram, Instagram) через Telegram бота.

## Требования

- Ubuntu 24.04
- Python 3.10+
- PostgreSQL
- Nginx
- Supervisor

## Инструкция по установке на Ubuntu 24.04

... содержимое инструкции ...
EOF
```

### 1.3. Инициализация Git репозитория и загрузка на GitHub

```bash
# Инициализация Git репозитория
git init

# Добавление всех файлов
git add .

# Создание первого коммита
git commit -m "Initial commit for Ubuntu 24.04"

# Добавление удаленного репозитория
git remote add origin https://github.com/yourusername/tg_poster_ubuntu.git

# Загрузка на GitHub
git push -u origin master
```

## 2. Установка на сервер Ubuntu 24.04

### 2.1. Подключение к серверу

```bash
ssh username@your_server_ip
```

### 2.2. Обновление системы

```bash
sudo apt update
sudo apt upgrade -y
```

### 2.3. Установка необходимых пакетов

```bash
sudo apt install -y python3 python3-pip python3-venv postgresql postgresql-contrib nginx supervisor git
```

### 2.4. Клонирование репозитория

```bash
sudo mkdir -p /opt/tg_poster
sudo chown $USER:$USER /opt/tg_poster
cd /opt/tg_poster
git clone https://github.com/yourusername/tg_poster_ubuntu.git .
```

### 2.5. Запуск скрипта установки

```bash
sudo ./setup.sh
```

### 2.6. Настройка переменных окружения

```bash
nano .env
```

Заполните все необходимые переменные окружения, включая токены и ключи API.

### 2.7. Перезапуск сервисов

```bash
sudo supervisorctl restart tg_poster
sudo supervisorctl restart tg_poster_api
```

## 3. Миграция данных (если необходимо)

### 3.1. Экспорт данных из SQLite (если используется на macOS)

```bash
# На локальной машине
cd /Users/aleksandr/Documents/augment-projects/tg_poster
sqlite3 app.db .dump > dump.sql
```

### 3.2. Импорт данных в PostgreSQL на Ubuntu

```bash
# Копирование дампа на сервер
scp dump.sql username@your_server_ip:/tmp/

# На сервере
cd /opt/tg_poster
cat /tmp/dump.sql | sudo -u postgres psql tg_poster
```

### 3.3. Копирование медиа-файлов

```bash
# На локальной машине
cd /Users/aleksandr/Documents/augment-projects/tg_poster
tar -czf media.tar.gz media/

# Копирование архива на сервер
scp media.tar.gz username@your_server_ip:/tmp/

# На сервере
cd /opt/tg_poster
tar -xzf /tmp/media.tar.gz
sudo chown -R $USER:$USER media/
```

## 4. Проверка работоспособности

### 4.1. Проверка статуса сервисов

```bash
sudo supervisorctl status
```

### 4.2. Проверка логов

```bash
sudo tail -f /var/log/tg_poster.err.log
sudo tail -f /var/log/tg_poster_api.err.log
```

### 4.3. Проверка доступности API

```bash
curl http://localhost:8002/docs
```

### 4.4. Проверка работы бота

Откройте Telegram и проверьте, что бот отвечает на команды.

## 5. Устранение неполадок

### 5.1. Проблемы с базой данных

```bash
# Проверка подключения к PostgreSQL
sudo -u postgres psql -c "SELECT 1;"

# Проверка существования базы данных
sudo -u postgres psql -c "\l"

# Проверка прав пользователя
sudo -u postgres psql -c "\du"
```

### 5.2. Проблемы с сетью

```bash
# Проверка открытых портов
sudo netstat -tulpn | grep LISTEN

# Проверка работы Nginx
sudo systemctl status nginx
```

### 5.3. Проблемы с правами доступа

```bash
# Проверка прав доступа к директориям
ls -la /opt/tg_poster
ls -la /opt/tg_poster/media

# Исправление прав доступа
sudo chown -R $USER:$USER /opt/tg_poster
```

## 6. Обновление проекта

```bash
cd /opt/tg_poster
git pull
source venv/bin/activate
pip install -r requirements.txt
sudo supervisorctl restart tg_poster
sudo supervisorctl restart tg_poster_api
```
