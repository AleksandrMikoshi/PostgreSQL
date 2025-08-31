# PostgreSQL Backup & Restore with S3 Integration

[Русский язык](https://github.com/AleksandrMikoshi/PostgreSQL/blob/main/Backup%20database%20on%20S3/Readme_ru.md)

## 📌 Description

This project automates **PostgreSQL** database backup and restore with support for uploading backups to **Amazon S3** and integration with **GitLab CI/CD**.

Features:

* Parallel PostgreSQL dumps using `pg_dump`
* Database restore with `pg_restore`
* Operation logging (backup, S3 upload, restore)
* Upload backups to **S3** with integrity check
* Run jobs via **GitLab CI/CD**

---

## 🛠 Requirements

* **PostgreSQL client tools** (`pg_dump`, `pg_restore`)
* **AWS CLI** (for uploading to S3)
* PostgreSQL access with backup/restore permissions
* GitLab Runner (to use `.gitlab-ci.yml`)

---

## 🚀 Usage

### 1. Database Backup

```bash
./backup.sh <PG_PASSWORD> <HOST> <PORT> <POSTGRESQL_USER> <DATABASE> [BACKDIR] [S3_BUCKET]
```

**Parameters:**

* `PG_PASSWORD` – PostgreSQL user password
* `HOST` – PostgreSQL host
* `PORT` – PostgreSQL port
* `POSTGRESQL_USER` – database user
* `DATABASE` – database name
* `BACKDIR` *(optional)* – local backup directory (default `/store/backup`)
* `S3_BUCKET` *(optional)* – S3 bucket name

**Example:**

```bash
./backup.sh mypass db.example.com 5432 postgres mydb /store/backup my-s3-bucket
```

---

### 2. Database Restore

```bash
./restore.sh <PG_PASSWORD> <HOST> <PORT> <POSTGRESQL_USER> <DATABASE> [BACKDIR]
```

**Parameters:**

* `PG_PASSWORD` – PostgreSQL user password
* `HOST` – PostgreSQL host
* `PORT` – PostgreSQL port
* `POSTGRESQL_USER` – database user
* `DATABASE` – database name
* `BACKDIR` *(optional)* – backup directory (default `/store/backup`)

**Example:**

```bash
./restore.sh mypass db.example.com 5432 postgres mydb /store/backup/mydb_31.08.2025-1200
```

---

## 📂 Project Structure

```
Backup database on S3/
│── backup.sh        # Backup and S3 upload script
│── restore.sh       # Database restore script
│── gitlab-ci.yml    # CI/CD pipeline for GitLab
```

---

## ⚡ GitLab CI/CD

The `.gitlab-ci.yml` defines three main jobs:

* **`backup_job`** – runs on schedule, creates a backup and uploads it to S3.
* **`restore_job`** – restores the database (manual trigger, `when: manual`).
* **`check_directory`** – checks the backup directory contents.

🔑 Required GitLab CI variables:

* `SSH_USER`, `SSH_HOST`, `SSH_PRIVATE_KEY` – SSH access to the server
* `PG_PASSWORD`, `HOST`, `PORT`, `POSTGRESQL_USER`, `DATABASE`, `BACKDIR`, `S3_BUCKET` – database and S3 settings

### Example GitLab Schedule (Pipeline Schedules)

To run a backup every day at 03:00 AM:

1. Go to **CI/CD → Schedules** in GitLab.
2. Click **New schedule**.
3. Set the cron expression:

   ```
   0 3 * * *
   ```
4. Enable `backup_job`.
5. Save.

---

## 📝 Logs

* Logs are stored in `/store/logs/`
* Example files:

  * `pg_backup_<DB>_<DATE>.log` – backup process
  * `s3_upload_<DB>_<DATE>.log` – S3 upload logs
  * `restore_<DB>_<DATE>.log` – restore process

---

## ✅ Integrity Check

After uploading to S3, the script compares the number of files locally and remotely to ensure backup integrity.