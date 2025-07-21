# Postgres Backup Tool
Command line tool for creating PostgreSQL database backups (using the `pg_dump` utility) and automatically sending the generated dump to an external storage (e.g., S3).

- outputs a custom-format archive `-Fc`
- name of the backup file will be set from current date and time expressed according to ISO 8601 `2025-01-01T000000Z.pgb`.

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
```txt
pgb [--pg-dump-version <version>] [--pg-dump-path <path>] [--storage <string>] [--directory <path>] [--keep <int>] [--keep-public-schema] [--s3-http1] [--env <path>]

OPTIONS:
  --pg-dump-version     <version>   pg_dump version to use [15, 16 or 17]                               (default: 17)
  --pg-dump-path        <path>      full path to the pg_dump executable (overwrites --pg-dump-version)
  -s, --storage         <string>    storage location for the backup file [s3, local]                    (default: s3)
  -d, --directory       <path>      destination directory for the backup file                           (default: .backups/db/)
  -k, --keep            <int>       number of backups to retain [set 0 to keep all]                     (default: 2)
  --keep-public-schema              do not exclude public schema from the backup
  --s3-http1                        force HTTP/1 for S3 connections
  -e, --env             <path>      .env file
  --version                         Show the version.
  -h, --help                        Show help information.
```

### Docker image available at:
- [GitHub Container Registry](https://github.com/ictorn/pgb/pkgs/container/pgb)  
  `docker run --pull always --rm ghcr.io/ictorn/pgb`
- [Docker Hub](https://hub.docker.com/r/ictorn/pgb)  
  `docker run --pull always --rm ictorn/pgb`
