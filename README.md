# Postgres Backup Tool
Command line tool for creating PostgreSQL database backups (using the `pg_dump` utility) and automatically sending the generated dump to an external storage (e.g., S3).

Name of the backup file will be set from current date and time expressed according to ISO 8601.

## Configuration
Configuration is done by defining environment variables listed below.

### pg_dump utility
- `PGB_CONNECTION_URI`: postgres [connection string](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING)

### S3 storage
- `PGB_S3_ENDPOINT`: server endpoint
- `PGB_S3_REGION`: region name
- `PGB_S3_KEY`: access key
- `PGB_S3_SECRET`: secret key
- `PGB_S3_BUCKET`: bucket name

## Usage
Docker image available at [GitHub Container Registry](https://github.com/ictorn/pgb/pkgs/container/pgb).

`docker run --pull always --rm ghcr.io/ictorn/pgb`

```txt
USAGE: pgb [--pg-dump-path <path>] [--storage <string>] [--directory <path>] [--extension <string>] [--keep <int>]

OPTIONS:
  --pg-dump-path    <path>      full path to pg_dump executable                 (default: /dump)
  -s, --storage     <string>    storage location for backup file [s3, local]    (default: s3)
  -d, --directory   <path>      destination directory for backup file           (default: .backups/db/)
  -e, --extension   <string>    extension for backup file                       (default: pgb)
  -k, --keep        <int>       number of backups to retain [set 0 to keep all] (default: 2)
```
