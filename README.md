# 🧪 SQL-Sandbox: PostgreSQL 

A plug-and-play PostgreSQL environment pre-loaded with a high-quality employee dataset. Designed for data engineers, analysts, and DBAs to practice complex queries, indexing, and schema management without the setup headache.

---

## 🚀 Quick Start

Ensure you have [Docker](https://docs.docker.com/get-docker/) installed, then run:

```bash
# Clone the repo and start the stack
docker compose up -d
```
The database will automatically initialize using the SQL scripts found in the /hr-schema directory.

---

## 🛠️ Connectivity
#### Method A: Web GUI (pgAdmin)
1. Open your browser to: http://localhost:5050

2. Login Credentials:

    * Email: admin@example.com

    * Password: admin

3. Connect to Server:

   * Host: db (This is the internal Docker service name)

   * Port: 5432

   * Maintenance DB: employees

   * Username/Password: admin / admin

#### Method B: Terminal (psql)
Access the database shell directly:
```bash
docker exec -it sql-db psql -U admin -d employees
```

---

## 📊 Database Schema
The hr-schema dataset mimics a real-world enterprise structure:

   * employee: Core staff records (ID, birth date, names, hire date).

   * department: Company organizational units.

   * salary: Historical salary(amount) tracking (with start/end dates).

   * title: Job titles and career progression.  

   * dept_emp & dept_manager: Junction tables linking staff to departments

---

## 📝 Practice Drills

#### 1. The High Earners
Find the top 10 highest-paid employees currently active in the company:
```SQL
SELECT e.first_name, e.last_name, s.amount 
FROM employee e
JOIN salary s ON e.emp_no = s.emp_no
WHERE s.to_date = '9999-01-01'
ORDER BY s.amount DESC
LIMIT 10;
```

#### 2. Department Breakdown
Count how many employees are currently assigned to each department:
```SQL
SELECT d.dept_name, COUNT(de.emp_no) as staff_count
FROM department d
JOIN dept_emp de ON d.dept_no = de.dept_no
WHERE de.to_date = '9999-01-01'
GROUP BY d.dept_name;
```

#### 3. Find the maximum salary that is strictly less than the overall maximum salary.
#### Subquery approach
```SQL
SELECT e.first_name, e.last_name, s.amount
FROM employee e
JOIN salary s ON e.emp_no = s.emp_no
WHERE 
    s.amount = (
    SELECT MAX(amount) 
    FROM salary 
    WHERE amount < (SELECT MAX(amount) FROM salary)
);
```

#### Using LIMIT & OFFSET
```SQL
SELECT e.first_name, e.last_name, s.amount
FROM employee e
JOIN salary s ON e.emp_no = s.emp_no
WHERE s.to_date = '9999-01-01'
ORDER BY s.amount DESC
LIMIT 1 OFFSET 1;
```

##### Using DENSE_RANK()
```SQL
SELECT first_name, last_name, amount
FROM (
    SELECT 
        e.first_name, 
        e.last_name, 
        s.amount,
        DENSE_RANK() OVER (ORDER BY s.amount DESC) as salary_rank
    FROM employee e
    JOIN salary s ON e.emp_no = s.emp_no
    WHERE s.to_date = '9999-01-01'
) ranked_salary
WHERE salary_rank = 2;
```

---

## 🧹 Housekeeping
Stop the services:

```bash
docker compose stop
```
Wipe everything (including the database volume):
*Use this if you want to force a fresh reload of the schema.*

```bash
docker compose down -v
```

---

## 🙏 Credits
This lab uses a modified version of the Employee Sample Database, originally curated by [Tianzhou](https://github.com/tianzhou). It provides a realistic distribution of data for testing SQL performance and logic.

---

## 📂 Repository Structure

```Plaintext
.
├── docker-compose.yml
├── .gitignore
├── README.md
└── hr-schema/
    └── postgres/
        └── dataset/
            ├── employee.sql        # Main entry point script
            └── data_load/          # Sub-scripts (ignored by Docker auto-run)
                ├── load_department.sql
                ├── load_employee.sql
                └── ...
└── README.md
```

---
#### Check out [My GitHub Page](https://singhajeet79.github.io/) for more AI/MLOps/Data Engineering projects!
**Happy Engineering!** 🚀
