# Project Context — multi-stack-platform

**Read this file first before touching any code.** This documents everything done so far so you don't repeat work or break existing infrastructure.

---

## What This Project Is

A DevOps portfolio project containerizing 6 apps (Nginx, Node.js, Flask, Java/Tomcat, plus a Full Stack Text Storage App split into Frontend + Backend) and deploying them to **AWS ECS Fargate** using **Terraform**, with a **GitHub Actions CI/CD pipeline**.

- **GitHub repo:** `github.com/M-Arslan-Bhatti/multi-stack-docker-platform`
- **Docker Hub account:** `arslanbhatti123`
- **AWS Account:** `300034476528` (IAM user: `ntier-cli-user`, CLI profile: `default`)
- **AWS Region:** `us-east-1`
- **Author attribution required everywhere:** "Muhammad Arslan — DevOps Engineer | GitHub: M-Arslan-Bhatti" — no mention of Netsol, no "intern" title, no "lab" in any branch/commit/file name.

---

## Folder Structure

```
multi-stack-platform/
├── nginx/                          # Static site, 2 pages (site1, site2), ports 81/82
│   └── Dockerfile
├── nodejs/                         # Simple HTTP server, port 3000, non-root user
│   └── Dockerfile
├── flask/                          # Flask app served via Gunicorn, port 5000
│   └── Dockerfile
├── java/                           # Tomcat + Maven multi-stage build, port 8080
│   └── Dockerfile
├── fullstack-text-storage/
│   ├── frontend/                   # React app, multi-stage build → Nginx (port 80)
│   │   └── Dockerfile
│   └── backend/                    # Flask + psycopg2, talks to Postgres, port 5000
│       ├── app.py
│       └── Dockerfile
├── dashboard/
│   └── index.html                  # Custom-built "Fleet Console" landing page —
│                                    # shows all 6 services with live status + links.
│                                    # NOT deployed anywhere yet — currently a local
│                                    # file only, also pushed to GitHub as backup.
├── .github/workflows/
│   └── docker-build-push.yml       # CI/CD pipeline (see below)
├── .gitignore                      # Excludes terraform.tfvars, .terraform/, *.tfstate
└── terraform-ecs/                  # All AWS infrastructure as code
    ├── provider.tf                 # AWS provider, region us-east-1, profile default
    ├── vpc.tf                      # VPC (10.0.0.0/16), 2 public subnets, IGW, route table
    ├── security.tf                 # ECS security group
    ├── ecs-cluster.tf              # ECS Cluster "multi-stack-cluster" (Fargate)
    ├── iam.tf                      # ecsTaskExecutionRole + ecsTaskRole (for ECS Exec) +
    │                                # CloudWatch logs policy + SSM exec policy
    ├── variables.tf                # var.apps map (nginx/nodejs/flask/java/frontend)
    │                                # + var.db_password (sensitive)
    ├── ecs-tasks.tf                # Task definitions for the 5 apps in var.apps (for_each)
    ├── ecs-services.tf             # ECS services for the 5 apps in var.apps (for_each)
    ├── backend.tf                  # Backend task definition + service (separate from
    │                                # for_each because it needs RDS env vars)
    ├── rds.tf                      # RDS PostgreSQL instance "textstorage-db" + its
    │                                # own security group (only accepts from ecs_sg)
    ├── outputs.tf                  # ecs_cluster_name, service_names
    ├── terraform.tfvars            # db_password value — GITIGNORED, never in git
    └── alb.tf                      # IN PROGRESS — see "Current Task" below
```

---

## What's Actually Deployed on AWS Right Now

All via Terraform (`terraform apply` already run successfully multiple times):

| Resource | Name/ID |
|---|---|
| VPC | `ecs-fargate-vpc` (10.0.0.0/16) |
| Subnets | 2 public subnets across `us-east-1a` and `us-east-1b` |
| ECS Cluster | `multi-stack-cluster` (Fargate launch type) |
| RDS | `textstorage-db` (PostgreSQL 16.4, db.t3.micro), NOT publicly accessible |
| ECS Services | `nginx-service`, `nodejs-service`, `flask-service`, `java-service`, `frontend-service`, `backend-service` — all running, `desired_count=1` each |

**The `entries` table in RDS was created manually** via `ECS Exec` (`aws ecs execute-command`) running a Python script directly inside the backend container — there is no automated migration/init script yet. Schema:
```sql
CREATE TABLE entries (
    id SERIAL PRIMARY KEY,
    content VARCHAR(1000) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Backend app.py environment variable names (important — don't rename without updating Terraform too)
```
DB_HOST, DB_PORT, POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD
```
These exact names are required — the backend code was written for Docker Compose and expects these specific variable names (not `DB_NAME`/`DB_USER`/`DB_PASSWORD` — that mismatch caused a debugging session earlier).

Backend also has a `/health` route (used for ALB health checks) in addition to `/insert` and `/list`.

---

## CI/CD Pipeline (`.github/workflows/docker-build-push.yml`)

Two jobs:
1. **`build-and-push`** — builds all 6 Docker images and pushes to Docker Hub (`arslanbhatti123/<app>-app:latest` or similar names — check the file for exact tags)
2. **`deploy-to-ecs`** (`needs: build-and-push`) — runs `aws ecs update-service --force-new-deployment` for all 6 services

GitHub Secrets already configured: `DOCKER_USERNAME`, `DOCKER_PASSWORD`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`.

**This pipeline is confirmed working end-to-end** (tested, both jobs pass green).

