#!/bin/bash
set -e

# Русская локаль для 1С (Критично!)
export LANG=ru_RU.UTF-8
export LC_COLLATE=ru_RU.UTF-8
export LC_CTYPE=ru_RU.UTF-8

# Инициализация БД, если папка пуста
if [ -z "$(ls -A $PGDATA)" ]; then
    echo "Initializing PostgreSQL with Russian locale..."
    # Находим путь к initdb (может быть 16, 17 или 18)
    INITDB=$(find /usr/lib/postgresql -name initdb | head -n 1)
    
    su - postgres -c "$INITDB -D $PGDATA --locale=ru_RU.UTF-8 --encoding=UTF8"
    
    # Настройки для 1С
    echo "shared_buffers = 256MB" >> $PGDATA/postgresql.conf
    echo "max_connections = 100" >> $PGDATA/postgresql.conf
    echo "listen_addresses = '*'" >> $PGDATA/postgresql.conf
    
    # Разрешаем подключения
    echo "host all all 0.0.0.0/0 md5" >> $PGDATA/pg_hba.conf
fi

# Запуск PostgreSQL
POSTGRES_BIN=$(find /usr/lib/postgresql -name postgres | head -n 1)
exec su - postgres -c "$POSTGRES_BIN -D $PGDATA"