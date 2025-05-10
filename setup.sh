#!/bin/bash

# Скрипт для инициализации проекта TG Poster на Ubuntu 24.04

# Проверка прав суперпользователя
if [ "$EUID" -ne 0 ]; then
  echo "Пожалуйста, запустите скрипт с правами суперпользователя (sudo)"
  exit 1
fi

# Получение имени пользователя, от которого запущен sudo
REAL_USER=$(logname)
REAL_GROUP=$(id -gn $REAL_USER)

# Установка переменных
PROJECT_DIR="/opt/tg_poster"
VENV_DIR="$PROJECT_DIR/venv"
NGINX_CONF="/etc/nginx/sites-available/tg_poster.conf"
SUPERVISOR_CONF="/etc/supervisor/conf.d/tg_poster.conf"
SYSTEMD_BOT_SERVICE="/etc/systemd/system/tg_poster.service"
SYSTEMD_API_SERVICE="/etc/systemd/system/tg_poster_api.service"

# Обновление системы
echo "Обновление системы..."
apt update
apt upgrade -y

# Установка необходимых пакетов
echo "Установка необходимых пакетов..."
apt install -y python3 python3-pip python3-venv postgresql postgresql-contrib nginx supervisor git

# Создание директории проекта
echo "Создание директории проекта..."
mkdir -p $PROJECT_DIR
chown $REAL_USER:$REAL_GROUP $PROJECT_DIR

# Клонирование репозитория
echo "Клонирование репозитория..."
cd $PROJECT_DIR
sudo -u $REAL_USER git clone https://github.com/yourusername/tg_poster_ubuntu.git .

# Создание виртуального окружения
echo "Создание виртуального окружения..."
sudo -u $REAL_USER python3 -m venv $VENV_DIR
sudo -u $REAL_USER $VENV_DIR/bin/pip install --upgrade pip
sudo -u $REAL_USER $VENV_DIR/bin/pip install -r requirements.txt

# Настройка базы данных PostgreSQL
echo "Настройка базы данных PostgreSQL..."
DB_PASSWORD=$(openssl rand -base64 12)
sudo -u postgres psql -c "CREATE USER tg_poster WITH PASSWORD '$DB_PASSWORD';"
sudo -u postgres psql -c "CREATE DATABASE tg_poster OWNER tg_poster;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE tg_poster TO tg_poster;"

# Создание .env файла
echo "Создание .env файла..."
sudo -u $REAL_USER cp .env.example .env
sudo -u $REAL_USER sed -i "s|DATABASE_URL=.*|DATABASE_URL=postgresql://tg_poster:$DB_PASSWORD@localhost/tg_poster|g" .env
sudo -u $REAL_USER sed -i "s|SECRET_KEY=.*|SECRET_KEY=$(openssl rand -base64 32)|g" .env
sudo -u $REAL_USER sed -i "s|API_PORT=.*|API_PORT=8002|g" .env

# Инициализация базы данных
echo "Инициализация базы данных..."
sudo -u $REAL_USER $VENV_DIR/bin/python -c "from app.db.database import Base, engine; from app.db.models import *; Base.metadata.create_all(bind=engine)"

# Настройка Nginx
echo "Настройка Nginx..."
cat > $NGINX_CONF << EOF
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
        alias $PROJECT_DIR/static/;
    }

    location /media/ {
        alias $PROJECT_DIR/media/;
    }
}
EOF

# Создание символической ссылки для Nginx
ln -sf $NGINX_CONF /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

# Настройка Supervisor
echo "Настройка Supervisor..."
cat > $SUPERVISOR_CONF << EOF
[program:tg_poster]
command=$VENV_DIR/bin/python $PROJECT_DIR/main.py
directory=$PROJECT_DIR
autostart=true
autorestart=true
stderr_logfile=/var/log/tg_poster.err.log
stdout_logfile=/var/log/tg_poster.out.log
user=$REAL_USER
environment=PYTHONPATH="$PROJECT_DIR"

[program:tg_poster_api]
command=$VENV_DIR/bin/uvicorn app.api.main:app --host 0.0.0.0 --port 8002
directory=$PROJECT_DIR
autostart=true
autorestart=true
stderr_logfile=/var/log/tg_poster_api.err.log
stdout_logfile=/var/log/tg_poster_api.out.log
user=$REAL_USER
environment=PYTHONPATH="$PROJECT_DIR"
EOF

# Перезагрузка конфигурации Supervisor
supervisorctl reread
supervisorctl update

# Настройка systemd сервисов (альтернатива Supervisor)
echo "Настройка systemd сервисов..."
cat > $SYSTEMD_BOT_SERVICE << EOF
[Unit]
Description=TG Poster Bot Service
After=network.target

[Service]
User=$REAL_USER
Group=$REAL_GROUP
WorkingDirectory=$PROJECT_DIR
Environment="PATH=$VENV_DIR/bin"
ExecStart=$VENV_DIR/bin/python $PROJECT_DIR/main.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat > $SYSTEMD_API_SERVICE << EOF
[Unit]
Description=TG Poster API Service
After=network.target

[Service]
User=$REAL_USER
Group=$REAL_GROUP
WorkingDirectory=$PROJECT_DIR
Environment="PATH=$VENV_DIR/bin"
ExecStart=$VENV_DIR/bin/uvicorn app.api.main:app --host 0.0.0.0 --port 8002
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Включение и запуск systemd сервисов
systemctl daemon-reload
systemctl enable tg_poster.service
systemctl enable tg_poster_api.service
systemctl start tg_poster.service
systemctl start tg_poster_api.service

# Создание директорий для медиа-файлов
echo "Создание директорий для медиа-файлов..."
mkdir -p $PROJECT_DIR/media
chown -R $REAL_USER:$REAL_GROUP $PROJECT_DIR/media

# Вывод информации о завершении установки
echo "Установка завершена!"
echo "База данных: tg_poster"
echo "Пользователь БД: tg_poster"
echo "Пароль БД: $DB_PASSWORD"
echo "API доступен по адресу: http://localhost:8002"
echo "Веб-интерфейс доступен по адресу: http://localhost:8080"
echo ""
echo "Для настройки бота отредактируйте файл .env и укажите токен бота и другие параметры."
echo "После настройки перезапустите сервисы:"
echo "sudo supervisorctl restart tg_poster"
echo "sudo supervisorctl restart tg_poster_api"
echo ""
echo "Или, если вы используете systemd:"
echo "sudo systemctl restart tg_poster"
echo "sudo systemctl restart tg_poster_api"