**Known limitation:** every push rebuilds/redeploys all 6 apps regardless of which files actually changed — no path filtering yet.

---

## Known Issue — Frontend Service Currently Broken

The React frontend's Nginx config does `proxy_pass http://backend:5000/` — that `backend` hostname only resolves inside **Docker Compose's** internal DNS. It does **not** resolve on ECS Fargate (each service has its own network interface, no shared DNS namespace by default), so the frontend container crash-loops with `host not found in upstream "backend"`.

**Decision made:** Instead of fixing the React app's networking, we're repurposing the "frontend" slot to serve the **custom dashboard** (`dashboard/index.html`) instead — it's a static page, no backend proxy needed, so it just works. This was a deliberate choice, not a bug to silently work around.

To do this: create `dashboard/Dockerfile` (simple `nginx:alpine` + `COPY index.html`), then change the CI workflow's frontend build step `context:` from `./fullstack-text-storage/frontend` to `./dashboard`. Same image name/tag, so no Terraform changes needed for this specific swap.

---

## The Core Pain Point Driving Current Work — Dynamic IPs

Fargate tasks get a **new public IP every time they restart** (deployment, crash, force-new-deployment). This means:
- Manually looking up IPs via `aws ecs describe-tasks` + `aws ec2 describe-network-interfaces` after every deploy was the workflow so far — tedious and the dashboard's hardcoded IPs go stale constantly.
- **This is being solved right now by adding an Application Load Balancer (ALB)** — see Current Task.

---

## Current Task — Adding an ALB (IN PROGRESS, NOT YET APPLIED)

Goal: one ALB with a **fixed DNS name** that never changes, fronting all 6 services on different listener ports (since services aren't path-aware). Once done, `terraform output alb_dns_name` gives one permanent URL, and the dashboard should link through the ALB DNS instead of raw task IPs.

Planned listener port mapping:
```
Port 80    → frontend/dashboard
Port 81    → nginx
Port 3000  → nodejs
Port 5000  → flask
Port 8080  → java
Port 5001  → backend (listener port differs from container port 5000 because flask already owns ALB port 5000)
```

Files being added/modified for this (in `terraform-ecs/`):
- `variables.tf` — added `health_check_path` field to each app in `var.apps` (nginx:"/", nodejs:"/", flask:"/", java:"/hello", frontend:"/")
- `alb.tf` (new) — `aws_lb`, `aws_security_group.alb_sg`, `aws_lb_target_group.apps` (for_each), `aws_lb_listener.apps` (for_each), plus separate `aws_lb_target_group.backend` + `aws_lb_listener.backend` (health check path `/health`)
- `security.tf` — updated `ecs_sg` to only accept traffic from `alb_sg` (SG-to-SG pattern) instead of `0.0.0.0/0`
- `ecs-services.tf` — added `load_balancer` block to each service (for_each), referencing the matching target group
- `backend.tf` — added `load_balancer` block to backend service
- `outputs.tf` — added `alb_dns_name` output

**Status: files written, `terraform plan` was about to be run but not yet reviewed/applied.** Expect the plan to show all 6 ECS services as "must be replaced" (Terraform/AWS doesn't support attaching a load balancer to a service that didn't have one at creation — this forces recreation, which is expected and fine).

### Next steps when resuming:
1. Run `terraform plan` in `terraform-ecs/`, review carefully (should show new ALB resources + all services replaced)
2. `terraform apply`
3. Get the ALB DNS: `terraform output alb_dns_name`
4. Update `dashboard/index.html` links to use `http://<alb-dns>:<port>` instead of raw IPs
5. Create `dashboard/Dockerfile` and repoint the CI workflow's frontend build context to `./dashboard` (see "Known Issue" above)
6. Commit + push everything

---

## Environment / Tooling Notes

- Windows 11, Git Bash (MINGW64) is the primary shell — **not** WSL2 for this project's command history (though WSL2 exists on the machine).
- **Git Bash path-mangling issue:** commands with `/`-prefixed arguments (like `--log-group-name /ecs/backend`) get mangled by MSYS2 unless prefixed with `MSYS2_ARG_CONV_EXCL="*"`.
- `aws ecs execute-command` (ECS Exec) does **not** work reliably from Git Bash due to the same path issue with the Session Manager Plugin — use **PowerShell** for any `execute-command` sessions.
- Session Manager Plugin is installed at `C:\Program Files\Amazon\SessionManagerPlugin\bin` — not on PATH by default in new shells, run `$env:Path += ";C:\Program Files\Amazon\SessionManagerPlugin\bin"` in PowerShell if needed.
- Terraform state file (`terraform.tfstate`) and `terraform.tfvars` are gitignored because they contain the RDS password in plaintext — **never commit these**. If you need to run `terraform apply` fresh, you'll need to recreate `terraform.tfvars` with `db_password = "<value>"`.

---

## What NOT To Do

- Don't rename the backend's environment variables away from `DB_HOST`/`DB_PORT`/`POSTGRES_DB`/`POSTGRES_USER`/`POSTGRES_PASSWORD` without also updating `backend.tf`.
- Don't remove `assign_public_ip = true` from ECS services — there's no NAT Gateway in this VPC (skipped for cost), so tasks need a public IP to pull images from Docker Hub over the Internet Gateway.
- Don't commit `terraform.tfvars` or any `.tfstate` file.
- Don't put "lab", "Netsol", or "intern" anywhere in commit messages, branch names, or file names — this is portfolio-facing.
