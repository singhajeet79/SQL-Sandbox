# 🚀 SQL-Sandbox: Multi-DB Practice Lab

Welcome to the **Multi-DB Support** branch of the SQL-Sandbox. This environment is designed for advanced SQL practice, allowing you to work across multiple distinct database schemas within a single PostgreSQL instance.

## 🏗️ Included Databases
This branch automatically initializes three separate databases:
1.  **postgres**: The default maintenance database.
2.  **sakila**: The classic DVD rental store schema (Actors, Films, Inventory).
3.  **employee_example**: A custom laboratory schema for join and aggregation practice.

---

## 🛠️ Quick Start

### 1. Prerequisites
- Docker and Docker Compose installed.
- Git (switched to `feature/multi-db-support` branch).

### 2. Launch the Lab
To ensure a clean initialization of all three databases, run:
```bash
# Clear any existing volumes from other branches
docker compose down -v

# Start the environment
docker compose up -d
```
### 3. Verify Initialization
The Sakila dataset is ~8MB. It may take 30–60 seconds to fully populate. Monitor the progress:

```bash
docker logs -f sql-db
```
Wait until you see: PostgreSQL init process complete; ready for start up.


### 4.🖥️ How to Register in pgAdmin UI
Once the containers are running, follow these steps to connect the GUI to your databases:

Access pgAdmin: Open http://10.81.27.131:5050 (or your host IP).

Login:

Email: admin@example.com

Password: admin

Register Server:

Right-click Servers > Register > Server...

General Tab:

Name: SQL-Sandbox-MultiDB

Connection Tab:

Host name/address: sql-db

Port: 5432

Maintenance database: postgres

Username: admin

Password: admin

Save password: Check the box.

Save: Click the Save button.

Note: After saving, expand Databases in the left sidebar. If you don't see sakila or employee_example immediately, right-click Databases and select Refresh.

### 5. 📂 Project Structure (Feature Branch)
init-scripts/00-init.sh: Orchestrates the creation of multiple DBs and the postgres role.

init-scripts/01-sakila-schema.sql: Definitions for the Sakila objects.

init-scripts/02-sakila-data.sql: Massive data insert script for Sakila.

init-scripts/03-example.sql: Your custom practice dataset.


### 6.🔄 Switching Back to Main
If you need to return to the single employees (HR) database setup:
```bash
git checkout main

docker compose down -v

docker compose up -d
```


---
#### Check out [My GitHub Page](https://singhajeet79.github.io/) for more AI/MLOps/Data Engineering projects!
**Happy Engineering!** 🚀
