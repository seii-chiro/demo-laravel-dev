# Docker Laravel Dev

This project demonstrates a Dockerized Laravel API with separate development and production-like workflows.

The setup mirrors the `docker-react-dev` pattern:

- `Dockerfile` contains multiple build targets.
- `docker-compose.yml` defines shared services.
- `docker-compose.dev.yml` runs a bind-mounted development stack.
- `docker-compose.prod.yml` runs production-style images without source bind mounts.

## Services

- `app`: PHP-FPM Laravel application.
- `nginx`: Public HTTP entry point.
- `db`: PostgreSQL database.

## Ports

| Stack | App URL | PostgreSQL |
| --- | --- | --- |
| Development | `http://localhost:9080` | `localhost:5448` |
| Production-like | `http://localhost:9081` | `localhost:5449` |

## Development

Start the development stack:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

The development stack bind-mounts the project into the `app` and `nginx` containers, so PHP source changes are picked up without rebuilding the image.

Initialize Laravel once:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml exec app php artisan key:generate
docker compose -f docker-compose.yml -f docker-compose.dev.yml exec app php artisan migrate
```

Smoke test the API:

```bash
curl http://localhost:9080/api/health
```

Run tests in the app container:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml exec app php artisan test
```

Stop the stack:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml down
```

Remove the database volume too:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml down -v
```

## Production-Like Build

Build and start the production-like stack:

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up --build
```

This uses the production `app` target, installs Composer dependencies without dev packages, builds frontend assets, and serves through the nginx image target.

Smoke test:

```bash
curl http://localhost:9081/api/health
```

Stop the stack:

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml down
```

## Dockerfile Targets

- `vendor`: Installs production Composer dependencies.
- `assets`: Builds Vite assets.
- `dev`: PHP-FPM image with Composer dev dependencies.
- `app`: Production PHP-FPM image with optimized dependencies.
- `nginx`: Nginx image with Laravel public assets and config.

## Useful Commands

Rebuild only the app image:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml build app
```

Run an Artisan command:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml exec app php artisan route:list
```

Open a shell in the app container:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml exec app sh
```

View logs:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml logs -f app nginx db
```

Reset the development database:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml exec app php artisan migrate:fresh
```

## API Endpoints

- `GET /`: Basic JSON app status.
- `GET /api/health`: API health check.

## Notes

- This is an API-first Laravel setup, so there is no Dockerized Vite HMR service.
- PostgreSQL data is stored in the `laravel_pgdata` Docker volume.
- Composer dependencies inside the development container are stored in the `laravel_vendor` Docker volume so the host bind mount does not hide container-installed packages.
