# Multi-Stack Docker Platform

A Docker learning project with five independent services: a two-site Nginx
server, a Node.js API, a Flask API (Gunicorn), a Java/Tomcat WAR app, and a
full-stack React + Flask + PostgreSQL application wired together with
docker-compose.

Tested on **Windows 11 with Docker Desktop**, run from **Git Bash or WSL2**.

---

## Project layout

```
multi-stack-platform/
├── nginx/                       # Two static sites on ports 81 and 82
├── nodejs/                      # Node.js HTTP server, port 3000
├── flask/                       # Flask API served by Gunicorn, port 5000
├── java/                        # Maven-built WAR deployed on Tomcat, port 8080
├── fullstack-text-storage/      # React + Flask + PostgreSQL, run via docker-compose
├── .dockerignore
└── README.md
```

## Port map

| Service                              | Container port | Host port | URL                          |
|---------------------------------------|:--------------:|:---------:|-------------------------------|
| Nginx – site1                         | 81              | 81        | http://localhost:81          |
| Nginx – site2                         | 82              | 82        | http://localhost:82          |
| Node.js server                        | 3000            | 3000      | http://localhost:3000        |
| Flask server (standalone)             | 5000            | 5001      | http://localhost:5001        |
| Java/Tomcat app                       | 8080            | 8080      | http://localhost:8080        |
| Full stack – frontend (React/Nginx)   | 80              | 3001      | http://localhost:3001        |
| Full stack – backend (Flask API)      | 5000            | 5000      | http://localhost:5000        |
| Full stack – PostgreSQL               | 5432            | 5433      | localhost:5433 (psql/clients)|

> The standalone Flask app is mapped to host port **5001** so it doesn't clash
> with the full-stack backend, which uses host port **5000**.

---

## 1. Nginx (two static sites)

```bash
cd multi-stack-platform/nginx
docker build -t nginx-demo .
docker run -d --name nginx-demo -p 81:81 -p 82:82 nginx-demo
```

Test:

```bash
curl http://localhost:81
curl http://localhost:82
```

## 2. Node.js

```bash
cd multi-stack-platform/nodejs
docker build -t nodejs-demo .
docker run -d --name nodejs-demo -p 3000:3000 nodejs-demo
```

Test:

```bash
curl http://localhost:3000
curl http://localhost:3000/health
```

## 3. Flask (Gunicorn)

```bash
cd multi-stack-platform/flask
docker build -t flask-demo .
docker run -d --name flask-demo -p 5001:5000 flask-demo
```

Test:

```bash
curl http://localhost:5001
curl http://localhost:5001/health
```

## 4. Java / Tomcat

```bash
cd multi-stack-platform/java
docker build -t java-demo .
docker run -d --name java-demo -p 8080:8080 java-demo
```

Tomcat can take a few seconds to finish starting. Test:

```bash
curl http://localhost:8080/
curl http://localhost:8080/hello
```

---

## 5. Full-stack text storage app (docker-compose)

React frontend → Flask REST API (`/insert`, `/list`) → PostgreSQL, all on a
custom bridge network, with a named volume for database persistence.

```bash
cd multi-stack-platform/fullstack-text-storage
docker compose up -d --build
```

Docker Compose automatically loads `fullstack-text-storage/.env` for the
database credentials (`POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`,
`DB_HOST`, `DB_PORT`) — nothing is hardcoded in `app.py`. Edit that file to
change credentials before deploying anywhere real.

The `backend` service has `depends_on: db: condition: service_healthy`, so it
will not start until Postgres's own healthcheck (`pg_isready`) passes.

Test:

```bash
# Open the UI
# http://localhost:3001

# Or hit the API directly
curl -X POST http://localhost:5000/insert -H "Content-Type: application/json" -d "{\"text\": \"hello docker\"}"
curl http://localhost:5000/list
```

Stop and remove containers (keep the data volume):

```bash
docker compose down
```

Stop and also wipe the database volume:

```bash
docker compose down -v
```

---

## Basic Docker commands used in this project

```bash
# Build an image from a Dockerfile in the current directory
docker build -t <image-name> .

# Run a container in the background with a port mapping
docker run -d --name <container-name> -p <host-port>:<container-port> <image-name>

# List running containers
docker ps

# List all containers, including stopped ones
docker ps -a

# Stream logs from a container
docker logs -f <container-name>

# Open a shell inside a running container
docker exec -it <container-name> /bin/sh    # or /bin/bash if available

# Stop and remove a container
docker stop <container-name>
docker rm <container-name>

# Remove an image
docker rmi <image-name>

# docker-compose: build and start all services in the background
docker compose up -d --build

# docker-compose: view logs for all services
docker compose logs -f

# docker-compose: stop and remove containers/network (add -v to also drop volumes)
docker compose down
```

---

## Image size / best practices applied

- All images use **slim or alpine base images** (`node:20-slim`,
  `python:3.11-slim`, `nginx:1.27-alpine`, `postgres:16-alpine`) except
  Tomcat, which requires the full JDK runtime.
- Every Dockerfile **copies dependency manifests first** (`package.json`,
  `requirements.txt`, `pom.xml`) and installs dependencies **before** copying
  application source, so code changes don't invalidate the dependency-install
  layer cache.
- The Java and React builds use **multi-stage builds**: build tools (Maven,
  Node) are only present in the intermediate build stage and are not shipped
  in the final runtime image.
- `RUN` commands are combined where it reduces layers (e.g. user creation,
  `apt`/`pip` installs).
- Containers run as **non-root users** where the base image supports it
  (Node.js and Flask images create and switch to an unprivileged user).
- `.dockerignore` keeps `node_modules`, `.git`, `__pycache__`, `*.pyc`, and
  `.env` files out of build contexts and images.
