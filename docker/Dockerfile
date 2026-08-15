FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Moscow

LABEL maintainer="1C Home Server"
LABEL description="PostgreSQL 1C for Integration Test Stand"

ENV PGDATA=/var/lib/postgresql/data

# 1. Установка зависимостей и ЛОКАЛЕЙ (Критично для 1С!)
RUN apt-get update && apt-get install -y \
    wget curl ca-certificates gnupg bzip2 sudo tzdata locales \
    && rm -rf /var/lib/apt/lists/*

# 2. Генерация русской локали (Обязательно!)
RUN sed -i -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen ru_RU.UTF-8

ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru
ENV LC_ALL=ru_RU.UTF-8

# 3. Создание пользователя postgres
RUN useradd -m -s /bin/bash postgres \
    && echo "postgres:postgres" | chpasswd \
    && adduser postgres sudo

# 4. Копирование дистрибутива 1С (Пользователь должен скачать его сам!)
# Файл должен лежать рядом с Dockerfile и называться postgresql_*.tar.bz2
COPY postgresql_*.tar.bz2 /tmp/

# 5. Установка PostgreSQL из дистрибутива 1С
WORKDIR /tmp
RUN tar -xjf postgresql_*.tar.bz2 \
    && apt-get update && apt-get install -y libjson-perl ssl-cert ucf perl \
    && ln -fs /usr/share/zoneinfo/Europe/Moscow /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && dpkg -i postgresql-common_*.deb || true \
    && dpkg -i postgresql-client-common_*.deb || true \
    && dpkg -i libpq5_*.deb || true \
    && dpkg -i postgresql-client-*.deb || true \
    && dpkg -i postgresql-*.deb || true \
    && apt-get install -f -y \
    && rm -rf /tmp/postgresql-*.tar.bz2 /tmp/*.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 6. Настройка PostgreSQL для 1С
RUN mkdir -p $PGDATA && chown -R postgres:postgres $PGDATA

# Копируем entrypoint
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 5432
USER postgres
ENTRYPOINT ["entrypoint.sh"]