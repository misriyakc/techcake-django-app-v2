# Techcake Sample Django App — v2 (S3-enabled)

The Track 2 version of the Techcake Django app — an **S3-integrated app**. Same
congratulations page and admin as v1, **plus Amazon S3 media storage reached
through an EC2 IAM instance role** (no AWS access keys anywhere) and a **Redis**
cache (a visit counter on the home page proves Redis is wired in). It also ships
an `s3check` management command to verify S3 connectivity.

> Your task is to deploy this — not to rewrite it. Setting up RDS, the S3 bucket,
> the instance role, the container, and the compose stack is the exercise.

## What this app needs
- Python 3 + a virtual environment
- The packages in `requirements.txt` (`Django`, `gunicorn`, `PyMySQL`, `boto3`, `django-storages`)
- An **Amazon RDS** (MySQL/MariaDB) database, with a dedicated DB user and password
- An **S3 bucket** and an **IAM instance role** attached to the EC2 instance granting
  least-privilege access to that bucket (no access keys)

## How AWS credentials work
This app does **not** read AWS keys. `boto3`/`django-storages` use the default
credential chain, which on EC2 resolves to the **attached instance role**. Attach
the role to the instance first; the app (and the container running on it) inherit it.

## Environment variables it reads

| Variable | Purpose | Example |
|---|---|---|
| `DJANGO_SECRET_KEY` | Django secret key (generate your own) | a long random string |
| `DJANGO_DEBUG` | leave off in production | `false` |
| `DJANGO_ALLOWED_HOSTS` | comma-separated hostnames | `django1.<studentid>.nixlabs.in` |
| `DJANGO_CSRF_TRUSTED_ORIGINS` | needed once you're on HTTPS | `https://django1.<studentid>.nixlabs.in` |
| `DB_NAME` | database name | `django1` |
| `DB_USER` | database user | `django1_user` |
| `DB_PASSWORD` | database password | (your password) |
| `DB_HOST` | **RDS endpoint** | `your-db.xxxx.<region>.rds.amazonaws.com` |
| `DB_PORT` | database port | `3306` |
| `AWS_STORAGE_BUCKET_NAME` | the S3 bucket for media | `techcake-<studentid>-media` |
| `AWS_S3_REGION_NAME` | bucket region | `ap-south-1` |
| `REDIS_URL` | Redis cache (omit to fall back to local memory) | `redis://redis:6379/0` |

## Verify S3 (the point of v2)
Once the bucket exists and the instance role is attached:

```
python manage.py s3check
```

It writes a small test object to the bucket and reads it back. Exit code 0 and a
`S3 CHECK PASSED` line mean the instance role + bucket policy are working.

## The usual first steps once the env is set
- Install requirements into the venv
- Run database migrations (against RDS)
- `collectstatic`
- Run `s3check` to confirm S3 access via the role
- Start it under gunicorn (bind to a local TCP port); for Track 2, this runs in a container

Refer to your Track 2 task sheet for the exact requirements and definition of done.
Jenkins webhook test.
