# PostgreSQL Backup & Restore with S3 Integration

## 📌 Описание

Этот проект предназначен для автоматизации резервного копирования и восстановления баз данных **PostgreSQL** с поддержкой загрузки бэкапов в **Amazon S3** и использованием **GitLab CI/CD**.

Функционал:

* Создание параллельных дампов PostgreSQL с помощью `pg_dump`
* Восстановление базы данных с помощью `pg_restore`
* Логирование операций (резервное копирование, загрузка на S3, восстановление)
* Загрузка резервных копий в **S3** и проверка целостности
* Поддержка запуска через **GitLab CI/CD**

---

## 🛠 Требования

* **PostgreSQL client tools** (`pg_dump`, `pg_restore`)
* **AWS CLI** (для загрузки на S3)
* Доступ к PostgreSQL с правами на бэкап/восстановление
* GitLab Runner (для использования `.gitlab-ci.yml`)

---

## 🚀 Использование

### 1. Резервное копирование базы

```bash
./backup.sh <PG_PASSWORD> <HOST> <PORT> <POSTGRESQL_USER> <DATABASE> [BACKDIR] [S3_BUCKET]
```

**Параметры:**

* `PG_PASSWORD` – пароль пользователя PostgreSQL
* `HOST` – хост PostgreSQL
* `PORT` – порт PostgreSQL
* `POSTGRESQL_USER` – имя пользователя
* `DATABASE` – имя базы данных
* `BACKDIR` *(опционально)* – локальная папка для бэкапов (по умолчанию `/store/backup`)
* `S3_BUCKET` *(опционально)* – имя S3 bucket для загрузки

**Пример:**

```bash
./backup.sh mypass db.example.com 5432 postgres mydb /store/backup my-s3-bucket
```

---

### 2. Восстановление базы

```bash
./restore.sh <PG_PASSWORD> <HOST> <PORT> <POSTGRESQL_USER> <DATABASE> [BACKDIR]
```

**Параметры:**

* `PG_PASSWORD` – пароль пользователя PostgreSQL
* `HOST` – хост PostgreSQL
* `PORT` – порт PostgreSQL
* `POSTGRESQL_USER` – имя пользователя
* `DATABASE` – имя базы данных
* `BACKDIR` *(опционально)* – папка с резервной копией (по умолчанию `/store/backup`)

**Пример:**

```bash
./restore.sh mypass db.example.com 5432 postgres mydb /store/backup/mydb_31.08.2025-1200
```

---

## 📂 Структура проекта

```
Backup database on S3/
│── backup.sh        # Скрипт резервного копирования и выгрузки на S3
│── restore.sh       # Скрипт восстановления из резервной копии
│── gitlab-ci.yml    # CI/CD pipeline для GitLab
```

---

## ⚡ GitLab CI/CD

В проекте предусмотрен `.gitlab-ci.yml` с тремя основными job’ами:

* **`backup_job`** – запускается по расписанию, выполняет резервное копирование и выгрузку на S3.
* **`restore_job`** – выполняет восстановление базы (ручной запуск, `when: manual`).
* **`check_directory`** – проверка содержимого каталога с бэкапами.

🔑 Для работы необходимы переменные GitLab CI:

* `SSH_USER`, `SSH_HOST`, `SSH_PRIVATE_KEY` – доступ к серверу
* `PG_PASSWORD`, `HOST`, `PORT`, `POSTGRESQL_USER`, `DATABASE`, `BACKDIR`, `S3_BUCKET` – параметры базы и S3

### Пример расписания GitLab (Pipeline Schedules)

Чтобы запускать бэкап каждый день в 03:00 утра:

1. Зайдите в **CI/CD → Schedules** в GitLab.
2. Нажмите **New schedule**.
3. Укажите cron-выражение:

   ```
   0 3 * * *
   ```
4. Включите `backup_job`.
5. Сохраните.

---

## 📝 Логи

* Логи хранятся в `/store/logs/`
* Примеры файлов:

  * `pg_backup_<DB>_<DATE>.log` – процесс бэкапа
  * `s3_upload_<DB>_<DATE>.log` – загрузка в S3
  * `restore_<DB>_<DATE>.log` – процесс восстановления

---

## ✅ Проверка целостности

После загрузки в S3 выполняется сравнение числа файлов в локальной и удалённой папке.